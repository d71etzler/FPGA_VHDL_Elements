--------------------------------------------------------------------------------
-- File: diag_elements.vhd
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
package diag_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------

-- Low side control bit vector length
constant C_DIAG_STATE_LS_CTRL_LEN : natural := 4;

-- Diagnostics result flags bit positions
constant C_DIAG_CTRL_RES_BPOS_VALID   : natural := 0;                                                       -- Diagnostics result bit position VALID flag
constant C_DIAG_CTRL_RES_BPOS_SCG_HS  : natural := C_DIAG_CTRL_RES_BPOS_VALID+1;                            -- Diagnostics result bit position SCG_HS flag
constant C_DIAG_CTRL_RES_BPOS_SCP_LS  : natural := C_DIAG_CTRL_RES_BPOS_SCG_HS+1;                           -- Diagnostics result bit position SCP_LS flags (LSB)
constant C_DIAG_CTRL_RES_BPOS_OL      : natural := C_DIAG_CTRL_RES_BPOS_SCP_LS+C_DIAG_STATE_LS_CTRL_LEN;    -- Diagnostics result bit position OL flags (LSB)
constant C_DIAG_CTRL_RES_BPOS_SCG     : natural := C_DIAG_CTRL_RES_BPOS_OL+C_DIAG_STATE_LS_CTRL_LEN;        -- Diagnostics result bit position SCG flag
constant C_DIAG_CTRL_RES_BPOS_SCP     : natural := C_DIAG_CTRL_RES_BPOS_SCG+1;                              -- Diagnostics result bit position SCP flag
constant C_DIAG_CTRL_RES_BPOS_NOTUSED : natural := C_DIAG_CTRL_RES_BPOS_SCP+1;                              -- Diagnostics result bit position NOT USED flags

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------

-- Diagnostics result vector type ----------------------------------------------
type diag_res_t is record
  SCP    : std_logic;
  SCG    : std_logic;
  OL     : std_logic_vector(C_DIAG_STATE_LS_CTRL_LEN-1 downto 0);
  SCP_LS : std_logic_vector(C_DIAG_STATE_LS_CTRL_LEN-1 downto 0);
  SCG_HS : std_logic;
  VALID  : std_logic;
end record diag_res_t;

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- Diagnostics state-machine sequencer -----------------------------------------
component diag_state_seq is
  generic (
    DIAG_LGRP_LEN      : natural;
    DIAG_CNT_LEN       : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys              : in  sys_ctrl_t;
    i_diag_state_ena   : in  std_logic;
    i_diag_cnt_cnt     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_hcmp_voltage     : in  std_logic;
    i_hcmp_current     : in  std_logic;
    i_lcmp_current     : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    i_tcmp_prep_idle   : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_scp      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_scg      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_ol       : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_rslv     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_hi_scp      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_hi_scg      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_hi_rslv     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_valid       : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_prep_repeat : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_lcmp_msk         : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_diag_cnt_clr     : out std_logic;
    o_diag_cnt_tck     : out std_logic;
    o_diag_prot_ena    : out std_logic;
    o_hdiag_ctrl       : out std_logic;
    o_hdiag_pu         : out std_logic;
    o_hdiag_pd         : out std_logic;
    o_ldiag_ctrl       : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    o_ldiag_pd         : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    o_diag_res_flags   : out diag_res_t
  );
end component diag_state_seq;

-- Diagnostics state-machine control -------------------------------------------
component diag_state_ctrl is
  generic (
    DIAG_HPOS_LEN      : natural := 2;
    DIAG_LGRP_LEN      : natural := 4;
    DIAG_CNT_LEN       : natural := 20;
    DIAG_DATA_LEN      : natural := 16
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys              : in  sys_ctrl_t;
    i_hctrl            : in  std_logic_vector(DIAG_HPOS_LEN-1 downto 0);
    i_hcmp_voltage     : in  std_logic;
    i_hcmp_current     : in  std_logic;
    i_lctrl            : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    i_lcmp_current     : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    i_tcmp_prep_idle   : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_scp      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_scg      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_ol       : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_li_rslv     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_hi_scp      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_hi_scg      : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_hi_rslv     : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_valid       : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_tcmp_prep_repeat : in  std_logic_vector(DIAG_CNT_LEN-1 downto 0);
    i_lcmp_msk         : in  std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_hdiag_prot_ena   : out std_logic;
    o_hdiag_ctrl       : out std_logic;
    o_hdiag_pu         : out std_logic;
    o_hdiag_pd         : out std_logic;
    o_ldiag_prot_ena   : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    o_ldiag_ctrl       : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    o_ldiag_pd         : out std_logic_vector(DIAG_LGRP_LEN-1 downto 0);
    o_diag_res         : out std_logic_vector(DIAG_DATA_LEN-1 downto 0)
  );
end component diag_state_ctrl;

end package diag_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body diag_elements is
end package body diag_elements;