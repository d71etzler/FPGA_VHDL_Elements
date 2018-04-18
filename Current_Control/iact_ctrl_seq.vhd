--------------------------------------------------------------------------------
-- File: iact_ctrl_seq.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-25 #$: Date of last commit
-- $Rev:: 19           $: Revision of last commit
--
-- Open Points/Remarks:
--  + (none)
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Used library definitions
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--  use unisim.vcomponents.all;

library basic;
  use basic.basic_elements.all;
library iact;
  use iact.iact_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity iact_ctrl_seq is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;    -- System control
    i_clr        : in  std_logic;     -- Control output(s) clear
    i_set        : in  std_logic;     -- Control output(s) set
    i_isns_state : in  cmp_states_t;  -- Current sense comparator state
    i_ton_state  : in  cmp_states_t;  -- NMOS On-time comparator state
    i_toff_state : in  cmp_states_t;  -- NMOS Off-time comparator state
    -- Output ports ------------------------------------------------------------
    o_ctrl       : out iact_ctrl_t    -- Actuator current control
  );
end entity iact_ctrl_seq;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of iact_ctrl_seq is
  -- Constants -----------------------------------------------------------------
  constant C_IACT_CTRL_SEQ_LEVEL_OFF  : std_logic := '0';
  constant C_IACT_CTRL_SEQ_LEVEL_ON   : std_logic := '1';
  constant C_IACT_CTRL_SEQ_LEVEL_INIT : std_logic := C_IACT_CTRL_SEQ_LEVEL_OFF;
  constant C_IACT_CTRL_SEQ_ERROR_OFF  : std_logic := '0';
  constant C_IACT_CTRL_SEQ_ERROR_ON   : std_logic := '1';
  constant C_IACT_CTRL_SEQ_ERROR_INIT : std_logic := C_IACT_CTRL_SEQ_ERROR_OFF;
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal level_reg  : std_logic := C_IACT_CTRL_SEQ_LEVEL_INIT;
  signal level_next : std_logic := C_IACT_CTRL_SEQ_LEVEL_INIT;
  signal error_reg  : std_logic := C_IACT_CTRL_SEQ_ERROR_INIT;
  signal error_next : std_logic := C_IACT_CTRL_SEQ_ERROR_INIT;
  signal level_mux  : std_logic := C_IACT_CTRL_SEQ_LEVEL_INIT;
  signal error_mux  : std_logic := C_IACT_CTRL_SEQ_ERROR_INIT;
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
begin

--------------------------------------------------------------------------------
-- Actuator control sequencer
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------

-- Control level
proc_register_level:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      level_reg <= C_IACT_CTRL_SEQ_LEVEL_INIT;
    else
      level_reg <= level_next;
    end if;
  end if;
end process;

-- Control error
proc_register_error:
process(i_sys.rst, i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      error_reg <= C_IACT_CTRL_SEQ_ERROR_INIT;
    else
      error_reg <= error_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- Control level
-- TODO:: To be cross-checked whether additional branches for the control level
-- are necessary.  This has to be decided after testing using the target
-- hardware.
proc_in_level_mux:
level_mux <= '1' when (i_isns_state = BELOW_MIN_S)
        else '1' when (level_reg = '0') and (i_toff_state = ABOVE_MAX_S)
        else '0' when (i_isns_state = ABOVE_MAX_S)
        else '0' when (level_reg = '1') and (i_ton_state  = ABOVE_MAX_S)
        else '0' when (i_isns_state = INVALID_S)
        else '0' when (i_ton_state  = INVALID_S)
        else '0' when (i_toff_state = INVALID_S)
        else level_reg;

-- Control error
-- TODO:: To be cross-checked whether additional branches for the control error
-- are necessary.  This has to be decided after testing using the target
-- hardware.
proc_in_error_mux:
error_mux <= '1' when (i_isns_state = INVALID_S)
        else '1' when (i_ton_state  = INVALID_S)
        else '1' when (i_toff_state = INVALID_S)
        else '0';

-- Next-state logic ------------------------------------------------------------

-- Control level
proc_next_state_level:
process(level_reg, i_sys.ena, i_sys.clr, i_clr, i_set, level_mux)
begin
  level_next <= level_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      level_next <= C_IACT_CTRL_SEQ_LEVEL_INIT;
    else
      if (i_clr = '1') then
        level_next <= C_IACT_CTRL_SEQ_LEVEL_OFF;
      elsif (i_set = '1') then
        level_next <= C_IACT_CTRL_SEQ_LEVEL_ON;
      else
        level_next <= level_mux;
      end if;
    end if;
  end if;
end process;

-- Control error
proc_next_state_error:
process(error_reg, i_sys.ena, i_sys.clr, i_clr, error_mux)
begin
  error_next <= error_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      error_next <= C_IACT_CTRL_SEQ_LEVEL_INIT;
    else
      if (i_clr = '1') then
        error_next <= C_IACT_CTRL_SEQ_ERROR_OFF;
      else
        error_next <= error_mux;
      end if;
    end if;
  end if;
end process;

-- Current control -------------------------------------------------------------
proc_out_o_ctrl:
o_ctrl <= (
  level => level_reg,
  error => error_reg
);

end architecture rtl;