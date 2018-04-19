--------------------------------------------------------------------------------
-- File: nmos_pdrv_elements.vhd
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
package nmos_pdrv_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------

-- NMOS pre-driver high side switch type ---------------------------------------
type nmos_pdrv_hs_switch_t is (
  BAT,    -- Battery switch
  BST     -- Boost switch
);

-- NMOS pre-driver high side group type ----------------------------------------
type nmos_pdrv_hs_grp_t is array (nmos_pdrv_hs_switch_t) of std_logic;

-- NMOS pre-driver high side location type -------------------------------------
-- TODO::This type needs to be updated when the number of high side pre-drivers
-- is modified.
type nmos_pdrv_hs_loc_t is (
  HSA,    -- Pre-driver group A
  HSB,    -- Pre-driver group B
  HSC     -- Pre-driver group C
);

-- NMOS pre-driver high side control type --------------------------------------
type nmos_pdrv_hs_ctrl_t is array (nmos_pdrv_hs_loc_t) of nmos_pdrv_hs_grp_t;

-- NMOS pre-driver low side location type --------------------------------------
type nmos_pdrv_ls_loc_t is (
  SEL0,   -- Pre-driver selection 0
  SEL1,   -- Pre-driver selection 1
  SEL2,   -- Pre-driver selection 2
  SEL3    -- Pre-drvier selection 3
);

-- NMOS pre-driver low side control type ---------------------------------------
type nmos_pdrv_ls_ctrl_t is array (nmos_pdrv_ls_loc_t) of std_logic;

-- NMOS pre-driver diagnostics control type ------------------------------------
type nmos_pdrv_diag_ctrl_t is record 
  CTRL : std_logic;   -- Diagnostics NMOS control
  PENA : std_logic;   -- Diagnostics protection enable
end record;

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- NMOS Pre-driver Control -----------------------------------------------------
component nmos_pdrv_ctrl is
  generic (
    CUR_LEN    : natural;
    TSOFF_LEN  : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys      : in  sys_ctrl_t;
    i_ctrl     : in  std_logic;
    i_diag     : in  std_logic;
    i_prot_set : in  std_logic;
    i_prot_clr : in  std_logic;
    i_cur      : in  std_logic_vector(CUR_LEN-1 downto 0);
    i_tsoff    : in  std_logic_vector(TSOFF_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
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
    i_bst_ctrl      : in  std_logic;
    i_bat_ctrl      : in  std_logic;
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
    i_bst_ctrl      : in  std_logic;
    i_bat_ctrl      : in  std_logic;
    i_diag_prot_ena : in  std_logic;
    i_bst_cur       : in  std_logic_vector(CUR_LEN-1 downto 0);
    i_bst_tslp      : in  std_logic_vector(TSLP_LEN-1 downto 0);
    i_bat_cur       : in  std_logic_vector(CUR_LEN-1 downto 0);
    i_bat_tslp      : in  std_logic_vector(TSLP_LEN-1 downto 0);
    i_diag_cur      : in  std_logic_vector(CUR_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_cur           : out std_logic_vector(CUR_LEN-1 downto 0)
  );
end component nmos_prot_ctrl;

-- NMOS High Side Pre-Driver ---------------------------------------------------
component nmos_hs_pdrv is
  generic (
    NMOS_CUR_LEN     : natural;
    NMOS_TSOFF_LEN   : natural;
    PROT_CUR_LEN     : natural;
    PROT_TSLP_LEN    : natural;
    PROT_CMP_LEN     : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys            : in  sys_ctrl_t;
    i_bst_nmos_ctrl  : in  std_logic;
    i_bat_nmos_ctrl  : in  std_logic;
    i_diag_nmos_ctrl : in  std_logic;
    i_diag_prot_ena  : in  std_logic;
    i_bst_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    i_bst_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
    i_bat_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    i_bat_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
    i_bst_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_bst_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_bat_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_bat_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_diag_prot_cur  : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_prot_cmp       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
    i_prot_msk       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
    i_prot_clr       : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_bst_nmos_ctrl  : out std_logic;
    o_bst_nmos_soff  : out std_logic;
    o_bst_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    o_bat_nmos_ctrl  : out std_logic;
    o_bat_nmos_soff  : out std_logic;
    o_bat_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    o_prot_cur       : out std_logic_vector(PROT_CUR_LEN-1 downto 0)
  );
end component nmos_hs_pdrv;

-- NMOS Low Side Pre-Driver ----------------------------------------------------
component nmos_ls_pdrv is
  generic (
    NMOS_HBNK_LEN    : natural;
    NMOS_CUR_LEN     : natural;
    NMOS_TSOFF_LEN   : natural;
    PROT_CUR_LEN     : natural;
    PROT_TSLP_LEN    : natural;
    PROT_CMP_LEN     : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys            : in  sys_ctrl_t;
    i_bst_nmos_ctrl  : in  std_logic_vector(NMOS_HBNK_LEN-1 downto 0);
    i_bat_nmos_ctrl  : in  std_logic_vector(NMOS_HBNK_LEN-1 downto 0);
    i_diag_nmos_ctrl : in  std_logic;
    i_diag_prot_ena  : in  std_logic;
    i_sel_nmos_ctrl  : in  std_logic;
    i_sel_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    i_sel_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
    i_bst_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_bst_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_bat_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_bat_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
    i_diag_prot_cur  : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
    i_prot_cmp       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
    i_prot_msk       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
    i_prot_clr       : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_sel_nmos_ctrl  : out std_logic;
    o_sel_nmos_soff  : out std_logic;
    o_sel_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
    o_prot_cur       : out std_logic_vector(PROT_CUR_LEN-1 downto 0)
  );
end component nmos_ls_pdrv;

end package nmos_pdrv_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body nmos_pdrv_elements is
end package body nmos_pdrv_elements;