--------------------------------------------------------------------------------
-- File: widen_pulse.vhd
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
entity widen_pulse is
  generic (
    LEN      : natural := 2     -- Pulse length (number of clock cycles)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys    : in  sys_ctrl_t;  -- System control
    i_clr    : in  std_logic;   -- Counter clear
    i_pls_s  : in  std_logic;   -- Pulse (one clock cycle)
    -- Output ports ------------------------------------------------------------
    o_pls_xs : out std_logic    -- Pulse (LEN clock cycles)
  );
end entity widen_pulse;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of widen_pulse is
  -- Constants -----------------------------------------------------------------
  constant C_WIDEN_PULSE_CNT_WIDTH : natural                                      := clogb2(LEN);
  constant C_WIDEN_PULSE_CNT_INIT  : unsigned(C_WIDEN_PULSE_CNT_WIDTH-1 downto 0) := (others => '0');
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal cnt_res  : std_logic                                    := '0';
  signal cnt_tck  : std_logic                                    := '0';
  signal cnt_reg  : unsigned(C_WIDEN_PULSE_CNT_WIDTH-1 downto 0) := C_WIDEN_PULSE_CNT_INIT;
  signal cnt_next : unsigned(C_WIDEN_PULSE_CNT_WIDTH-1 downto 0) := C_WIDEN_PULSE_CNT_INIT;
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
--assert (LEN > 1)
--  report "LEN <= 1!  The new length value must be greater than 1."
--  severity error;

--------------------------------------------------------------------------------
-- Modulo-m counter
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      cnt_reg <= C_WIDEN_PULSE_CNT_INIT;
    else
      cnt_reg <= cnt_next;
    end if;
  end if;
end process;

-- Input logic ---------------------------------------------------------------

-- Counter reset
proc_in_cnt_res:
cnt_res <= '1' when (cnt_reg = (LEN-1))
      else '1' when (i_clr = '1')
      else '0';

-- Counter tick
proc_in_cnt_tck:
cnt_tck <= '1' when (i_pls_s = '1')
      else '1' when (cnt_reg /= 0)
      else '0';

-- Next-state logic ----------------------------------------------------------
proc_next_state_cnt_up:
process(cnt_reg, cnt_res, i_sys.clr, i_sys.ena, cnt_tck)
begin
  cnt_next <= cnt_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      cnt_next <= C_WIDEN_PULSE_CNT_INIT;
    else
      if (cnt_res = '1') then
        cnt_next <= C_WIDEN_PULSE_CNT_INIT;
      elsif (cnt_tck = '1') then
        cnt_next <= cnt_reg+1;
      end if;
    end if;
  end if;
end process;

-- Output logic --------------------------------------------------------------
proc_out_o_pls_xs:
o_pls_xs <= i_pls_s or cnt_tck;

end architecture rtl;