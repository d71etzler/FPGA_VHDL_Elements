--------------------------------------------------------------------------------
-- File: diag_state_ctrl.vhd
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
library basic;
  use basic.basic_elements.all;
library math;
  use math.math_functions.all;
  use math.logic_functions.all;
library diag;
  use diag.diag_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity diag_state_ctrl is
  generic (
    DIAG_HPOS_LEN      : natural := 2;                                    -- High side control switch signal bit vector length (e.g. Battery and Boost switch; not high side groups)
    DIAG_LGRP_LEN      : natural := 4;                                    -- Low side control signal bit vector length (low side 0 ... 3)
    DIAG_CNT_LEN       : natural := 24;                                   -- Diagnostics counter/timer bit vector length
    DIAG_DATA_LEN      : natural := 16                                    -- Storage register data length
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys              : in  sys_ctrl_t;                                  -- System control
    i_hctrl            : in  std_logic_vector(DIAG_HPOS_LEN-1 downto 0);  -- High side control
    i_hcmp_voltage     : in  std_logic;                                   -- Diagnostics high side voltage comparator
    i_hcmp_current     : in  std_logic;                                   -- High side (over-)current protection comparator
    i_lctrl            : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- Low side control
    i_lcmp_current     : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- Low side (over-)current protection comparator
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
    i_lcmp_msk         : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- Low side control mask
    -- Output ports ------------------------------------------------------------
    o_hdiag_prot_ena   : out std_logic;                                   -- High side diagnostics (over-)current protection threshold enable
    o_hdiag_ctrl       : out std_logic;                                   -- NMOS high side control
    o_hdiag_pu         : out std_logic;                                   -- High side diagnostics pull-up current source control
    o_hdiag_pd         : out std_logic;                                   -- High side diagnostics pull-down current source control
    o_ldiag_prot_ena   : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- Low side diagnostics (over-)current protection threshold enable
    o_ldiag_ctrl       : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- NMOS low side control
    o_ldiag_pd         : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);  -- Low side diagnostics pull-down current source control
    o_diag_res         : out std_logic_vector(DIAG_DATA_LEN-1 downto 0)   -- Diagnostics result register
  );
end entity diag_state_ctrl;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of diag_state_ctrl is
  -- Constants -----------------------------------------------------------------
  constant C_DIAG_STATE_CTRL_COUNT_MODULO_PLUS1   : natural := 2**DIAG_CNT_LEN;                                           -- Diagnostics state counter/timer modulo value
  constant C_DIAG_STATE_CTRL_COUNT_INIT           : natural := 0;                                                         -- Diagnostics state counter/timer initial value
  constant C_DIAG_STATE_CTRL_RES_BPOS_VALID       : natural := C_DIAG_CTRL_RES_BPOS_VALID;                                -- Diagnostics result bit position VALID flag
  constant C_DIAG_STATE_CTRL_RES_BPOS_SCG_HS      : natural := C_DIAG_CTRL_RES_BPOS_SCG_HS;                               -- Diagnostics result bit position SCG_HS flag
  constant C_DIAG_STATE_CTRL_RES_BPOS_SCP_LS_LSB  : natural := C_DIAG_CTRL_RES_BPOS_SCP_LS;                               -- Diagnostics result bit position SCP_LS flag (LSB)
  constant C_DIAG_STATE_CTRL_RES_BPOS_SCP_LS_MSB  : natural := C_DIAG_CTRL_RES_BPOS_SCP_LS+C_DIAG_STATE_LS_CTRL_LEN-1;    -- Diagnostics result bit position SCP_LS flag (MSB)
  constant C_DIAG_STATE_CTRL_RES_BPOS_OL_LSB      : natural := C_DIAG_CTRL_RES_BPOS_OL;                                   -- Diagnostics result bit position OL flag (LSB)
  constant C_DIAG_STATE_CTRL_RES_BPOS_OL_MSB      : natural := C_DIAG_CTRL_RES_BPOS_OL+C_DIAG_STATE_LS_CTRL_LEN-1;        -- Diagnostics result bit position OL flag (MSB)
  constant C_DIAG_STATE_CTRL_RES_BPOS_SCG         : natural := C_DIAG_CTRL_RES_BPOS_SCG;                                  -- Diagnostics result bit position SCG flag
  constant C_DIAG_STATE_CTRL_RES_BPOS_SCP         : natural := C_DIAG_CTRL_RES_BPOS_SCP;                                  -- Diagnostics result bit position SCP flag
  constant C_DIAG_STATE_CTRL_RES_BPOS_NOTUSED_LSB : natural := C_DIAG_CTRL_RES_BPOS_NOTUSED;                              -- Diagnostics result bit position NOT USED (LSB)
  constant C_DIAG_STATE_CTRL_RES_BPOS_NOTUSED_MSB : natural := DIAG_DATA_LEN-1;                                           -- Diagnostics result bit position NOT USED (MSB)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal diag_state_ena : std_logic                                := '0';                -- State sequencer enable
  signal diag_prot_ena  : std_logic                                := '0';                -- Diagnostics (over-)current protection threshold enable
  signal diag_cnt_clr   : std_logic                                := '1';                -- Diagnostics state counter/timer clear
  signal diag_cnt_tck   : std_logic                                := '0';                -- Diagnostics state counter/timer tick
  signal diag_cnt_cnt   : std_logic_vector(DIAG_CNT_LEN-1 downto 0):= (others => '0');    -- Diagnostics state counter/timer value
  signal diag_res_flags : diag_res_t                               := (                   -- Diagnostics results
    SCP    => '0',
    SCG    => '0',
    OL     => (others => '0'),
    SCP_LS => (others => '0'),
    SCG_HS => '0',
    VALID  => '0'
  );
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Global signal function
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Diagnostics state sequencer
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Diagnostics state sequencer enable
proc_in_diag_state_ena:
diag_state_ena <= not(or_reduce(i_hctrl & (i_lctrl and i_lcmp_msk)));

-- Component instantiation -----------------------------------------------------
diag_state_seq_unit: diag_state_seq
  generic map (
    DIAG_LGRP_LEN      => DIAG_LGRP_LEN,
    DIAG_CNT_LEN       => DIAG_CNT_LEN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys              => i_sys,
    i_diag_state_ena   => diag_state_ena,
    i_diag_cnt_cnt     => diag_cnt_cnt,
    i_hcmp_voltage     => i_hcmp_voltage,
    i_hcmp_current     => i_hcmp_current,
    i_lcmp_current     => i_lcmp_current,
    i_tcmp_prep_idle   => i_tcmp_prep_idle,
    i_tcmp_li_scp      => i_tcmp_li_scp,
    i_tcmp_li_scg      => i_tcmp_li_scg,
    i_tcmp_li_ol       => i_tcmp_li_ol,
    i_tcmp_li_rslv     => i_tcmp_li_rslv,
    i_tcmp_hi_scp      => i_tcmp_hi_scp,
    i_tcmp_hi_scg      => i_tcmp_hi_scg,
    i_tcmp_hi_rslv     => i_tcmp_hi_rslv,
    i_tcmp_valid       => i_tcmp_valid,
    i_tcmp_prep_repeat => i_tcmp_prep_repeat,
    i_lcmp_msk         => i_lcmp_msk,
    -- Output ports ------------------------------------------------------------
    o_diag_cnt_clr     => diag_cnt_clr,
    o_diag_cnt_tck     => diag_cnt_tck,
    o_diag_prot_ena    => diag_prot_ena,
    o_hdiag_ctrl       => o_hdiag_ctrl,
    o_hdiag_pu         => o_hdiag_pu,
    o_hdiag_pd         => o_hdiag_pd,
    o_ldiag_ctrl       => o_ldiag_ctrl,
    o_ldiag_pd         => o_ldiag_pd,
    o_diag_res_flags   => diag_res_flags
  );

-- Output logic ----------------------------------------------------------------

-- High side (over-)current protection threshold enable
proc_out_o_hdiag_prot_ena:
o_hdiag_prot_ena <= diag_prot_ena;

-- Low side (over-)current protection threshold enable
proc_out_o_ldiag_prot_ena:
process (i_lcmp_msk, diag_prot_ena)
begin
  for i in 0 to (DIAG_LGRP_LEN-1) loop
    o_ldiag_prot_ena(i) <= i_lcmp_msk(i) and diag_prot_ena;
  end loop;
end process proc_out_o_ldiag_prot_ena;

-- Diagnostics result mapping to data register valid flag
proc_out_o_diag_res_valid:
o_diag_res(C_DIAG_STATE_CTRL_RES_BPOS_VALID) <= diag_res_flags.VALID;

-- Diagnostics result mapping to data register SCG_HS flag
proc_out_o_diag_res_scg_hs:
o_diag_res(C_DIAG_STATE_CTRL_RES_BPOS_SCG_HS) <= diag_res_flags.SCG_HS;

-- Diagnostics result mapping to data register SCP_LS flags
proc_out_o_diag_res_scp_ls:
o_diag_res(C_DIAG_STATE_CTRL_RES_BPOS_SCP_LS_MSB downto C_DIAG_STATE_CTRL_RES_BPOS_SCP_LS_LSB) <= diag_res_flags.SCP_LS and i_lcmp_msk;

-- Diagnostics result mapping to data register OL flags
proc_out_o_diag_res_ol:
o_diag_res(C_DIAG_STATE_CTRL_RES_BPOS_OL_MSB downto C_DIAG_STATE_CTRL_RES_BPOS_OL_LSB) <= diag_res_flags.OL and i_lcmp_msk;

-- Diagnostics result mapping to data register SCG flag
proc_out_o_diag_res_scg:
  o_diag_res(C_DIAG_STATE_CTRL_RES_BPOS_SCG) <= diag_res_flags.SCG;

-- Diagnostics result mapping to data register SCP flag
proc_out_o_diag_res_scp:
o_diag_res(C_DIAG_STATE_CTRL_RES_BPOS_SCP) <= diag_res_flags.SCP;

-- Diagnostics result mapping to NO USED bits
proc_out_o_diag_res_not_used:
o_diag_res(C_DIAG_STATE_CTRL_RES_BPOS_NOTUSED_MSB downto C_DIAG_STATE_CTRL_RES_BPOS_NOTUSED_LSB) <= (others => '0');

--------------------------------------------------------------------------------
-- Diagnostics state timer/counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
diag_state_count_unit: count_mod_m
  generic map (
    M     => C_DIAG_STATE_CTRL_COUNT_MODULO_PLUS1,
    INIT  => C_DIAG_STATE_CTRL_COUNT_INIT,
    DIR   => UP
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => diag_cnt_clr,
    i_tck => diag_cnt_tck,
    -- Output ports ------------------------------------------------------------
    o_cnt => diag_cnt_cnt
  );

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;