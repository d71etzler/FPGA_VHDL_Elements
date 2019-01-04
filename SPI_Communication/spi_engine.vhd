--------------------------------------------------------------------------------
-- File: spi_engine.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-19 #$: Date of last commit
-- $Rev:: 11           $: Revision of last commit
--
-- Open Points/Remarks:
--  + SPI message counter to be implemented
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Used library definitions
--------------------------------------------------------------------------------
library ieee;
  use ieee.numeric_std.all;
  use ieee.std_logic_1164.all;
library basic;
  use basic.basic_elements.all;
library math;
  use math.crc_functions.all;
library spi;
  use spi.spi_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_engine is
  generic (
    SPI_MSG_LEN    : natural          := 6;                         -- SPI message length (number in bits)
    SPI_CTRL_MODE  : spi_ctrl_mode_t  := CPOL0_CPHA0;               -- SPI control mode
    SPI_SHIFT_DIR  : spi_shift_dir_t  := MSB;                       -- SPI shift direction
    SPI_CRC_POLY   : std_logic_vector := b"01";                     -- SPI CRC polynom (without leading '1')
    SPI_SHIFT_INIT : std_logic_vector := b"11_1111";                -- SPI shift register initial value
    SPI_FRM_INIT   : std_logic_vector := b"11_1111";                -- SPI frame buffer initial string
    SPI_MSG_INIT   : std_logic_vector := b"11_1111";                -- SPI message buffer initial string
    SPI_ERR_SCLK   : std_logic_vector := b"11_1110";                -- SPI clock error message string
    SPI_ERR_CRC    : std_logic_vector := b"11_1101";                -- SPI frame CRC error message string
    SPI_ERR_OVRN   : std_logic_vector := b"11_1011"                 -- SPI frame overrun error message string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys          : in  sys_ctrl_t;                                -- System control
    i_csel         : in  std_logic;                                 -- SPI chip select
    i_sclk         : in  std_logic;                                 -- SPI clock
    i_sdi          : in  std_logic;                                 -- Serial input data
    i_mdo_load_s   : in  std_logic;                                 -- Parallel output message data load (one clock cycle pulse)
    i_mdo          : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);  -- Parallel output message data
    -- Output ports ------------------------------------------------------------
    o_sdo          : out std_logic;                                 -- Serial output data
    o_mdi_load_s   : out std_logic;                                 -- Parallel input message data load (one clock cycle pulse)
    o_mdi          : out std_logic_vector(SPI_MSG_LEN-1 downto 0)   -- Parallel input message data
  );
end entity spi_engine;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of spi_engine is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_ENGINE_SPI_CRC_POLY_LEN   : natural                                               := SPI_CRC_POLY'length;
  constant C_SPI_ENGINE_SPI_FRM_LEN        : natural                                               := SPI_MSG_LEN+C_SPI_ENGINE_SPI_CRC_POLY_LEN;
  constant C_SPI_ENGINE_SPI_SHIFT_INIT_CRC : std_logic_vector(C_SPI_ENGINE_SPI_FRM_LEN-1 downto 0) := append_crc(SPI_SHIFT_INIT, SPI_CRC_POLY);
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal err_sclk   : std_logic                                             := '0';              -- SPI clock error
  signal shift_mode : spi_shift_mode_t                                      := NONE;             -- SPI shift register mode
  signal pdi        : std_logic_vector(C_SPI_ENGINE_SPI_FRM_LEN-1 downto 0) := (others => '0');  -- Parallel input frame data
  signal pdo        : std_logic_vector(C_SPI_ENGINE_SPI_FRM_LEN-1 downto 0) := (others => '0');  -- Parallel output frame data
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI shift register control core
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_ctrl_core_unit: spi_ctrl_core
  generic map (
    SPI_FRM_LEN   => C_SPI_ENGINE_SPI_FRM_LEN,
    SPI_CTRL_MODE => SPI_CTRL_MODE
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys         => i_sys,
    i_csel        => i_csel,
    i_sclk        => i_sclk,
    -- Output ports ------------------------------------------------------------
    o_err_sclk    => err_sclk,
    o_shift_mode  => shift_mode
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI shift register
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_shift_reg_unit: spi_shift_reg
  generic map (
    SPI_FRM_LEN    => C_SPI_ENGINE_SPI_FRM_LEN,
    SPI_CTRL_MODE  => SPI_CTRL_MODE,
    SPI_SHIFT_DIR  => SPI_SHIFT_DIR,
    SPI_SHIFT_INIT => C_SPI_ENGINE_SPI_SHIFT_INIT_CRC
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys          => i_sys,
    i_shift_mode   => shift_mode,
    i_sdi          => i_sdi,
    i_pdo          => pdo,
    -- Output ports ------------------------------------------------------------
    o_sdo          => o_sdo,
    o_pdi          => pdi
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI frame check
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_frame_check_unit: spi_frame_check
  generic map (
    SPI_FRM_LEN  => C_SPI_ENGINE_SPI_FRM_LEN,
    SPI_MSG_LEN  => SPI_MSG_LEN,
    SPI_CRC_POLY => SPI_CRC_POLY,
    SPI_MSG_INIT => SPI_MSG_INIT,
    SPI_ERR_SCLK => SPI_ERR_SCLK,
    SPI_ERR_CRC  => SPI_ERR_CRC
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys        => i_sys,
    i_err_sclk   => err_sclk,
    i_shift_mode => shift_mode,
    i_pdi        => pdi,
    -- Output ports ------------------------------------------------------------
    o_mdi_load_s => o_mdi_load_s,
    o_mdi        => o_mdi
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI frame build
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_frame_build_unit: spi_frame_build
  generic map (
    SPI_FRM_LEN  => C_SPI_ENGINE_SPI_FRM_LEN,
    SPI_MSG_LEN  => SPI_MSG_LEN,
    SPI_CRC_POLY => SPI_CRC_POLY,
    SPI_FRM_INIT => SPI_FRM_INIT,
    SPI_ERR_OVRN => SPI_ERR_OVRN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys        => i_sys,
    i_shift_mode => shift_mode,
    i_mdo_load_s => i_mdo_load_s,
    i_mdo        => i_mdo,
    -- Output ports ------------------------------------------------------------
    o_pdo        => pdo
  );

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;