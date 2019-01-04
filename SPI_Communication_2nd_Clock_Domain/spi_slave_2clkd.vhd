--------------------------------------------------------------------------------
-- File: spi_slave_2clkd.vhd
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
library spi_2clkd;
  use spi_2clkd.spi_elements_2clkd.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_slave_2clkd is
  generic (
    SPI_MSG_LEN    : natural          := 7;                         -- SPI parallel message length (number in bits)
    SPI_CLK_POL    : spi_clk_pol_t    := CPOL0;                     -- SPI clock polarity
    SPI_SHIFT_DIR  : spi_shift_dir_t  := MSB;                       -- SPI shift direction
    SPI_PAR_VAR    : spi_parity_var_t := ODD;                       -- SPI parity variant (odd/even)
    SPI_MSG_INIT   : std_logic_vector := b"0000";                   -- SPI message buffer initial string
    SPI_ERR_SCLK   : std_logic_vector := b"1110";                   -- SPI clock error message string
    SPI_ERR_PAR    : std_logic_vector := b"1101";                   -- SPI frame parity error message string
    SPI_ERR_OVRN   : std_logic_vector := b"1011"                    -- SPI frame overrun error message string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys          : in  sys_ctrl_t;                                -- Reset control
    i_sclk_2clkd   : in  std_logic;                                 -- SPI clock (2nd clock domain)
    i_csel_2clkd_n : in  std_logic;                                 -- SPI chip select (low-active, synchronous to 2nd clock domain)
    i_sdi_2clkd    : in  std_logic;                                 -- Serial input data (synchronous to 2nd clock domain)
    i_mdo_load_s   : in  std_logic;                                 -- Parallel output message load strobe (Register=>SPI) (one clock cycle pulse)
    i_mdo_data     : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);  -- Parallel output message data (Register=>SPI)
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd_t  : out std_logic;                                 -- Serial output data (tristate, synchronous to 2nd clock domain)
    o_mdi_load_s   : out std_logic;                                 -- Parallel input message load strobe (SPI=>Register) (one clock cycle pulse)
    o_mdi_data     : out std_logic_vector(SPI_MSG_LEN-1 downto 0)   -- Parallel input message data (SPI=>Register)
  );
end entity spi_slave_2clkd;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of spi_slave_2clkd is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal csel_2clkd : std_logic := '0';   -- SPI chip select (high-active, synchronous to 2nd clock domain)
  signal sdo_2clkd  : std_logic := '0';   -- Serial output data (synchronous to 2nd clock domain)
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI engine
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- SPI chip select negation
proc_in_csel_2clkd:
csel_2clkd <= not(i_csel_2clkd_n);

-- Component instantiation -----------------------------------------------------
spi_slave_2clkd_engine_unit: spi_engine_2clkd
  generic map (
    SPI_MSG_LEN   => SPI_MSG_LEN,
    SPI_CLK_POL   => SPI_CLK_POL,
    SPI_SHIFT_DIR => SPI_SHIFT_DIR,
    SPI_PAR_VAR   => SPI_PAR_VAR,
    SPI_MSG_INIT  => SPI_MSG_INIT,
    SPI_ERR_SCLK  => SPI_ERR_SCLK,
    SPI_ERR_PAR   => SPI_ERR_PAR,
    SPI_ERR_OVRN  => SPI_ERR_OVRN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys         => i_sys,
    i_sclk_2clkd  => i_sclk_2clkd,
    i_csel_2clkd  => csel_2clkd,
    i_sdi_2clkd   => i_sdi_2clkd,
    i_mdo_load_s  => i_mdo_load_s,
    i_mdo         => i_mdo_data,
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd   => sdo_2clkd,
    o_mdi_load_s  => o_mdi_load_s,
    o_mdi         => o_mdi_data
  );

-- Output logic ----------------------------------------------------------------
-- Implementation of serial output data port as tristate buffer.  In order to
-- pass MAP step; (a) option -u (Trim Unconnected Signals) has to be unchecked
-- or (b) option -ignore_keep_hierarchy (Allow Logic Optimization Across
-- Hierarchy) has to be checked.  Otherwise, the following error occurs:
-- ERROR:PhysDesignRules:1710 - Incomplete connectivity.  The pin <O> of comp
-- block <o_sdo_2clkd_t> is used and partially connected to network <sdo_2clkd>.
--   All networks must have complete connectivity to the comp hierarchy and the
-- connectivity for this pin must be removed or completed.
proc_out_o_sdo_2clkd_t:
o_sdo_2clkd_t <= sdo_2clkd when (csel_2clkd = '1')
            else 'Z';

end architecture structural;