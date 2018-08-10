--------------------------------------------------------------------------------
-- File: diag_state_seq.vhd
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
library diag;
  use diag.diag_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity diag_state_seq is
  generic (
    DIAG_LGRP_LEN      : natural := 4;                                    -- Low side control signal bit vector length (Low side 0 ... 3)
    DIAG_CNT_LEN       : natural := 20                                    -- Diagnostics counter bit vector length
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys              : in  sys_ctrl_t;                                  -- System control
    i_diag_state_ena   : in  std_logic;                                   -- Diagnostics state enable
    i_diag_cnt_cnt     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Diagnostics counter/timer value
    i_hcmp_voltage     : in  std_logic;                                   -- High side voltage comparator
    i_hcmp_current     : in  std_logic;                                   -- High side current comparator
    i_lcmp_current     : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- Low side current comparator
    i_tcmp_prep_idle   : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for preparation after idle
    i_tcmp_li_scp      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for low current short-circuit-to-power test
    i_tcmp_li_scg      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for low current short-circuit-to-GND test
    i_tcmp_li_ol       : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for low current open load test
    i_tcmp_li_rslv     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for low current resolve phase
    i_tcmp_hi_scp      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for high current short-circuit-to-power test
    i_tcmp_hi_scg      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for high current short-circuit-to-GND test
    i_tcmp_hi_rslv     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for high current resolve phase
    i_tcmp_valid       : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for diagnostics valid phase
    i_tcmp_prep_repeat : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);   -- Phase time for preparation repeat
    i_lcmp_msk        : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);   -- Low side control mask
    -- Output ports ------------------------------------------------------------
    o_diag_cnt_clr     : out std_logic;                                   -- Diagnostics counter/timer clear
    o_diag_cnt_tck     : out std_logic;                                   -- Diagnostics counter/timer tick
    o_diag_prot_ena    : out std_logic;                                   -- Diagnostics (over-)current protection threshold enable
    o_hdiag_ctrl       : out std_logic;                                   -- NMOS high side control
    o_hdiag_pu         : out std_logic;                                   -- High side diagnostics pull-up current source control
    o_hdiag_pd         : out std_logic;                                   -- High side diagnostics pull-down current source control
    o_ldiag_ctrl       : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- NMOS low side control
    o_ldiag_pd         : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- Low side diagnostics pull-down current source control
    o_diag_res_flags   : out diag_res_t                                   -- Diagnostics result flags
  );
end entity diag_state_seq;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of diag_state_seq is
  -- Constants -----------------------------------------------------------------
  constant C_DIAG_STATE_SEQ_DEFAULT_CNT_CMP : std_logic_vector(DIAG_CNT_LEN-1 downto 0) := (others => '0');   -- Default diagnostics counter/timer compare value
  -- Types ---------------------------------------------------------------------
  -- Diagnostics state-machine type
  type diag_state_t is (    -- Diagnostics state-machine type
    IDLE,             -- Idle (no offline diagnostics sequence running)
    PREP_IDLE,        -- Prepare after idle
    LI_SCP,           -- Low current Short-Circuit-to-Power test
    LI_RSLV_SCP,      -- Low current Short-Circuit-to-Power resolve
    LI_SCG,           -- Low current Short-Circuit-to-GND test
    LI_RSLV_SCG,      -- Low current Short-Circuit-to-GND resolve
    LI_OL_CH0,        -- Low current Open-Load test channel 0
    LI_RSLV_OL_CH0,   -- Low current Open-Load resolve channel 0
    LI_OL_CH1,        -- Low current Open-Load test channel 1
    LI_RSLV_OL_CH1,   -- Low current Open-Load resolve channel 1
    LI_OL_CH2,        -- Low current Open-Load test channel 2
    LI_RSLV_OL_CH2,   -- Low current Open-Load resolve channel 2
    LI_OL_CH3,        -- Low current Open-Load test channel 3
    LI_RSLV_OL_CH3,   -- Low current Open-Load resolve channel 3
    HI_SCP_CH0,       -- High current Short-Circuit-to-Power test channel 0
    HI_RSLV_SCP_CH0,  -- High current Short-Circuit-to-Power resolve channel 0
    HI_SCP_CH1,       -- High current Short-Circuit-to-Power test channel 1
    HI_RSLV_SCP_CH1,  -- High current Short-Circuit-to-Power resolve channel 1
    HI_SCP_CH2,       -- High current Short-Circuit-to-Power test channel 2
    HI_RSLV_SCP_CH2,  -- High current Short-Circuit-to-Power resolve channel 2
    HI_SCP_CH3,       -- High current Short-Circuit-to-Power test channel 3
    HI_RSLV_SCP_CH3,  -- High current Short-Circuit-to-Power resolve channel 3
    HI_SCG,           -- High current Short-Circuit-to-GND test
    HI_RSLV_SCG,      -- High current Short-Circuit-to_GND resolve
    VALID,            -- Diagnostics valid
    PREP_REPEAT       -- Prepare after diagnostics sequence
  );
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal state_reg    : diag_state_t                              := IDLE;              -- State-machine current state
  signal state_next   : diag_state_t                              := IDLE;              -- State-machine next state
  signal diag_cnt_cmp : std_logic_vector(DIAG_CNT_LEN-1 downto 0) := (others => '0');   -- Diagnostics counter/timer compare value
  signal diag_cnt_ovr : std_logic                                 := '0';               -- Diagnostics counter/timer overflow
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
-- Offline diagnostics state sequencer
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

-- Diagnostics counter/timer compare value
proc_in_diag_cnt_cmp:
diag_cnt_cmp <= i_tcmp_prep_idle   when (state_reg = PREP_IDLE)
           else i_tcmp_li_scp      when (state_reg = LI_SCP)
           else i_tcmp_li_rslv     when (state_reg = LI_RSLV_SCP)
           else i_tcmp_li_scg      when (state_reg = LI_SCG)
           else i_tcmp_li_rslv     when (state_reg = LI_RSLV_SCG)
           else i_tcmp_li_ol       when (state_reg = LI_OL_CH0)
           else i_tcmp_li_rslv     when (state_reg = LI_RSLV_OL_CH0)
           else i_tcmp_li_ol       when (state_reg = LI_OL_CH1)
           else i_tcmp_li_rslv     when (state_reg = LI_RSLV_OL_CH1)
           else i_tcmp_li_ol       when (state_reg = LI_OL_CH2)
           else i_tcmp_li_rslv     when (state_reg = LI_RSLV_OL_CH2)
           else i_tcmp_li_ol       when (state_reg = LI_OL_CH3)
           else i_tcmp_li_rslv     when (state_reg = LI_RSLV_OL_CH3)
           else i_tcmp_hi_scp      when (state_reg = HI_SCP_CH0)
           else i_tcmp_hi_rslv     when (state_reg = HI_RSLV_SCP_CH0)
           else i_tcmp_hi_scp      when (state_reg = HI_SCP_CH1)
           else i_tcmp_hi_rslv     when (state_reg = HI_RSLV_SCP_CH1)
           else i_tcmp_hi_scp      when (state_reg = HI_SCP_CH2)
           else i_tcmp_hi_rslv     when (state_reg = HI_RSLV_SCP_CH2)
           else i_tcmp_hi_scp      when (state_reg = HI_SCP_CH3)
           else i_tcmp_hi_rslv     when (state_reg = HI_RSLV_SCP_CH3)
           else i_tcmp_hi_scg      when (state_reg = HI_SCG)
           else i_tcmp_hi_rslv     when (state_reg = HI_RSLV_SCG)
           else i_tcmp_valid       when (state_reg = VALID)
           else i_tcmp_prep_repeat when (state_reg = PREP_REPEAT)
           else C_DIAG_STATE_SEQ_DEFAULT_CNT_CMP;

-- Diagnostics counter/timer overflow
proc_in_diag_cnt_ovr:
diag_cnt_ovr <= '1' when (i_diag_cnt_cnt >= diag_cnt_cmp)
           else '0';

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(state_reg, i_sys.ena, i_sys.clr, i_diag_state_ena, diag_cnt_ovr, i_hcmp_voltage, i_hcmp_current, i_lcmp_current, i_lcmp_msk)
begin
  state_next <= state_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      state_next <= IDLE;
    else
      case state_reg is
        -- STATE: IDLE ---------------------------------------------------------
        when IDLE =>
          if (i_diag_state_ena = '1') then
            state_next <= PREP_IDLE;
          else
            state_next <= IDLE;
          end if;
        -- STATE: PREP_IDLE ----------------------------------------------------
        when PREP_IDLE =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              state_next <= LI_SCP;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: LI_SCP -------------------------------------------------------
        when LI_SCP =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_hcmp_voltage = '0') then
                state_next <= LI_SCG;
              else
                state_next <= LI_RSLV_SCP;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: LI_RSLV_SCP --------------------------------------------------
        when LI_RSLV_SCP =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(0) = '1') then
                state_next <= HI_SCP_CH0;
              elsif (i_lcmp_msk(1) = '1') then
                state_next <= HI_SCP_CH1;
              elsif (i_lcmp_msk(2) = '1') then
                state_next <= HI_SCP_CH2;
              elsif (i_lcmp_msk(3) = '1') then
                state_next <= HI_SCP_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          end if;
        -- STATE: LI_SCG -------------------------------------------------------
        when LI_SCG =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_hcmp_voltage = '1') then
                if (i_lcmp_msk(0) = '1') then
                  state_next <= LI_OL_CH0;
                elsif (i_lcmp_msk(1) = '1') then
                  state_next <= LI_OL_CH1;
                elsif (i_lcmp_msk(2) = '1') then
                  state_next <= LI_OL_CH2;
                elsif (i_lcmp_msk(3) = '1') then
                  state_next <= LI_OL_CH3;
                else
                  state_next <= VALID;
                end if;
              else
                state_next <= LI_RSLV_SCG;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: LI_RSLV_SCG --------------------------------------------------
        when LI_RSLV_SCG =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              state_next <= HI_SCG;
            end if;
          end if;
        -- STATE: LI_OL_CH0 -----------------------------------------------------
        when LI_OL_CH0 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_hcmp_voltage = '0') then
                if (i_lcmp_msk(1) = '1') then
                  state_next <= LI_OL_CH1;
                elsif (i_lcmp_msk(2) = '1') then
                  state_next <= LI_OL_CH2;
                elsif (i_lcmp_msk(3) = '1') then
                  state_next <= LI_OL_CH3;
                else
                  state_next <= VALID;
                end if;
              else
                state_next <= LI_RSLV_OL_CH0;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: LI_RSLV_OL_CH0 -----------------------------------------------
        when LI_RSLV_OL_CH0 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(1) = '1') then
                state_next <= LI_OL_CH1;
              elsif (i_lcmp_msk(2) = '1') then
                state_next <= LI_OL_CH2;
              elsif (i_lcmp_msk(3) = '1') then
                state_next <= LI_OL_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          end if;
        -- STATE: LI_OL_CH1 ----------------------------------------------------
        when LI_OL_CH1 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_hcmp_voltage = '0') then
                if (i_lcmp_msk(2) = '1') then
                  state_next <= LI_OL_CH2;
                elsif (i_lcmp_msk(3) = '1') then
                  state_next <= LI_OL_CH3;
                else
                  state_next <= VALID;
                end if;
              else
                state_next <= LI_RSLV_OL_CH1;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: LI_RSLV_OL_CH1 -----------------------------------------------
        when LI_RSLV_OL_CH1 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(2) = '1') then
                state_next <= LI_OL_CH2;
              elsif (i_lcmp_msk(3) = '1') then
                state_next <= LI_OL_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          end if;
        -- STATE: LI_OL_CH2 ----------------------------------------------------
        when LI_OL_CH2 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_hcmp_voltage = '0') then
                if (i_lcmp_msk(3) = '1') then
                  state_next <= LI_OL_CH3;
                else
                  state_next <= VALID;
                end if;
                else
                state_next <= LI_RSLV_OL_CH2;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: LI_RSLV_OL_CH2 -----------------------------------------------
        when LI_RSLV_OL_CH2 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(3) = '1') then
                state_next <= LI_OL_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          end if;
        -- STATE: LI_OL_CH3 ----------------------------------------------------
        when LI_OL_CH3 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_hcmp_voltage = '0') then
                state_next <= VALID;
              else
                state_next <= LI_RSLV_OL_CH3;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: LI_RSLV_OL_CH3 -----------------------------------------------
        when LI_RSLV_OL_CH3 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              state_next <= VALID;
            end if;
          end if;
        -- STATE: HI_SCP_CH0 ---------------------------------------------------
        when HI_SCP_CH0 =>
          if (i_diag_state_ena = '1') then
            if (i_lcmp_current(0) = '1') then
              state_next <= HI_RSLV_SCP_CH0;
            elsif (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(1) = '1') then
                state_next <= HI_SCP_CH1;
              elsif (i_lcmp_msk(2) = '1') then
                state_next <= HI_SCP_CH2;
              elsif (i_lcmp_msk(3) = '1') then
                state_next <= HI_SCP_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_RSLV_SCP_CH0 ----------------------------------------------
        when HI_RSLV_SCP_CH0 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(1) = '1') then
                state_next <= HI_SCP_CH1;
              elsif (i_lcmp_msk(2) = '1') then
                state_next <= HI_SCP_CH2;
              elsif (i_lcmp_msk(3) = '1') then
                state_next <= HI_SCP_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_SCP_CH1 ---------------------------------------------------
        when HI_SCP_CH1 =>
          if (i_diag_state_ena = '1') then
            if (i_lcmp_current(1) = '1') then
              state_next <= HI_RSLV_SCP_CH1;
            elsif (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(2) = '1') then
                state_next <= HI_SCP_CH2;
              elsif (i_lcmp_msk(3) = '1') then
                state_next <= HI_SCP_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_RSLV_SCP_CH1 ----------------------------------------------
        when HI_RSLV_SCP_CH1 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(2) = '1') then
                state_next <= HI_SCP_CH2;
              elsif (i_lcmp_msk(3) = '1') then
                state_next <= HI_SCP_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_SCP_CH2 ---------------------------------------------------
        when HI_SCP_CH2 =>
          if (i_diag_state_ena = '1') then
            if (i_lcmp_current(2) = '1') then
              state_next <= HI_RSLV_SCP_CH2;
            elsif (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(3) = '1') then
                state_next <= HI_SCP_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_RSLV_SCP_CH2 ----------------------------------------------
        when HI_RSLV_SCP_CH2 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              if (i_lcmp_msk(3) = '1') then
                state_next <= HI_SCP_CH3;
              else
                state_next <= VALID;
              end if;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_SCP_CH3 ---------------------------------------------------
        when HI_SCP_CH3 =>
          if (i_diag_state_ena = '1') then
            if (i_lcmp_current(3) = '1') then
              state_next <= HI_RSLV_SCP_CH3;
            elsif (diag_cnt_ovr = '1') then
              state_next <= VALID;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_RSLV_SCP_CH3 ----------------------------------------------
        when HI_RSLV_SCP_CH3 =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              state_next <= VALID;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_SCG -------------------------------------------------------
        when HI_SCG =>
          if (i_diag_state_ena = '1') then
            if (i_hcmp_current = '1') then
              state_next <= HI_RSLV_SCG;
            elsif (diag_cnt_ovr = '1') then
              state_next <= VALID;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: HI_RSLV_SCG --------------------------------------------------
        when HI_RSLV_SCG =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              state_next <= VALID;
            end if;
          else
            state_next <= IDLE;
          end if;
        -- STATE: VALID --------------------------------------------------------
        when VALID =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              state_next <= PREP_REPEAT;
            end if;
          else
            state_Next <= IDLE;
          end if;
        -- STATE: PREP_REPEAT --------------------------------------------------
        when PREP_REPEAT =>
          if (i_diag_state_ena = '1') then
            if (diag_cnt_ovr = '1') then
              state_next <= LI_SCP;
            end if;
          else
            state_next <= IDLE;
          end if;
      end case;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- Diagnostics protection enable
proc_out_o_diag_prot_ena:
o_diag_prot_ena <= '0' when (state_reg = IDLE)
              else '0' when (state_reg = PREP_IDLE)
              else '1';

-- Diagnostics state counter/timer clear
proc_out_o_diag_cnt_clr:
o_diag_cnt_clr <= '1' when (state_reg /= state_next)
             else '1' when (state_reg = IDLE)
             else '0';

-- Diagnostics state counter/timer tick
proc_out_o_diag_cnt_tck:
o_diag_cnt_tck <= '0' when (state_reg = IDLE)
             else '1' when (state_reg = state_next)
             else '0';

-- Diagnostics High Side pull-up control
proc_out_o_hdiag_pu:
o_hdiag_pu <= '1' when (state_reg = LI_SCG)
         else '1' when (state_reg = LI_OL_CH0)
         else '1' when (state_reg = LI_OL_CH1)
         else '1' when (state_reg = LI_OL_CH2)
         else '1' when (state_reg = LI_OL_CH3)
         else '0';

-- Diagnostics High Side pull-down control
proc_out_o_hdiag_pd:
o_hdiag_pd <= '1' when (state_reg = LI_SCP)
         else '0';

-- Diagnostics Low Side pull-down control channel 0
proc_out_o_ldiag_pd0:
o_ldiag_pd(0) <= '1' when (state_reg = LI_OL_CH0)
            else '0';

-- Diagnostics Low Side pull-down control channel 1
proc_out_o_ldiag_pd1:
o_ldiag_pd(1) <= '1' when (state_reg = LI_OL_CH1)
            else '0';

-- Diagnostics Low Side pull-down control channel 2
proc_out_o_ldiag_pd2:
o_ldiag_pd(2) <= '1' when (state_reg = LI_OL_CH2)
            else '0';

-- Diagnostics Low Side pull-down control channel 3
proc_out_o_ldiag_pd3:
o_ldiag_pd(3) <= '1' when (state_reg = LI_OL_CH3)
            else '0';

-- Diagnostics NMOS High Side control
proc_out_o_hdiag_ctrl:
o_hdiag_ctrl <= '1' when (state_reg = HI_SCG)
           else '0';

-- Diagnostics NMOS Low Side control channel 0
proc_out_o_ldiag_ctrl0:
o_ldiag_ctrl(0) <= '1' when (state_reg = HI_SCP_CH0)
              else '0';

-- Diagnostics NMOS Low Side control channel 1
proc_out_o_ldiag_ctrl1:
o_ldiag_ctrl(1) <= '1' when (state_reg = HI_SCP_CH1)
              else '0';

-- Diagnostics NMOS Low Side control channel 2
proc_out_o_ldiag_ctrl2:
o_ldiag_ctrl(2) <= '1' when (state_reg = HI_SCP_CH2)
              else '0';

-- Diagnostics NMOS Low Side control channel 3
proc_out_o_ldiag_ctrl3:
o_ldiag_ctrl(3) <= '1' when (state_reg = HI_SCP_CH3)
              else '0';

-- Diagnostics result flags short-circuit-to-power
proc_out_o_diag_res_flags_scp:
o_diag_res_flags.SCP <= '1' when (state_reg = LI_RSLV_SCP)
                   else '0';

-- Diagnostics result flags short-circuit-to-GND
proc_out_o_diag_res_flags_scg:
o_diag_res_flags.SCG <= '1' when (state_reg = LI_RSLV_SCG)
                   else '0';

-- Diagnostics result flags open load channel 0
proc_out_o_diag_res_flags_ol0:
o_diag_res_flags.OL(0) <= '1' when (state_reg = LI_RSLV_OL_CH0)
                     else '0';

-- Diagnostics result flags open load channel 1
proc_out_o_diag_res_flags_ol1:
o_diag_res_flags.OL(1) <= '1' when (state_reg = LI_RSLV_OL_CH1)
                     else '0';

-- Diagnostics result flags open load channel 2
proc_out_o_diag_res_flags_ol2:
o_diag_res_flags.OL(2) <= '1' when (state_reg = LI_RSLV_OL_CH2)
                     else '0';

-- Diagnostics result flags open load channel 3
proc_out_o_diag_res_flags_ol3:
o_diag_res_flags.OL(3) <= '1' when (state_reg = LI_RSLV_OL_CH3)
                     else '0';

-- Diagnostics result flags short-circuit-to-Power at low side 0
proc_out_o_diag_res_flags_scp_ls0:
o_diag_res_flags.SCP_LS(0) <= '1' when (state_reg = HI_RSLV_SCP_CH0)
                         else '0';

-- Diagnostics result flags short-circuit-to-Power at low side 1
proc_out_o_diag_res_flags_scp_ls1:
o_diag_res_flags.SCP_LS(1) <= '1' when (state_reg = HI_RSLV_SCP_CH1)
                         else '0';

-- Diagnostics result flags short-circuit-to-Power at low side 2
proc_out_o_diag_res_flags_scp_ls2:
o_diag_res_flags.SCP_LS(2) <= '1' when (state_reg = HI_RSLV_SCP_CH2)
                         else '0';

-- Diagnostics result flags short-circuit-to-Power at low side 3
proc_out_o_diag_res_flags_scp_ls3:
o_diag_res_flags.SCP_LS(3) <= '1' when (state_reg = HI_RSLV_SCP_CH3)
                         else '0';

-- Diagnostics result flags short-circuit-to-GND at high side
proc_out_o_diag_res_flags_scg_hs:
o_diag_res_flags.SCG_HS <= '1' when (state_reg = HI_RSLV_SCG)
                      else '0';

-- Diagnostics result flags diagnostics valid
proc_out_o_diag_res_flags_valid:
o_diag_res_flags.VALID <= '1' when (state_reg = VALID)
                     else '0';

end architecture rtl;