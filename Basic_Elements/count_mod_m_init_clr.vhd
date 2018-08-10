--------------------------------------------------------------------------------
-- File: count_mod_m_init_clr.vhd
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
library math;
  use math.math_functions.all;
library basic;
  use basic.basic_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity count_mod_m_init_clr is
  generic (
    M     : natural   := 2;                             -- Modulo value
    INIT  : natural   := 0;                             -- Initial value
    CLR   : natural   := 0;                             -- Clear value
    DIR   : cnt_dir_t := UP                             -- Count direction
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;                             -- System control
    i_clr : in  std_logic;                              -- Counter clear
    i_tck : in  std_logic;                              -- Counter tick
    -- Output ports ------------------------------------------------------------
    o_cnt : out std_logic_vector(clogb2(M)-1 downto 0)  -- Counter value
  );
end entity count_mod_m_init_clr;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of count_mod_m_init_clr is
  -- Constants -----------------------------------------------------------------
  constant C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH : natural                                               := clogb2(M);
  constant C_COUNT_MOD_M_INIT_CLR_CNT_INIT  : unsigned(C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH-1 downto 0) := to_unsigned(INIT, C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH);
  constant C_COUNT_MOD_M_INIT_CLR_CNT_CLR   : unsigned(C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH-1 downto 0) := to_unsigned(CLR, C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH);
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal cnt_res  : std_logic                                             := '0';
  signal cnt_reg  : unsigned(C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH-1 downto 0) := C_COUNT_MOD_M_INIT_CLR_CNT_INIT;
  signal cnt_next : unsigned(C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH-1 downto 0) := C_COUNT_MOD_M_INIT_CLR_CNT_INIT;
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
  attribute KEEP            : string;
  attribute KEEP of cnt_reg : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
assert (M > 1)
  report "M <= 1!  The modulo value must be greater than 1."
  severity error;
assert (INIT < M)
  report "INIT >= M!  The initial counter value must be between 0 and M-1."
  severity error;
assert (CLR < M)
  report "CLR >= M!  The clearing counter value must be between 0 and M-1."
  severity error;

--------------------------------------------------------------------------------
-- Modulo-m counter
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      cnt_reg <= C_COUNT_MOD_M_INIT_CLR_CNT_INIT;
    else
      cnt_reg <= cnt_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- GENERATE BLOCK: DOWN-counter
gen_in_cnt_down:
if (DIR = DOWN) generate
  proc_in_cnt_res_down:
  cnt_res <= '1' when (cnt_reg = to_unsigned(0, C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH))
        else '0';
end generate;

-- GENERATE BLOCK: UP-counter
gen_in_cnt_up:
if (DIR = UP) generate
  proc_in_cnt_res_up:
  cnt_res <= '1' when (cnt_reg = to_unsigned((M-1), C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH))
        else '0';
end generate;

-- Next-state logic ------------------------------------------------------------

-- GENERATE BLOCK: DOWN-counter
gen_next_state_cnt_down:
if (DIR = DOWN) generate
  proc_next_state_cnt_down:
  process(cnt_reg, i_sys.ena, i_sys.clr, cnt_res, i_clr, i_tck)
  begin
    cnt_next <= cnt_reg;
    if (i_sys.ena = '1') then
      if (i_sys.clr = '1') then
        cnt_next <= C_COUNT_MOD_M_INIT_CLR_CNT_CLR;
      else
        if (i_clr = '1') then
          cnt_next <= C_COUNT_MOD_M_INIT_CLR_CNT_CLR;
        elsif (i_tck = '1') then
          if (cnt_res = '1') then
            cnt_next <= to_unsigned((M-1), C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH);
          else
            cnt_next <= cnt_reg-1;
          end if;
        end if;
      end if;
    end if;
  end process;
end generate;

-- GENERATE BLOCK: UP-counter
gen_next_state_cnt_up:
if (DIR = UP) generate
  proc_next_state_cnt_up:
  process(cnt_reg, cnt_res, i_sys.clr, i_sys.ena, i_clr, i_tck)
  begin
    cnt_next <= cnt_reg;
    if (i_sys.ena = '1') then
      if (i_sys.clr = '1') then
        cnt_next <= C_COUNT_MOD_M_INIT_CLR_CNT_CLR;
      else
        if (i_clr = '1') then
          cnt_next <= C_COUNT_MOD_M_INIT_CLR_CNT_CLR;
        elsif (i_tck = '1') then
          if (cnt_res = '1') then
            cnt_next <= to_unsigned(0, C_COUNT_MOD_M_INIT_CLR_CNT_WIDTH);
          else
            cnt_next <= cnt_reg+1;
          end if;
        end if;
      end if;
    end if;
  end process;
end generate;

-- Output logic ----------------------------------------------------------------
proc_out_o_cnt:
o_cnt <= std_logic_vector(cnt_reg);

end architecture rtl;