--------------------------------------------------------------------------------
-- File: spi_engine_2clkd.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-19 #$: Date of last commit
-- $Rev:: 11           $: Revision of last commit
--
-- Open Points/Remarks:
--  + (none)
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
library spi_2clkd;
  use spi_2clkd.spi_elements_2clkd.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_engine_2clkd is
  generic (
    SPI_MSG_LEN   : natural          := 7;                          -- SPI message length (number in bits)
    SPI_CLK_POL   : spi_clk_pol_t    := CPOL0;                      -- SPI clock polarity
    SPI_SHIFT_DIR : spi_shift_dir_t  := MSB;                        -- SPI shift direction
    SPI_PAR_VAR   : spi_parity_var_t := ODD;                        -- SPI parity variant
    SPI_MSG_INIT  : std_logic_vector := b"111_1111";                -- SPI message buffer initial string
    SPI_ERR_SCLK  : std_logic_vector := b"111_1110";                -- SPI clock error message string
    SPI_ERR_PAR   : std_logic_vector := b"111_1101";                -- SPI frame CRC error message string
    SPI_ERR_OVRN  : std_logic_vector := b"111_1011"                 -- SPI frame overrun error message string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys         : in  sys_ctrl_t;                                 -- System control
    i_sclk_2clkd  : in  std_logic;                                  -- SPI clock (2nd clock domain)
    i_csel_2clkd  : in  std_logic;                                  -- SPI chip select (2nd clock domain)
    i_sdi_2clkd   : in  std_logic;                                  -- Serial input data (2nd clock domain)
    i_mdo_load_s  : in  std_logic;                                  -- Parallel output message data load (one clock cycle pulse)
    i_mdo         : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);   -- Parallel output message data
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd   : out std_logic;                                  -- Serial output data (2nd clock domain)
    o_mdi_load_s  : out std_logic;                                  -- Parallel input message data load (one clock cycle pulse)
    o_mdi         : out std_logic_vector(SPI_MSG_LEN-1 downto 0)    -- Parallel input message data
  );
end entity spi_engine_2clkd;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of spi_engine_2clkd is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_ENGINE_2CLKD_SPI_PAR_LEN       : natural                                                     := 1;                                                       -- SPI parity check length
  constant C_SPI_ENGINE_2CLKD_SPI_FRM_LEN       : natural                                                     := SPI_MSG_LEN+C_SPI_ENGINE_2CLKD_SPI_PAR_LEN;              -- SPI frame length (message length + parity length)
  constant C_SPI_ENGINE_2CLKD_SPI_FRM_INIT      : std_logic_vector(C_SPI_ENGINE_2CLKD_SPI_FRM_LEN-1 downto 0) := get_parity(SPI_MSG_INIT, SPI_PAR_VAR) & SPI_MSG_INIT;    -- SPI frame initial value (first response message)
  constant C_SPI_ENGINE_2CLKD_IO_SYNC_GUARD_LEN : natural                                                     := 1;                                                       -- SPI guard length flip-flop shift register length
  constant C_SPI_ENGINE_2CLKD_IO_SYNC_CSEL_INIT : std_logic                                                   := '0';                                                     -- SPI chip select IO-synchronization initial value
  constant C_SPI_ENGINE_2CLKD_IO_SYNC_SCNT_INIT : std_logic                                                   := '0';                                                     -- SPI clock edge counter IO-synchronization value
  constant C_SPI_ENGINE_2CLKD_IO_SYNC_PDI_INIT  : std_logic_vector(C_SPI_ENGINE_2CLKD_SPI_FRM_LEN-1 downto 0) := get_parity(SPI_MSG_INIT, SPI_PAR_VAR) & SPI_MSG_INIT;    -- SPI parallel data IO-synchronization initial value
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal csel             : std_logic                                                   := '0';                                   -- SPI chip select (synchronized to SDI clock domain)
  signal csel_rise        : std_logic                                                   := '0';                                   -- SPI chip select rising edge (synchronized to SDI clock domain)
  signal csel_fall        : std_logic                                                   := '0';                                   -- SPI chip select falling edge (synchronized to SDI clock domain)
  signal sclk_cnt_2clkd   : std_logic                                                   := '0';                                   -- SPI clock edge counter (synchronized to 2nd clock domain)
  signal sclk_cnt         : std_logic                                                   := '0';                                   -- SPI clock edge counter (synchronized to SDI clock domain)
  signal pdi_2clkd        : std_logic_vector(C_SPI_ENGINE_2CLKD_SPI_FRM_LEN-1 downto 0) := C_SPI_ENGINE_2CLKD_IO_SYNC_PDI_INIT;   -- Parallel input frame data (synchronized to 2nd clock domain)
  signal pdi_no_chk       : std_logic_vector(C_SPI_ENGINE_2CLKD_SPI_FRM_LEN-1 downto 0) := C_SPI_ENGINE_2CLKD_IO_SYNC_PDI_INIT;   -- Parallel input frame data before parity check (synchronized to SDI clock domain)
  signal pdo_load_2clkd   : std_logic                                                   := '0';                                   -- Parallel output frame data load
  signal pdo_2clkd        : std_logic_vector(C_SPI_ENGINE_2CLKD_SPI_FRM_LEN-1 downto 0) := (others => '0');                       -- Parallel output frame data (synchronized to 2nd clock domain)
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI IO-synchronization
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_engine_2clkd_io_sync_unit: spi_io_sync_2clkd
  generic map (
    SPI_FRM_LEN   => C_SPI_ENGINE_2CLKD_SPI_FRM_LEN,
    SPI_GUARD_LEN => C_SPI_ENGINE_2CLKD_IO_SYNC_GUARD_LEN,
    SPI_CSEL_INIT => C_SPI_ENGINE_2CLKD_IO_SYNC_CSEL_INIT,
    SPI_SCNT_INIT => C_SPI_ENGINE_2CLKD_IO_SYNC_SCNT_INIT,
    SPI_PDI_INIT  => C_SPI_ENGINE_2CLKD_IO_SYNC_PDI_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst         => i_sys.rst,
    i_clk         => i_sys.clk,
    i_csel_a      => i_csel_2clkd,
    i_sclk_cnt_a  => sclk_cnt_2clkd,
    i_pdi_a       => pdi_2clkd,
    -- Output ports ------------------------------------------------------------
    o_csel        => csel,
    o_sclk_cnt    => sclk_cnt,
    o_pdi         => pdi_no_chk
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI chip select edge detection
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_engine_2clkd_csel_edge_unit: spi_csel_edge_2clkd
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys       => i_sys,
    i_csel      => csel,
    -- Output ports ------------------------------------------------------------
    o_csel_rise => csel_rise,
    o_csel_fall => csel_fall
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI clock edge counter (2nd clock domain)
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_engine_2clkd_sclk_cnt_unit: spi_sclk_cnt_2clkd
  generic map (
    SPI_FRM_LEN        => C_SPI_ENGINE_2CLKD_SPI_FRM_LEN,
    SPI_CLK_POL        => SPI_CLK_POL
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst              => i_sys.rst,
    i_csel_fall        => csel_fall,
    i_sclk_2clkd       => i_sclk_2clkd,
    i_csel_2clkd       => i_csel_2clkd,
    -- Output ports ------------------------------------------------------------
    o_sclk_cnt_2clkd   => sclk_cnt_2clkd,
    o_sclk_lead_2clkd  => open,
    o_sclk_trail_2clkd => open
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI shift register (2nd clock domain)
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_engine_2clkd_shift_reg_unit: spi_shift_reg_2clkd
  generic map (
    SPI_FRM_LEN      => C_SPI_ENGINE_2CLKD_SPI_FRM_LEN,
    SPI_CLK_POL      => SPI_CLK_POL,
    SPI_SHIFT_DIR    => SPI_SHIFT_DIR,
    SPI_SHIFT_INIT   => C_SPI_ENGINE_2CLKD_SPI_FRM_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst            => i_sys.rst,
    i_sclk_2clkd     => i_sclk_2clkd,
    i_csel_2clkd     => i_csel_2clkd,
    i_sdi_2clkd      => i_sdi_2clkd,
    i_pdo_load_2clkd => pdo_load_2clkd,
    i_pdo_2clkd      => pdo_2clkd,
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd      => o_sdo_2clkd,
    o_pdi_2clkd      => pdi_2clkd
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI frame parity check
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_engine_2clkd_frm_chk_unit: spi_frm_chk_2clkd
  generic map (
    SPI_FRM_LEN  => C_SPI_ENGINE_2CLKD_SPI_FRM_LEN,
    SPI_PAR_VAR  => SPI_PAR_VAR,
    SPI_MDI_INIT => SPI_MSG_INIT,
    SPI_ERR_SCLK => SPI_ERR_SCLK,
    SPI_ERR_PAR  => SPI_ERR_PAR
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys        => i_sys,
    i_csel_fall  => csel_fall,
    i_sclk_cnt   => sclk_cnt,
    i_pdi        => pdi_no_chk,
    -- Output ports ------------------------------------------------------------
    o_mdi_load_s => o_mdi_load_s,
    o_mdi        => o_mdi
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI frame parity build
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_engine_2clkd_frm_bld_unit:spi_frm_bld_2clkd
  generic map (
    SPI_FRM_LEN      => C_SPI_ENGINE_2CLKD_SPI_FRM_LEN,
    SPI_PAR_VAR      => SPI_PAR_VAR,
    SPI_MDO_INIT     => SPI_MSG_INIT,
    SPI_ERR_OVRN     => SPI_ERR_OVRN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys            => i_sys,
    i_csel           => csel,
    i_csel_rise      => csel_rise,
    i_sclk_cnt       => sclk_cnt,
    i_mdo_load_s     => i_mdo_load_s,
    i_mdo            => i_mdo,
    i_sclk_cnt_2clkd => sclk_cnt_2clkd,
    -- Output ports ------------------------------------------------------------
    o_pdo_load       => pdo_load_2clkd,
    o_pdo            => pdo_2clkd
  );

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;