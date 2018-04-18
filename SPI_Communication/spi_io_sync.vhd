--------------------------------------------------------------------------------
-- File: spi_io_sync.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-25 #$: Date of last commit
-- $Rev:: 20           $: Revision of last commit
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
library sync;
  use sync.sync_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_io_sync is
  generic (
    SPI_GUARD_LEN   : natural   := 1;     -- SPI guard length flip-flop shift register length
    SPI_CSEL_N_INIT : std_logic := '1';   -- SPI chip select initial synchronization value
    SPI_SCLK_INIT   : std_logic := '0';   -- SPI clock initial synchronization value
    SPI_SDI_INIT    : std_logic := '0'    -- Serial input data initial synchronization value
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst           : in  std_logic;      -- Reset
    i_clk           : in  std_logic;      -- System clock
    i_csel_na       : in  std_logic;      -- SPI chip select (low-active, asynchronous)
    i_sclk_a        : in  std_logic;      -- SPI clock (asynchronous)
    i_sdi_a         : in  std_logic;      -- Serial input data (asynchronous)
    -- Output ports ------------------------------------------------------------
    o_csel_n        : out std_logic;      -- SPI chip select (low-active, synchronous)
    o_sclk          : out std_logic;      -- SPI clock (synchronous)
    o_sdi           : out std_logic       -- Serial input data (synchronous)
  );
end entity spi_io_sync;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of spi_io_sync is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_IO_SYNC_GUARD_LEN : natural                                             := SPI_GUARD_LEN;
  constant C_SPI_IO_SYNC_VECT_LEN  : natural                                             := 3;
  constant C_SPI_IO_SYNC_VECT_INIT : std_logic_vector(C_SPI_IO_SYNC_VECT_LEN-1 downto 0) := (SPI_SDI_INIT & SPI_SCLK_INIT & SPI_CSEL_N_INIT);
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal spi_signals_a : std_logic_vector(C_SPI_IO_SYNC_VECT_LEN-1 downto 0) := C_SPI_IO_SYNC_VECT_INIT;  -- SPI signal vector (asynchronous)
  signal spi_signals   : std_logic_vector(C_SPI_IO_SYNC_VECT_LEN-1 downto 0) := C_SPI_IO_SYNC_VECT_INIT;  -- SPI signal vector (synchronous)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI IO signal synchronization
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
proc_in_spi_singals_a:
spi_signals_a <= (i_sdi_a & i_sclk_a & i_csel_na);

-- Component instantiation -----------------------------------------------------
gen_spi_io_sync_unit:
for i in 0 to (C_SPI_IO_SYNC_VECT_LEN-1) generate
  spi_io_sync_unit: sync_bit
    generic map (
      GUARD_LEN => C_SPI_IO_SYNC_GUARD_LEN,
      SYNC_INIT => C_SPI_IO_SYNC_VECT_INIT(i)
    )
    port map (
      -- Input ports -----------------------------------------------------------
      i_rst    => i_rst,
      i_clk    => i_clk,
      i_bit_a  => spi_signals_a(i),
      -- Output ports ----------------------------------------------------------
      o_bit    => spi_signals(i)
    );
end generate;

-- Output logic ----------------------------------------------------------------
proc_out_spi_signals:
(o_sdi, o_sclk, o_csel_n) <= spi_signals;

end architecture structural;