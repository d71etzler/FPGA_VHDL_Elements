--------------------------------------------------------------------------------
-- File: divide_mod_m.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-25 #$: Date of last commit
-- $Rev:: 18           $: Revision of last commit
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
entity divide_mod_m is
  generic (
    M     : natural   := 2;   -- Modulo value
    INIT  : natural   := 0;   -- Initial value
    DIR   : cnt_dir_t := UP   -- Count direction
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;   -- System control
    i_clr : in  std_logic;    -- Divider clear
    i_tck : in  std_logic;    -- Divider count tick
    -- Output ports ------------------------------------------------------------
    o_div : out std_logic     -- Divider tick
  );
end entity divide_mod_m;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of divide_mod_m is
  -- Constants -----------------------------------------------------------------
  constant C_DIVIDE_MOD_M_CNT_WIDTH : natural                                       := clogb2(M);
  constant C_DIVIDE_MOD_M_CNT_INIT  : unsigned(C_DIVIDE_MOD_M_CNT_WIDTH-1 downto 0) := to_unsigned(INIT, C_DIVIDE_MOD_M_CNT_WIDTH);
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal div_res  : std_logic                                     := '0';                       -- Divider reset
  signal div_reg  : unsigned(C_DIVIDE_MOD_M_CNT_WIDTH-1 downto 0) := C_DIVIDE_MOD_M_CNT_INIT;   -- Divider register current state
  signal div_next : unsigned(C_DIVIDE_MOD_M_CNT_WIDTH-1 downto 0) := C_DIVIDE_MOD_M_CNT_INIT;   -- Divider register next state
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
begin

-- Assertions ------------------------------------------------------------------
assert (M > 1)
  report "M <= 1!  The modulo value must be greater than 1."
  severity error;
assert (INIT < M)
  report "INIT >= M!  The initial divider value must be between 0 and M-1."
  severity error;

--------------------------------------------------------------------------------
-- Modulo-m divider
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      div_reg <= C_DIVIDE_MOD_M_CNT_INIT;
    else
      div_reg <= div_next;
    end if;
  end if;
end process;

-- Input logic ---------------------------------------------------------------

-- GENERATE BLOCK: DOWN-counter
gen_in_cnt_down:
if (DIR = DOWN) generate
  proc_in_div_res_down:
  div_res <= '1' when (div_reg = to_unsigned(0, C_DIVIDE_MOD_M_CNT_WIDTH))
        else '0';
end generate;

-- GENERATE BLOCK: UP-counter
gen_in_cnt_up:
if (DIR = UP) generate
  proc_in_div_res_up:
  div_res <= '1' when (div_reg = to_unsigned((M-1), C_DIVIDE_MOD_M_CNT_WIDTH))
        else '0';
end generate;

-- Next-state logic ----------------------------------------------------------

-- GENERATE BLOCK: DOWN-counter
gen_next_state_cnt_down:
if (DIR = DOWN) generate
  proc_next_state_cnt_down:
  process(div_reg, div_res, i_sys.ena, i_sys.clr, i_clr, i_tck)
  begin
    div_next <= div_reg;
    if (i_sys.ena = '1') then
      if (i_sys.clr = '1') then
        div_next <= C_DIVIDE_MOD_M_CNT_INIT;
      else
        if (i_clr = '1') then
          div_next <= C_DIVIDE_MOD_M_CNT_INIT;
        elsif (i_tck = '1') then
          if (div_res = '1') then
            div_next <= to_unsigned((M-1), C_DIVIDE_MOD_M_CNT_WIDTH);
          else
            div_next <= div_reg-1;
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
  process(div_reg, div_res, i_sys.clr, i_sys.ena, i_clr, i_tck)
  begin
    div_next <= div_reg;
    if (i_sys.ena = '1') then
      if (i_sys.clr = '1') then
        div_next <= C_DIVIDE_MOD_M_CNT_INIT;
      else
        if (i_clr = '1') then
          div_next <= C_DIVIDE_MOD_M_CNT_INIT;
        elsif (i_tck = '1') then
          if (div_res = '1') then
            div_next <= to_unsigned(0, C_DIVIDE_MOD_M_CNT_WIDTH);
          else
            div_next <= div_reg+1;
          end if;
        end if;
      end if;
    end if;
  end process;
end generate;

-- Output logic --------------------------------------------------------------

-- GENERATE BLOCK: DOWN-counter
gen_out_cnt_down:
if (DIR = DOWN) generate
  proc_out_o_div:
  o_div <= '1' when (div_reg = 0)
      else '0';
end generate;

-- GENERATE BLOCK: UP-counter
gen_out_cnt_up:
if (DIR = UP) generate
  proc_out_o_div:
  o_div <= '1' when (div_reg = (M-1))
      else '0';
end generate;

end architecture rtl;