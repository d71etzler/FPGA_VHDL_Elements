--------------------------------------------------------------------------------
-- File: spi_io_sync_2clkd.vhd
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
entity spi_io_sync_2clkd is
  generic (
    SPI_FRM_LEN   : natural          := 8;                          -- SPI frame length (number in bits)
    SPI_GUARD_LEN : natural          := 1;                          -- SPI guard length flip-flop shift register length
    SPI_CSEL_INIT : std_logic        := '0';                        -- SPI chip select initial synchronization value
    SPI_SCNT_INIT : std_logic        := '0';                        -- SPI clock edge counter synchronization value
    SPI_PDI_INIT  : std_logic_vector := b"0000_0000"                -- Parallel input data initial synchronization value
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst         : in  std_logic;                                  -- Reset
    i_clk         : in  std_logic;                                  -- System clock
    i_csel_a      : in  std_logic;                                  -- SPI chip select (asynchronous)
    i_sclk_cnt_a  : in  std_logic;                                  -- SPI clock edge counter (asynchronous)
    i_pdi_a       : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);   -- Parallel input data (asynchronous)
    -- Output ports ------------------------------------------------------------
    o_csel        : out std_logic;                                  -- SPI chip select (synchronous)
    o_sclk_cnt    : out std_logic;                                  -- SPI clock edge counter (synchronous)
    o_pdi         : out std_logic_vector(SPI_FRM_LEN-1 downto 0)    -- Parallel input data (synchronous)
  );
end entity spi_io_sync_2clkd;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of spi_io_sync_2clkd is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  -- (none)
  -- Attributes ----------------------------------------------------------------
  -- KEEP_HIERARCHY is used to prevent optimizations along the hierarchy
  -- boundaries.  The Vivado synthesis tool attempts to keep the same general
  -- hierarchies specified in the RTL, but for QoR reasons it can flatten or
  -- modify them.
  -- If KEEP_HIERARCHY is placed on the instance, the synthesis tool keeps the
  -- boundary on that level static.
  -- This can affect QoR and also should not be used on modules that describe
  -- the control logic of 3-state outputs and I/O buffers.  The KEEP_HIERARCHY
  -- can be placed in the module or architecture level or the instance.  This
  -- attribute can only be set in the RTL.
--  attribute KEEP_HIERARCHY                     : string;
--  attribute KEEP_HIERARCHY of __example_unit__ : label is "yes";
  -- Use the KEEP attribute to prevent optimizations where signals are either
  -- optimized or absorbed into logic blocks. This attribute instructs the
  -- synthesis tool to keep the signal it was placed on, and that signal is
  -- placed in the netlist.
  -- For example, if a signal is an output of a 2 bit AND gate, and it drives
  -- another AND gate, the KEEP attribute can be used to prevent that signal
  -- from being merged into a larger LUT that encompasses both AND gates.
  -- KEEP is also commonly used in conjunction with timing constraints. If there
  -- is a timing constraint on a signal that would normally be optimized, KEEP
  -- prevents that and allows the correct timing rules to be used.
  -- Note: The KEEP attribute is not supported on the port of a module or
  -- entity. If you need to keep specific ports, either use the
  -- -flatten_hierarchy none setting, or put a DONT_TOUCH on the module or
  -- entity itself.
--  attribute KEEP                       : string;
--  attribute KEEP of __example_signal__ : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI chip select synchronization (to SDI clock domain)
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_io_sync_2clkd_csel_unit: sync_bit
  generic map (
    GUARD_LEN => SPI_GUARD_LEN,
    SYNC_INIT => SPI_CSEL_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst     => i_rst,
    i_clk     => i_clk,
    i_bit_a   => i_csel_a,
    -- Output ports ------------------------------------------------------------
    o_bit     => o_csel
  );

-- Output logic ----------------------------------------------------------------
-- (none

--------------------------------------------------------------------------------
-- SPI clock edge counter synchronization (to SDI clock domain)
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_io_sync_2clkd_sclk_cnt_unit: sync_bit
  generic map (
    GUARD_LEN => SPI_GUARD_LEN,
    SYNC_INIT => SPI_SCNT_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst     => i_rst,
    i_clk     => i_clk,
    i_bit_a   => i_sclk_cnt_a,
    -- Output ports ------------------------------------------------------------
    o_bit     => o_sclk_cnt
  );

-- Output logic ----------------------------------------------------------------
-- (none

--------------------------------------------------------------------------------
-- SPI parallel data input synchronization (to SDI clock domain)
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
gen_spi_io_sync_2clkd_pdi:
for i in 0 to SPI_FRM_LEN-1 generate
  spi_io_sync_2clkd_pdi_unit: sync_bit
    generic map (
      GUARD_LEN => SPI_GUARD_LEN,
      SYNC_INIT => SPI_PDI_INIT(i)
    )
    port map (
      -- Input ports -----------------------------------------------------------
      i_rst     => i_rst,
      i_clk     => i_clk,
      i_bit_a   => i_pdi_a(i),
      -- Output ports ----------------------------------------------------------
      o_bit     => o_pdi(i)
    );
end generate;

-- Output logic ----------------------------------------------------------------
-- (none

end architecture structural;