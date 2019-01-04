--------------------------------------------------------------------------------
-- File: shift_reg.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-04-21 #$: Date of last commit
-- $Rev:: 44           $: Revision of last commit
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

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity shift_reg is
  generic (
    LEN   : natural          := 8;                  -- Register length
    INIT  : std_logic_vector := b"0000_0000";       -- Initial value
    DIR   : shift_dir_t      := RSHIFT              -- Shift direction (right shift)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;                         -- System control
    i_clr : in  std_logic;                          -- Register clear
    i_set : in  std_logic;                          -- Register parallel load
    i_tck : in  std_logic;                          -- Shift tick
    i_ssd : in  std_logic;                          -- Serial shift data input
    i_psd : in  std_logic_vector(LEN-1 downto 0);   -- Parallel shift data input
    -- Output ports ------------------------------------------------------------
    o_ssd : out std_logic;                          -- Serial shift data output
    o_psd : out std_logic_vector(LEN-1 downto 0)    -- Parallel shift data output
  );
end entity shift_reg;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of shift_reg is
  -- Constants -----------------------------------------------------------------
  constant C_SHIFT_REG_INIT : std_logic_vector(LEN-1 downto 0) := INIT;       -- Shift register initial value
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal shift_reg  : std_logic_vector(LEN-1 downto 0) := C_SHIFT_REG_INIT;   -- Shift register current state
  signal shift_next : std_logic_vector(LEN-1 downto 0) := C_SHIFT_REG_INIT;   -- Shift register next state
  -- Atributes -----------------------------------------------------------------
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
  -- attribute MARK_DEBUG of >signal_name< : signal is "true";
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
  attribute KEEP               : string;
  attribute KEEP of shift_reg : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Shift register
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      shift_reg <= C_SHIFT_REG_INIT;
    else
      shift_reg <= shift_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------
-- (none)

-- Next-state logic ------------------------------------------------------------

-- GENERATE BLOCK: LSHIFT direction
gen_next_state_lshift:
if (DIR = LSHIFT) generate
  proc_next_state_lshift:
  process(shift_reg, i_sys.clr, i_sys.ena, i_clr, i_set, i_tck, i_ssd, i_psd)
  begin
    shift_next <= shift_reg;
    if (i_sys.ena = '1') then
      if (i_sys.clr = '1') then
        shift_next <= C_SHIFT_REG_INIT;
      else
        if (i_clr = '1') then
          shift_next <= C_SHIFT_REG_INIT;
        elsif (i_set = '1') then
          shift_next <= i_psd;
        elsif (i_tck = '1') then
          shift_next <= shift_reg(LEN-2 downto 0) & i_ssd;
        end if;
      end if;
    end if;
  end process;
end generate;

-- GENERATE BLOCK: RSHIFT direction
gen_next_state_rshift:
if (DIR = RSHIFT) generate
  proc_next_state_rshift:
  process(shift_reg, i_sys.clr, i_sys.ena, i_clr, i_set, i_tck, i_ssd, i_psd)
  begin
    shift_next <= shift_reg;
    if (i_sys.ena = '1') then
      if (i_sys.clr = '1') then
        shift_next <= C_SHIFT_REG_INIT;
      else
        if (i_clr = '1') then
          shift_next <= C_SHIFT_REG_INIT;
        elsif (i_set = '1') then
          shift_next <= i_psd;
        elsif (i_tck = '1') then
          shift_next <= i_ssd & shift_reg(LEN-1 downto 1);
        end if;
      end if;
    end if;
  end process;
end generate;

-- Output logic ----------------------------------------------------------------

-- GENERATE BLOCK: LSHIFT direction
gen_proc_out_lshift:
if (DIR = LSHIFT) generate
  proc_out_o_ssd:
  o_ssd <= shift_reg(LEN-1);
end generate;

-- GENERATE BLOCK: RSHIFT direction
gen_proc_out_rshift:
if (DIR = RSHIFT) generate
  proc_out_o_ssd:
  o_ssd <= shift_reg(0);
end generate;

-- Parallel shift data output
proc_out_o_psd:
o_psd <= shift_reg;

end architecture rtl;