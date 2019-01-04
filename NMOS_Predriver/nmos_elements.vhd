--------------------------------------------------------------------------------
-- File: nmos_elements.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-03-23 #$: Date of last commit
-- $Rev:: 39           $: Revision of last commit
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
-- Package declarations
--------------------------------------------------------------------------------
package nmos_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- NMOS Pre-driver Synchronization ---------------------------------------------
component nmos_io_sync is
  generic (
    NMOS_GUARD_LEN  : natural;
    NMOS_HGRP_LEN   : natural;
    NMOS_LGRP_LEN   : natural;
    NMOS_HCTRL_INIT : std_logic;
    NMOS_LCTRL_INIT : std_logic
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst           : in  std_logic;
    i_clk           : in  std_logic;
    i_hctrl_bst_na  : in  std_logic_vector(NMOS_HGRP_LEN-1 downto 0);
    i_hctrl_bat_na  : in  std_logic_vector(NMOS_HGRP_LEN-1 downto 0);
    i_lctrl_sel_na  : in  std_logic_vector(NMOS_LGRP_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_hctrl_bst_n   : out std_logic_vector(NMOS_HGRP_LEN-1 downto 0);
    o_hctrl_bat_n   : out std_logic_vector(NMOS_HGRP_LEN-1 downto 0);
    o_lctrl_sel_n   : out std_logic_vector(NMOS_LGRP_LEN-1 downto 0)
  );
end component nmos_io_sync;

-- NMOS Pre-driver Control Sequencer -------------------------------------------
component nmos_pdrv_seq is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys           : in  sys_ctrl_t;
    i_ovld          : in  std_logic;
    i_ctrl          : in  std_logic;
    i_diag          : in  std_logic;
    i_prot_set      : in  std_logic;
    i_prot_clr      : in  std_logic;
    i_tsoff_cnt_ovr : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_trst_n        : out std_logic;
    o_ctrl          : out std_logic;
    o_soff          : out std_logic;
    o_tsoff_cnt_clr : out std_logic;
    o_tsoff_cnt_tck : out std_logic
  );
end component nmos_pdrv_seq;

-- NMOS Pre-driver Control -----------------------------------------------------
component nmos_pdrv_ctrl is
  generic (
    CUR_LEN    : natural;
    TSOFF_LEN  : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys      : in  sys_ctrl_t;
    i_ovld     : in  std_logic;
    i_ctrl     : in  std_logic;
    i_diag     : in  std_logic;
    i_prot_set : in  std_logic;
    i_prot_clr : in  std_logic;
    i_cur      : in  std_logic_vector(CUR_LEN-1 downto 0);
    i_tsoff    : in  std_logic_vector(TSOFF_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_trst_n   : out std_logic;
    o_ctrl     : out std_logic;
    o_soff     : out std_logic;
    o_cur      : out std_logic_vector(CUR_LEN-1 downto 0)
  );
end component nmos_pdrv_ctrl;

-- NMOS Protection Sequencer ---------------------------------------------------
component nmos_prot_seq is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys           : in  sys_ctrl_t;
    i_ctrl_bst      : in  std_logic;
    i_ctrl_bat      : in  std_logic;
    i_diag_prot_ena : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_tbst_bat_ena  : out std_logic;
    o_tbat_bst_ena  : out std_logic;
    o_tbxt_diag_ena : out std_logic;
    o_diag_tbst_ena : out std_logic;
    o_diag_tbat_ena : out std_logic
  );
end component nmos_prot_seq;

-- NMOS Protection Control -----------------------------------------------------
component nmos_prot_ctrl is
  generic (
    CUR_LEN         : natural;
    TSLP_LEN        : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys           : in  sys_ctrl_t;
    i_ctrl_bst      : in  std_logic;
    i_ctrl_bat      : in  std_logic;
    i_diag_prot_ena : in  std_logic;
    i_cur_bst       : in  std_logic_vector(CUR_LEN-1 downto 0);
    i_tslp_bst      : in  std_logic_vector(TSLP_LEN-1 downto 0);
    i_cur_bat       : in  std_logic_vector(CUR_LEN-1 downto 0);
    i_tslp_bat      : in  std_logic_vector(TSLP_LEN-1 downto 0);
    i_cur_diag      : in  std_logic_vector(CUR_LEN-1 downto 0);
    -- Output ports ---------------------------------------------
    o_cur           : out std_logic_vector(CUR_LEN-1 downto 0)
  );
end component nmos_prot_ctrl;

-- NMOS High Side Pre-Driver ---------------------------------------------------
component nmos_hs_pdrv is
  generic (
    NMOS_CUR_LEN      : natural;
    NMOS_TSOFF_LEN    : natural;
    PROT_CUR_LEN      : natural;
    PROT_TSLP_LEN     : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys             : in  sys_ctrl_t;
    i_nmos_ovld_bst   : in  std_logic;
    i_nmos_ctrl_bst   : in  std_logic;
    i_nmos_cur_bst    : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    i_nmos_tsoff_bst  : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
    i_nmos_ovld_bat   : in  std_logic;
    i_nmos_ctrl_bat   : in  std_logic;
    i_nmos_cur_bat    : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    i_nmos_tsoff_bat  : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
    i_prot_cur_bst    : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_prot_tslp_bst   : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_prot_set_bst    : in  std_logic;
    i_prot_clr_bst    : in  std_logic;
    i_prot_cur_bat    : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_prot_tslp_bat   : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_prot_set_bat    : in  std_logic;
    i_prot_clr_bat    : in  std_logic;
    i_prot_cur_diag   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_diag_ctrl       : in  std_logic;
    i_diag_prot_ena   : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_nmos_trst_bst_n : out std_logic;
    o_nmos_ctrl_bst   : out std_logic;
    o_nmos_soff_bst   : out std_logic;
    o_nmos_cur_bst    : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    o_nmos_trst_bat_n : out std_logic;
    o_nmos_ctrl_bat   : out std_logic;
    o_nmos_soff_bat   : out std_logic;
    o_nmos_cur_bat    : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    o_prot_cur        : out std_logic_vector(PROT_CUR_LEN-1 downto 0)
  );
end component nmos_hs_pdrv;

-- NMOS Low Side Pre-Driver ----------------------------------------------------
component nmos_ls_pdrv is
  generic (
    NMOS_HGRP_LEN     : natural;
    NMOS_CUR_LEN      : natural;
    NMOS_TSOFF_LEN    : natural;
    PROT_CUR_LEN      : natural;
    PROT_TSLP_LEN     : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys             : in  sys_ctrl_t;
    i_nmos_ctrl_bst   : in  std_logic;
    i_nmos_ctrl_bat   : in  std_logic;
    i_nmos_ovld_sel   : in  std_logic;
    i_nmos_ctrl_sel   : in  std_logic;
    i_nmos_cur_sel    : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    i_nmos_tsoff_sel  : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
    i_prot_cur_bst    : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_prot_tslp_bst   : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_prot_cur_bat    : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_prot_tslp_bat   : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_prot_set_sel    : in  std_logic;
    i_prot_clr_sel    : in  std_logic;
    i_prot_cur_diag   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_diag_ctrl       : in  std_logic;
    i_diag_prot_ena   : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_nmos_trst_sel_n : out std_logic;
    o_nmos_ctrl_sel   : out std_logic;
    o_nmos_soff_sel   : out std_logic;
    o_nmos_cur_sel    : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    o_prot_cur        : out std_logic_vector(PROT_CUR_LEN-1 downto 0)
  );
end component nmos_ls_pdrv;

end package nmos_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body nmos_elements is
end package body nmos_elements;