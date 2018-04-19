--------------------------------------------------------------------------------
-- File: nmos_pdrv.vhd
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
entity nmos_pdrv is
  generic (
    NMOS_HGRP_NUM    : natural := 3;                                      -- NMOS high side group number
    NMOS_LGRP_NUM    : natural := 4;                                      -- NMOS low side group number
    NMOS_CUR_LEN     : natural := 3;                                      -- NMOS charge/discharge current selection length (in bits)
    NMOS_TSOFF_LEN   : natural := 16;                                     -- Strong-OFF timer register length (in bits)
    PROT_CUR_LEN     : natural := 8;                                      -- Protection current selection register length (in bits)
    PROT_TSLP_LEN    : natural := 16;                                     -- Proetection slope timer register length (in bits)
    PROT_CMP_LEN     : natural := 7                                       -- Protection comparator register length (in bits)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys            : in  sys_ctrl_t;                                    -- System control
    i_hs_ctrl_na     : in  nmos_pdrv_hs_ctrl_t;                           -- NMOS pre-driver high side control
    i_ls_ctrl_na     : in  nmos_pdrv_ls_ctrl_t;                           -- NMOS pre-driver low side control
    i_diag_ctrl      : in  nmos_pdrv_diag_ctrl_t;                         -- NMOS pre-driver diagnostics control (NMOS control, protection enable)

    i_bst_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Boost NMOS charge/discharge current selection
    i_bst_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);   -- Boost NMOS strong-OFF timer value
    i_bat_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Battery NMOS charge/discharge current selection
    i_bat_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);   -- Battery NMOS strong-OFF timer value
    i_bst_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Boost NMOS protection current
    i_bst_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);    -- Battery-to-Boost NMOS protection slope timer value
    i_bat_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Battery NMOS protection current
    i_bat_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);    -- Boost-to-Battery NMOS protection slope timer value
    i_diag_prot_cur  : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Diagnostics NMOS protection current
    i_prot_cmp       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);     -- Protection comparator inputs (from all possible instances)
    i_prot_msk       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);     -- Protection comparator masks (cross-links between pre-drivers, topology dependent)
    i_prot_clr       : in  std_logic;                                     -- Protection register clear
    -- Output ports ------------------------------------------------------------
    o_bst_nmos_ctrl  : out std_logic;                                     -- Boost NMOS pre-driver control
    o_bst_nmos_soff  : out std_logic;                                     -- Boost NMOS strong-OFF control
    o_bst_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Boost NMOS charge/discharge current
    o_bat_nmos_ctrl  : out std_logic;                                     -- Battery NMOS pre-driver control
    o_bat_nmos_soff  : out std_logic;                                     -- Battery NMOS strong-Off control
    o_bat_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Battery NMOS charge/discharge control
    o_prot_cur       : out std_logic_vector(PROT_CUR_LEN-1 downto 0)      -- Protection comparator current threshold
  );
end entity nmos_pdrv;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of nmos_pdrv is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  -- (none)
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------

-- Check generic NMOS_CUR_LEN for valid value ----------------------------------
assert ((NMOS_CUR_LEN > 0) and (NMOS_CUR_LEN <= 3))
  report "Bit vector length of generic >NMOS_CUR_LEN< specified incorrectly!"
  severity error;

-- Check generic NMOS_TSOFF_LEN for valid value --------------------------------
assert ((NMOS_TSOFF_LEN > 0) and (NMOS_TSOFF_LEN <= 16))
  report "Bit vector length of generic >NMOS_TSOFF_LEN< specified incorrectly!"
  severity error;

-- Check generic PROT_CUR_LEN for valid value ----------------------------------
assert ((PROT_CUR_LEN > 0) and (PROT_CUR_LEN <= 8))
  report "Bit vector length of generic >PROT_CUR_LEN< specified incorrectly!"
  severity error;

-- Check generic PROT_TSLP_LEN for valid value ---------------------------------
assert ((PROT_TSLP_LEN > 0) and (PROT_TSLP_LEN <= 16))
  report "Bit vector length of generic >PROT_TSLP_LEN< specified incorrectly!"
  severity error;

-- Check generic PCMP_LEN for valid value --------------------------------------
assert ((PROT_CMP_LEN > 0) and (PROT_CMP_LEN <= 7))
  report "Bit vector length of generic >PROT_CMP_LEN< specified incorrectly!"
  severity error;

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
-- (none)

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
--gen_nmos_pdrv_hs_unit : for i in 0 to (NMOS_HGRP_NUM-1) generate
--  nmos_pdrv_hs_unit: nmos_hs_pdrv
--    generic map (
--      NMOS_CUR_LEN     => NMOS_CUR_LEN,
--      NMOS_TSOFF_LEN   => NMOS_TSOFF_LEN,
--      PROT_CUR_LEN     => PROT_CUR_LEN,
--      PROT_TSLP_LEN    => PROT_TSLP_LEN,
--      PROT_CMP_LEN     => PROT_CMP_LEN
--    )
--    port map (
--      -- Input ports -------------------------------------------------------------
--      i_sys            => i_sys,
--      i_bst_nmos_ctrl  => hpdrv_nmos_ctrl(i),
--      i_bat_nmos_ctrl  => hpdrv_nmos_ctrl(i),
--      i_diag_nmos_ctrl => diag_nmos_ctrl(i),
--      i_diag_prot_ena  : in  std_logic;
--      i_bst_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
--      i_bst_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
--      i_bat_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
--      i_bat_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
--      i_bst_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
--      i_bst_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
--      i_bat_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
--      i_bat_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
--      i_diag_prot_cur  : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
--      i_prot_cmp       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
--      i_prot_msk       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
--      i_prot_clr       : in  std_logic;
--      -- Output ports ------------------------------------------------------------
--      o_bst_nmos_ctrl  : out std_logic;
--      o_bst_nmos_soff  : out std_logic;
--      o_bst_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
--      o_bat_nmos_ctrl  : out std_logic;
--      o_bat_nmos_soff  : out std_logic;
--      o_bat_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
--      o_prot_cur       : out std_logic_vector(PROT_CUR_LEN-1 downto 0)
--    );
--end generate;

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
--gen_nmos_pdrv_ls_unit : for i in 0 to (NMOS_LGRP_NUM-1) generate
--  nmos_pdrv_ls_unit: nmos_ls_pdrv
--    generic map (
--      NMOS_HBNK_LEN    => NMOS_HBNK_LEN,
--      NMOS_CUR_LEN     => NMOS_CUR_LEN
--      NMOS_TSOFF_LEN   => NMOS_TSOFF_LEN,
--      PROT_CUR_LEN     => PROT_CUR_LEN,
--      PROT_TSLP_LEN    => PROT_TSLP_LEN,
--      PROT_CMP_LEN     => PROT_CMP_LEN
--    )
--    port map (
--      -- Input ports -------------------------------------------------------------
--      i_sys            => i_sys,
--      i_bst_nmos_ctrl  : in  std_logic_vector(NMOS_HBNK_LEN-1 downto 0);
--      i_bat_nmos_ctrl  : in  std_logic_vector(NMOS_HBNK_LEN-1 downto 0);
--      i_diag_nmos_ctrl : in  std_logic;
--      i_diag_prot_ena  : in  std_logic;
--      i_sel_nmos_ctrl  : in  std_logic;
--      i_sel_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);
--      i_sel_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);
--      i_bst_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
--      i_bst_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
--      i_bat_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
--      i_bat_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);
--      i_diag_prot_cur  : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);
--      i_prot_cmp       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
--      i_prot_msk       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);
--      i_prot_clr       : in  std_logic;
--      -- Output ports ------------------------------------------------------------
--      o_sel_nmos_ctrl  : out std_logic;
--      o_sel_nmos_soff  : out std_logic;
--      o_sel_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);
--      o_prot_cur       : out std_logic_vector(PROT_CUR_LEN-1 downto 0)
--    );
-- end generate;

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;