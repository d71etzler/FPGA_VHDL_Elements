--------------------------------------------------------------------------------
-- File: nmos_pdrv_seq.vhd
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
library basic;
  use basic.basic_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity nmos_pdrv_seq is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys           : in  sys_ctrl_t;   -- System control
    i_ctrl          : in  std_logic;    -- Pre-driver control
    i_diag          : in  std_logic;    -- Diagnostics control
    i_prot_set      : in  std_logic;    -- Protection disable set
    i_prot_clr      : in  std_logic;    -- Protection disable clear
    i_tsoff_cnt_ovr : in  std_logic;    -- Strong OFF-path delay counter overflow
    -- Output ports ------------------------------------------------------------
    o_ctrl          : out std_logic;    -- NMOS switch control
    o_soff          : out std_logic;    -- Strong OFF-path control
    o_tsoff_cnt_clr : out std_logic;    -- Strong OFF-path delay counter clear
    o_tsoff_cnt_tck : out std_logic     -- Strong OFF-path delay counter tick
  );
end entity nmos_pdrv_seq;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of nmos_pdrv_seq is
  -- Constants -----------------------------------------------------------------
  constant C_NMOS_PDRV_SEQ_SOFF_CTRL_ZERO_DELAY : boolean := FALSE;   -- Zero additional clock cycles for strong OFF-path activation
  -- Types ---------------------------------------------------------------------
  type ctrl_state_t is (    -- Control state-machine type
    IDLE,         -- Idle state (wating for activation)
    ACTIVATED,    -- Activated state
    POST_CNT,     -- Post activation count state
    DIAGNOSTICS,  -- Diagnostics state
    PROTECTION    -- Protection event state
  );
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal state_reg  : ctrl_state_t := IDLE;     -- State-machine current state
  signal state_next : ctrl_state_t := IDLE;     -- State-machine next state
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
  -- FSM_ENCODING controls encoding on the state machine.  Typically, the Vivado
  -- tools choose an encoding protocol for state machines based on heuristics that
  -- do the best for the most designs.  Certain design types work better with a
  -- specific encoding protocol.
  -- FSM_ENCODING can be placed on the state machine registers.  The legal values
  -- for this are "one_hot", "sequential", "johnson", "gray", "auto", and "none".
  -- The "auto" value is the default, and allows the tool to determine best
  -- encoding.  This attribute can be set in the RTL or the XDC.
  attribute FSM_ENCODING              : string;
  attribute FSM_ENCODING of state_reg : signal is "gray";
  -- FSM_SAFE_STATE instructs Vivado synthesis to insert logic into the state
  -- machine that detects there is an illegal state, then puts it into a known,
  -- good state on the next clock cycle.
  -- For example, if there were a state machine with a "one_hot" encode, and that
  -- is in a "0101" state (which is an illegal for "one_hot"), the state machine
  -- would be able to recover.  Place the FSM_SAFE_STATE attribute on the state
  -- machine registers.  You can set this attribute in either the RTL or in the
  -- XDC.
  -- The legal values for FSM_SAFE_STATE are:
  -- • "auto": Uses Hamming-3 encoding for auto-correction for one bit/flip.
  -- • "reset_state": Forces the state machine into the reset state using
  --   Hamming-2 encoding detection for one bit/flip.
  -- • "power_on_state": Forces the state machine into the power-on state using
  --   Hamming-2 encoding detection for one bit/flip.
  -- • "default_state": Forces the state machine into the default state specified
  --   in RTL: the state that is specified in "default" branch of the case
  --   statement in Verilog or the state specified in the others branch of the
  --   case statement in VHDL; even if that state is unreachable, using Hamming-2
  --   encoding detection for one bit/flip.
  attribute FSM_SAFE_STATE              : string;
  attribute FSM_SAFE_STATE of state_reg : signal is "reset_state";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- NMOS protection threshold control sequencer
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      state_reg <= IDLE;
    else
      state_reg <= state_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------
-- (none)

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(state_reg, i_sys.ena, i_sys.clr, i_ctrl, i_diag, i_prot_set, i_prot_clr, i_tsoff_cnt_ovr)
begin
  state_next <= state_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      state_next <= IDLE;
    else
      case state_reg is
        -- STATE: IDLE ---------------------------------------------------------
        when IDLE =>
          if (i_prot_set = '1') then
            state_next <= PROTECTION;
          elsif (i_ctrl = '1') then
            state_next <= ACTIVATED;
          elsif (i_diag = '1') then
            state_next <= DIAGNOSTICS;
          end if;
        -- STATE: ACTIVATED ----------------------------------------------------
        when ACTIVATED =>
          if (i_prot_set = '1') then
            state_next <= PROTECTION;
          elsif (i_ctrl = '0') then
            state_next <= POST_CNT;
          end if;
        -- STATE: POST_CNT -----------------------------------------------------
        when POST_CNT =>
          if (i_prot_set = '1') then
            state_next <= PROTECTION;
          elsif (i_ctrl = '1') then
            state_next <= ACTIVATED;
          elsif (i_tsoff_cnt_ovr = '1') then
            state_next <= IDLE;
          end if;
        -- STATE: DIAGNOSTICS --------------------------------------------------
        when DIAGNOSTICS =>
          if (i_prot_set = '1') then
            state_next <= PROTECTION;
          elsif (i_diag = '0') then
            state_next <= IDLE;
          end if;
        -- STATE: PROTECTION ---------------------------------------------------
        when PROTECTION =>
          if (i_prot_set = '0') and (i_prot_clr = '1') then
            state_next <= IDLE;
          end if;
      end case;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- Strong OFF-path delay counter clear
proc_out_o_tsoff_cnt_clr:
o_tsoff_cnt_clr <= '0' when (state_reg = POST_CNT)
              else '1';

-- Strong OFF-path delay counter tick
proc_out_o_tsoff_cnt_tck:
o_tsoff_cnt_tck <= '1' when (state_reg = POST_CNT)
              else '0';

-- NMOS switch control
proc_out_o_ctrl:
o_ctrl <= '1' when (state_reg = ACTIVATED)
     else '1' when (state_reg = DIAGNOSTICS)
     else '0';

gen_o_soff: if (C_NMOS_PDRV_SEQ_SOFF_CTRL_ZERO_DELAY) generate
-- Strong OFF-path control
proc_out_o_soff:
o_soff <= '1' when (state_next = IDLE)
     else '1' when (state_next = PROTECTION)
     else '0';
end generate;

gen_o_soff_p1: if (not(C_NMOS_PDRV_SEQ_SOFF_CTRL_ZERO_DELAY)) generate
-- Strong OFF-path control (starting 1 clock cycle later)
proc_out_o_soff:
o_soff <= '1' when (state_reg = IDLE)
     else '1' when (state_reg = PROTECTION)
     else '0';
end generate;

end architecture rtl;