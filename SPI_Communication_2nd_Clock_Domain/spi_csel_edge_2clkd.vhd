--------------------------------------------------------------------------------
-- File: spi_csel_edge_2clkd.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-04-21 #$: Date of last commit
-- $Rev:: 44           $: Revision of last commit
--
-- Open Points/Remarks:
--  + Replace shift register implementation in chip select edge detection
--    instance by single flip-flop to avoid synthesis warning of an used
--    flip-flop (e.g. csel_reg(1) is unused).
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
entity spi_csel_edge_2clkd is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys       : in  sys_ctrl_t;   -- System control
    i_csel      : in  std_logic;    -- SPI chip select
    -- Output ports ------------------------------------------------------------
    o_csel_rise : out std_logic;    -- SPI chip select rising edge
    o_csel_fall : out std_logic     -- SPI chip select falling edge
  );
end entity spi_csel_edge_2clkd;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_csel_edge_2clkd is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_LEN  : natural                                                          := 2;      -- Chip select edge detec register length
  constant C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_INIT : std_logic                                                        := '0';    -- Chip select edge detect intial value
  constant C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_RISE : std_logic_vector(C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_LEN-1 downto 0) := b"01";  -- Chip select rising edge detect compare pattern
  constant C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_FALL : std_logic_vector(C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_LEN-1 downto 0) := b"10";  -- Chip select falling edge detect compare pattern
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal csel_reg  : std_logic := '0';    -- Chip select edge detect current state
  signal csel_next : std_logic := '0';    -- Chip select edge detect next state
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
  attribute KEEP_HIERARCHY        : string;
  attribute KEEP_HIERARCHY of rtl : architecture is "yes";
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
  attribute KEEP             : string;
  attribute KEEP of csel_reg : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI frame check
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------

-- Chip select edge detect
proc_register_csel_edge:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      csel_reg <= C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_INIT;
    else
      csel_reg <= csel_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------
-- (none)

-- Next-state logic ------------------------------------------------------------
proc_next_state_csel_edge:
process(csel_reg, i_sys.ena, i_sys.clr, i_csel)
begin
  csel_next <= csel_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      csel_next <= C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_INIT;
    else
      csel_next <= i_csel;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- Chip select rising edge detect
proc_out_o_csel_rise:
o_csel_rise <= '1' when ((csel_reg & csel_next) = C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_RISE)
          else '0';

-- Chip select falling edge detect
proc_out_o_csel_fall:
o_csel_fall <= '1' when ((csel_reg & csel_next) = C_SPI_CSEL_EDGE_2CLKD_CSEL_EDGE_FALL)
          else '0';

end architecture rtl;