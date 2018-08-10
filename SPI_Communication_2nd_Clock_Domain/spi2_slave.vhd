--------------------------------------------------------------------------------
-- File: spi2_slave.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-02-28 #$: Date of last commit
-- $Rev:: 33           $: Revision of last commit
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
library sync;
  use sync.sync_elements.all;
library spi2;
  use spi2.spi2_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi2_slave is
  generic (
    SPI_MSG_LEN    : natural          := 6;                         -- SPI message length (number in bits)
    SPI_CTRL_MODE  : spi_ctrl_mode_t  := CPOL0_CPHA0;               -- SPI control mode
    SPI_SHIFT_DIR  : spi_shift_dir_t  := MSB;                       -- SPI shift direction
    SPI_CRC_POLY   : std_logic_vector := b"01";                     -- SPI CRC polynom (without leading '1')
    SPI_STAT_CMD   : std_logic_vector := b"1";                      -- SPI status command
    SPI_STAT_ADDR  : std_logic_vector := b"1";                      -- SPI status address
    SPI_SHIFT_INIT : std_logic_vector := b"1111";                   -- SPI shift register initial value
    SPI_FRM_INIT   : std_logic_vector := b"1111";                   -- SPI frame buffer initial string
    SPI_MSG_INIT   : std_logic_vector := b"1111";                   -- SPI message buffer initial string
    SPI_ERR_SCLK   : std_logic_vector := b"1110";                   -- SPI clock error message string
    SPI_ERR_CRC    : std_logic_vector := b"1101";                   -- SPI frame CRC error message string
    SPI_ERR_OVRN   : std_logic_vector := b"1011"                    -- SPI frame overrun error message string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_res_na       : in  sys_ctrl_t;                                -- Reset control
    i_csel_2c_n    : in  std_logic;                                 -- SPI chip select (low-active, synchronous to 2nd clock domain [sclk_2c])
    i_sclk_2c      : in  std_logic;                                 -- SPI clock (2nd clock domain)
    i_sdi_2c       : in  std_logic;                                 -- Serial input data (synchronous to 2nd clock domain [sclk_2c])
    i_mdo_load_s   : in  std_logic;                                 -- Parallel output message load strobe (RAM=>SPI) (one clock cycle pulse)
    i_mdo_data     : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);  -- Parallel output message data (RAM=>SPI)
    -- Output ports ------------------------------------------------------------
    o_sdo_2c_t     : out std_logic;                                 -- Serial output data (tristate, synchronous to 2nd clock domain [sclk_2c])
    o_mdi_load_s   : out std_logic;                                 -- Parallel input message load strobe (SPI=>RAM) (one clock cycle pulse)
    o_mdi_data     : out std_logic_vector(SPI_MSG_LEN-1 downto 0)   -- Parallel input message data (SPI=>RAM)
  );
end entity spi2_slave;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of spi2_slave is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_SLAVE_GUARD_LEN   : natural   := 1;                              -- SPI IO synchronization guard length
  constant C_SPI_SLAVE_CSEL_N_INIT : std_logic := '1';                            -- SPI chip select (low-active) initial value
  constant C_SPI_SLAVE_SCLK_INIT   : std_logic := set_sclk_level(SPI_CTRL_MODE);  -- SPI clock initial value
  constant C_SPI_SLAVE_SDI_INIT    : std_logic := '0';                            -- Serial input data initial value
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal csel_n : std_logic := C_SPI_SLAVE_CSEL_N_INIT;       -- SPI chip select (low-active, synchronous)
  signal csel   : std_logic := not(C_SPI_SLAVE_CSEL_N_INIT);  -- Complement chip select (high-active, synchronous)
  signal sclk   : std_logic := C_SPI_SLAVE_SCLK_INIT;         -- SPI clock (synchronous)
  signal sdi    : std_logic := C_SPI_SLAVE_SDI_INIT;          -- Serial input data (synchronous)
  signal sdo    : std_logic := '0';                           -- Serial output data
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI engine
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_engine_unit: spi_engine
  generic map (
    SPI_MSG_LEN    => SPI_MSG_LEN,
    SPI_CTRL_MODE  => SPI_CTRL_MODE,
    SPI_SHIFT_DIR  => SPI_SHIFT_DIR,
    SPI_CRC_POLY   => SPI_CRC_POLY,
    SPI_SHIFT_INIT => (SPI_STAT_CMD & SPI_STAT_ADDR & SPI_SHIFT_INIT),
    SPI_FRM_INIT   => (SPI_STAT_CMD & SPI_STAT_ADDR & SPI_FRM_INIT),
    SPI_MSG_INIT   => (SPI_STAT_CMD & SPI_STAT_ADDR & SPI_MSG_INIT),
    SPI_ERR_SCLK   => (SPI_STAT_CMD & SPI_STAT_ADDR & SPI_ERR_SCLK),
    SPI_ERR_CRC    => (SPI_STAT_CMD & SPI_STAT_ADDR & SPI_ERR_CRC),
    SPI_ERR_OVRN   => (SPI_STAT_CMD & SPI_STAT_ADDR & SPI_ERR_OVRN)
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys          => i_sys,
    i_csel         => csel,
    i_sclk         => sclk,
    i_sdi          => sdi,
    i_mdo_load_s   => i_mdo_load_s,
    i_mdo          => i_mdo_data,
    -- Output ports ------------------------------------------------------------
    o_sdo          => sdo,
    o_mdi_load_s   => o_mdi_load_s,
    o_mdi          => o_mdi_data
  );

-- Output logic ----------------------------------------------------------------
-- Implementation of serial output data port as tristate buffer.  In order to
-- pass MAP step; (a) option -u (Trim Unconnected Signals) has to be unchecked
-- or (b) option -ignore_keep_hierarchy (Allow Logic Optimization Across
-- Hierarchy) has to be checked.  Otherwise, the following error occurs:
-- ERROR:PhysDesignRules:1710 - Incomplete connectivity.  The pin <O> of comp
-- block <o_sdo_t> is used and partially connected to network <sdo>.  All
-- networks must have complete connectivity to the comp hierarchy and the
-- connectivity for this pin must be removed or completed.
proc_out_o_sdo_t:
o_sdo_t <= sdo when (csel = '1')
      else 'Z';

--------------------------------------------------------------------------------
-- SPI asynchronous external input signal synchronization
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_io_sync_unit: spi_io_sync
  generic map (
    SPI_GUARD_LEN   => C_SPI_SLAVE_GUARD_LEN,
    SPI_CSEL_N_INIT => C_SPI_SLAVE_CSEL_N_INIT,
    SPI_SCLK_INIT   => C_SPI_SLAVE_SCLK_INIT,
    SPI_SDI_INIT    => C_SPI_SLAVE_SDI_INIT
    )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst           => i_sys.rst,
    i_clk           => i_sys.clk,
    i_csel_na       => i_csel_na,
    i_sclk_a        => i_sclk_a,
    i_sdi_a         => i_sdi_a,
    -- Output ports ------------------------------------------------------------
    o_csel_n        => csel_n,
    o_sclk          => sclk,
    o_sdi           => sdi
  );

-- Output logic ----------------------------------------------------------------
proc_out_csel:
csel <= not(csel_n);

end architecture structural;