--------------------------------------------------------------------------------
-- File: nmos_prot_seq.vhd
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
library math;
  use math.logic_functions.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity nmos_prot_seq is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys           : in  sys_ctrl_t;   -- System control
    i_bst_ctrl      : in  std_logic;    -- Boost NMOS pre-driver control
    i_bat_ctrl      : in  std_logic;    -- Battery NMOS pre-driver control
    i_diag_prot_ena : in  std_logic;    -- Diagnostics protection enable
    -- Output ports ------------------------------------------------------------
    o_tbst_bat_ena  : out std_logic;    -- Boost-to-Battery slope timer enable
    o_tbat_bst_ena  : out std_logic;    -- Battery-to-Boost slope timer enable
    o_tbxt_diag_ena : out std_logic;    -- Boost-to-/Battery-to-Diagnostics slope timer enable
    o_diag_tbst_ena : out std_logic;    -- Diagnostics-to-Boost slope timer enable
    o_diag_tbat_ena : out std_logic     -- Diagnostics-to-Battery slope timer enable
  );
end entity nmos_prot_seq;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of nmos_prot_seq is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  type ctrl_state_t is (    -- Control state-machine type
    RESET,          -- Reset state
    RES_TO_BST,     -- Reset-to-Boost control transition state
    RES_TO_BAT,     -- Reset-to-Battery control transition state
    RES_TO_DIAG,    -- Reset-to-Diagnostics control transition state
    BST_TO_BAT,     -- Boost-to-Battery NMOS pre-driver control transition state
    BAT_TO_BST,     -- Battery-to-Boost NMOS pre-driver control transition state
    BXT_TO_DIAG,    -- Boost-to-/Battery-to-Diagnostics control transition state
    DIAG_TO_BST,    -- Diagnostics-to-Boost control transition state
    DIAG_TO_BAT     -- Diagnostics-to-Battery control transition state
  );
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal state_reg  : ctrl_state_t := RESET;    -- State-machine current state
  signal state_next : ctrl_state_t := RESET;    -- State-machine next state
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
  attribute FSM_ENCODING : string;
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
  attribute FSM_SAFE_STATE : string;
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
      state_reg <= RESET;
    else
      state_reg <= state_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------
-- (none)

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(state_reg, i_sys.ena, i_sys.clr, i_bst_ctrl, i_bat_ctrl, i_diag_prot_ena)
begin
  state_next <= state_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      state_next <= RESET;
    else
      case state_reg is
        -- STATE: RESET --------------------------------------------------------
        when RESET =>
          if (i_bst_ctrl = '1') then
            state_next <= RES_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= RES_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= RES_TO_DIAG;
          end if;
        -- STATE: RES_TO_BST ---------------------------------------------------
        when RES_TO_BST =>
          if (i_bst_ctrl = '1') then
            state_next <= RES_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= BST_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= BXT_TO_DIAG;
          end if;
        -- STATE: RES_TO_BAT ---------------------------------------------------
        when RES_TO_BAT =>
          if (i_bst_ctrl = '1') then
            state_next <= BAT_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= RES_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= BXT_TO_DIAG;
          end if;
        -- STATE: RES_TO_DIAG --------------------------------------------------
        when RES_TO_DIAG =>
          if (i_bst_ctrl = '1') then
            state_next <= DIAG_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= DIAG_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= RES_TO_DIAG;
          end if;
        -- STATE: BST_TO_BAT ---------------------------------------------------
        when BST_TO_BAT =>
          if (i_bst_ctrl = '1') then
            state_next <= BAT_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= BST_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= BXT_TO_DIAG;
          end if;
        -- STATE: BAT_TO_BST ---------------------------------------------------
        when BAT_TO_BST =>
          if (i_bst_ctrl = '1') then
            state_next <= BAT_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= BST_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= BXT_TO_DIAG;
          end if;
        -- STATE: BXT_TO_DIAG --------------------------------------------------
        when BXT_TO_DIAG =>
          if (i_bst_ctrl = '1') then
            state_next <= DIAG_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= DIAG_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= BXT_TO_DIAG;
          end if;
        -- STATE: DIAG_TO_BST --------------------------------------------------
        when DIAG_TO_BST =>
          if (i_bst_ctrl = '1') then
            state_next <= DIAG_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= BST_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= BXT_TO_DIAG;
          end if;
        -- STATE: DIAG_TO_BAT --------------------------------------------------
        when DIAG_TO_BAT =>
          if (i_bst_ctrl = '1') then
            state_next <= BAT_TO_BST;
          elsif (i_bat_ctrl = '1') then
            state_next <= DIAG_TO_BAT;
          elsif (i_diag_prot_ena = '1') then
            state_next <= BXT_TO_DIAG;
          end if;
      end case;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- Battery-to-Boost slope timer enable
proc_out_o_tbat_bst_ena:
o_tbat_bst_ena <= '1' when (state_reg = BAT_TO_BST)
             else '0';

-- Boost-to-Battery slope timer enable
proc_out_o_tbst_bat_ena:
o_tbst_bat_ena <= '1' when (state_reg = BST_TO_BAT)
             else '0';

-- Boost-to-/Battery-to-Diagnostics slope timer enable
proc_out_o_tbxt_diag_ena:
o_tbxt_diag_ena <= '1' when (state_reg = RES_TO_DIAG)
              else '1' when (state_reg = BXT_TO_DIAG)
              else '0';

-- Diagnostics-to-Boost slope timer enable
proc_out_o_diag_tbst_ena:
o_diag_tbst_ena <= '1' when (state_reg = RES_TO_BST)
              else '1' when (state_reg = DIAG_TO_BST)
              else '0';

-- Diagnostics-to-Battery slope timer enable
proc_out_o_diag_tbat_ena:
o_diag_tbat_ena <= '1' when (state_reg = RES_TO_BAT)
              else '1' when (state_reg = DIAG_TO_BAT)
              else '0';

end architecture rtl;