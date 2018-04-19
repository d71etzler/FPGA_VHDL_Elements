--------------------------------------------------------------------------------
-- File: nmos_prot_ctrl.vhd
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
  use math.logic_functions.all;
library nmos;
  use nmos.nmos_pdrv_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity nmos_prot_ctrl is
  generic (
    CUR_LEN         : natural := 8;                                 -- Protection current selection length (in bits)
    TSLP_LEN        : natural := 16                                 -- Slope timer register length (in bits)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys           : in  sys_ctrl_t;                               -- System control
    i_bst_ctrl      : in  std_logic;                                -- Boost NMOS pre-driver control
    i_bat_ctrl      : in  std_logic;                                -- Battery NMOS pre-driver control
    i_diag_prot_ena : in  std_logic;                                -- Diagnostics protetion enable
    i_bst_cur       : in  std_logic_vector(CUR_LEN-1 downto 0);     -- Boost NMOS protection current
    i_bst_tslp      : in  std_logic_vector(TSLP_LEN-1 downto 0);    -- Battery-to-Boost slope timer prescale value
    i_bat_cur       : in  std_logic_vector(CUR_LEN-1 downto 0);     -- Battery NMOS protection current
    i_bat_tslp      : in  std_logic_vector(TSLP_LEN-1 downto 0);    -- Boost-to-Battery slope timer prescale value
    i_diag_cur      : in  std_logic_vector(CUR_LEN-1 downto 0);     -- Diagnostics NMOS protection current
    -- Output ports ------------------------------------------------------------
    o_cur           : out std_logic_vector(CUR_LEN-1 downto 0)      -- Protection comparator current threshold
  );
end entity nmos_prot_ctrl;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of nmos_prot_ctrl is
  -- Constants -----------------------------------------------------------------
  constant C_NMOS_PROT_CTRL_TBST_TO_BAT_COUNT_MODULO_PLUS1  : natural                                                           := 2**TSLP_LEN;       -- Boost-to-Battery NMOS slope timer modulo value
  constant C_NMOS_PROT_CTRL_TBST_TO_BAT_COUNT_INIT          : natural                                                           := 0;                 -- Boost-to-Battery NMOS slope timer initial value
  constant C_NMOS_PROT_CTRL_TBAT_TO_BST_COUNT_MODULO_PLUS1  : natural                                                           := 2**TSLP_LEN;       -- Battery-to-Boost NMOS slope timer modulo value
  constant C_NMOS_PROT_CTRL_TBAT_TO_BST_COUNT_INIT          : natural                                                           := 0;                 -- Battery-to-Boost NMOS slope timer initial value
  constant C_NMOS_PROT_CTRL_TBXT_TO_DIAG_COUNT_MODULO_PLUS1 : natural                                                           := 2**TSLP_LEN;       -- Boost-to-/Battery-to-Diagnostics slope timer modulo value
  constant C_NMOS_PROT_CTRL_TBXT_TO_DIAG_COUNT_INIT         : natural                                                           := 0;                 -- Boost-to-/Battery-to-Diagnostics slope timer initial value
  constant C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_LEN             : natural                                                           := CUR_LEN;           -- Protection current threshold multiplexer buffer length
  constant C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_INIT            : std_logic_vector(C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_LEN-1 downto 0) := (others => '1');   -- Protection current threshold multiplexer buffer initial length
  -- Types ---------------------------------------------------------------------
  type cur_thr_count_lpsd_t is (
    NO_CHANGE,
    TBST_BAT_LPSD,
    TBAT_BST_LPSD,
    TBXT_DIAG_LPSD,
    DIAG_TBST_LPSD,
    DIAG_TBAT_LPSD
  );
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal tbst_bat_count_ena   : std_logic                                                         := '0';                                     -- Boost-to-Battery NMOS slope timer enable
  signal tbst_bat_count_clr   : std_logic                                                         := '1';                                     -- Boost-to-Battery NMOS slope timer clear
  signal tbst_bat_count_tck   : std_logic                                                         := '0';                                     -- Boost-to-Battery NMOS slope timer tick
  signal tbst_bat_count_cnt   : std_logic_vector(TSLP_LEN-1 downto 0)                             := (others => '0');                         -- Boost-to-Battery NMOS slope timer value
  signal tbat_bst_count_ena   : std_logic                                                         := '0';                                     -- Battery-to-Boost NMOS slope timer enable
  signal tbat_bst_count_clr   : std_logic                                                         := '1';                                     -- Battery-to-Boost NMOS slope timer clear
  signal tbat_bst_count_tck   : std_logic                                                         := '0';                                     -- Battery-to-Boost NMOS slope timer tick
  signal tbat_bst_count_cnt   : std_logic_vector(TSLP_LEN-1 downto 0)                             := (others => '0');                         -- Battery-to-Boost NMOS slope timer value
  signal tbxt_diag_count_ena  : std_logic                                                         := '0';                                     -- Boost-to-/Battery-to-Diagnostics slope timer enable
  signal diag_tbst_count_ena  : std_logic                                                         := '0';                                     -- Diagnostics-to-Boost slope timer enable
  signal diag_tbat_count_ena  : std_logic                                                         := '0';                                     -- Diagnostics-to-Battery slope timer enable
  signal cur_thr_count_lpsd   : cur_thr_count_lpsd_t                                              := TBST_BAT_LPSD;                           -- Current threshold slope timer elapsed flag
  signal cur_thr_set          : std_logic                                                         := '0';                                     -- Current threshold set
  signal cur_thr_mux          : std_logic_vector(C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_LEN-1 downto 0) := C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_INIT;   -- Current threshold multiplexed
  signal cur_thr_buf          : std_logic_vector(C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_LEN-1 downto 0) := C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_INIT;   -- Current threshold buffered
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------

-- Check generic CUR_LEN for valid value ---------------------------------------
assert ((CUR_LEN > 0) and (CUR_LEN <= 8))
  report "Bit vector length of generic >CUR_LEN< specified incorrectly!"
  severity error;

-- Check generic TSOFF_LEN for valid value -------------------------------------
assert ((TSLP_LEN > 0) and (TSLP_LEN <= 16))
  report "Bit vector length of generic >TSLP_LEN< specified incorrectly!"
  severity error;

--------------------------------------------------------------------------------
-- Boost-NMOS/Battery-NMOS/Diagnostics change detector
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
nmos_prot_ctrl_nmos_change_unit: nmos_prot_seq
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys           => i_sys,
    i_bst_ctrl      => i_bst_ctrl,
    i_bat_ctrl      => i_bat_ctrl,
    i_diag_prot_ena => i_diag_prot_ena,
    -- Output ports ------------------------------------------------------------
    o_tbst_bat_ena  => tbst_bat_count_ena,
    o_tbat_bst_ena  => tbat_bst_count_ena,
    o_tbxt_diag_ena => tbxt_diag_count_ena,
    o_diag_tbst_ena => diag_tbst_count_ena,
    o_diag_tbat_ena => diag_tbat_count_ena
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Boost-to-Battery delay timer/counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Boost-to-Battery delay timer/counter clear
proc_in_tbst_bat_count_clr:
tbst_bat_count_clr <= '1' when (tbst_bat_count_ena = '0')
                 else '0';

-- Boost-to-Battery delay timer/counter tick
proc_in_tbst_bat_count_tck:
tbst_bat_count_tck <= '1' when ((tbst_bat_count_ena = '1') and (tbst_bat_count_cnt < i_bat_tslp))
                 else '0';

-- Component instantiation -----------------------------------------------------
nmos_prot_tbst_to_bat_count_unit: count_mod_m
  generic map (
    M     => C_NMOS_PROT_CTRL_TBST_TO_BAT_COUNT_MODULO_PLUS1,
    INIT  => C_NMOS_PROT_CTRL_TBST_TO_BAT_COUNT_INIT,
    DIR   => UP
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => tbst_bat_count_clr,
    i_tck => tbst_bat_count_tck,
    -- Output ports ------------------------------------------------------------
    o_cnt => tbst_bat_count_cnt
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Battery-to-Boost delay timer/counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Battery-to-Boost delay timer/counter clear
proc_in_tbat_bst_count_clr:
tbat_bst_count_clr <= '1' when (tbat_bst_count_ena = '0')
                 else '0';

-- Battery-to-Boost delay timer/counter tick
proc_in_tbat_bst_count_tck:
tbat_bst_count_tck <= '1' when ((tbat_bst_count_ena = '1') and (tbat_bst_count_cnt < i_bst_tslp))
                 else '0';

-- Component instantiation -----------------------------------------------------
nmos_prot_tbat_to_bst_count_unit: count_mod_m
  generic map (
    M     => C_NMOS_PROT_CTRL_TBAT_TO_BST_COUNT_MODULO_PLUS1,
    INIT  => C_NMOS_PROT_CTRL_TBAT_TO_BST_COUNT_INIT,
    DIR   => UP
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => tbat_bst_count_clr,
    i_tck => tbat_bst_count_tck,
    -- Output ports ------------------------------------------------------------
    o_cnt => tbat_bst_count_cnt
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Current multiplexer selection
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Slope timers elapsed
proc_in_cur_thr_count_lpsd:
cur_thr_count_lpsd <= TBST_BAT_LPSD  when ((tbst_bat_count_ena  = '1') and (tbst_bat_count_cnt = i_bat_tslp))
                 else TBAT_BST_LPSD  when ((tbat_bst_count_ena  = '1') and (tbat_bst_count_cnt = i_bst_tslp))
                 else TBXT_DIAG_LPSD when  (tbxt_diag_count_ena = '1')
                 else DIAG_TBST_LPSD when  (diag_tbst_count_ena = '1')
                 else DIAG_TBAT_LPSD when  (diag_tbat_count_ena = '1')
                 else NO_CHANGE;

-- Current threshold multiplexer
proc_in_cur_thr_mux:
cur_thr_mux <= i_bst_cur  when (cur_thr_count_lpsd = TBAT_BST_LPSD)
          else i_bst_cur  when (cur_thr_count_lpsd = DIAG_TBST_LPSD)
          else i_bat_cur  when (cur_thr_count_lpsd = TBST_BAT_LPSD)
          else i_bat_cur  when (cur_thr_count_lpsd = DIAG_TBAT_LPSD)
          else i_diag_cur when (cur_thr_count_lpsd = TBXT_DIAG_LPSD)
          else cur_thr_buf;

-- Current threshold buffer set
proc_in_cur_thr_set:
cur_thr_set <= '1' when (cur_thr_count_lpsd /= NO_CHANGE)
          else '0';

-- Component instantiation -----------------------------------------------------
nmos_prot_cur_mux_unit: buffer_bvec
  generic map (
    LEN    => C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_LEN,
    INIT   => C_NMOS_PROT_CTRL_CUR_THR_MUX_BUF_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys  => i_sys,
    i_clr  => '0',
    i_set  => cur_thr_set,
    i_bvec => cur_thr_mux,
    -- Output ports ------------------------------------------------------------
    o_bvec => cur_thr_buf
  );

-- Output logic ----------------------------------------------------------------

-- Current threshold output
proc_out_o_cur:
o_cur <= cur_thr_buf;

end architecture structural;