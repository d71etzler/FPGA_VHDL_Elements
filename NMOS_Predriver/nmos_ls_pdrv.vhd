--------------------------------------------------------------------------------
-- File: nmos_ls_pdrv.vhd
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
  use nmos.nmos_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity nmos_ls_pdrv is
  generic (
    NMOS_HGRP_LEN     : natural := 3;                                       -- NMOS high side group length
    NMOS_CUR_LEN      : natural := 3;                                       -- NMOS charge/discharge current selection length (in bits)
    NMOS_TSOFF_LEN    : natural := 16;                                      -- Strong-OFF timer register length (in bits)
    PROT_CUR_LEN      : natural := 8;                                       -- Protection current selection length (in bits)
    PROT_TSLP_LEN     : natural := 16                                       -- Protection slope timer register length (in bits)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys             : in  sys_ctrl_t;                                     -- System control
    i_nmos_ctrl_bst   : in  std_logic;                                      -- Boost NMOS pre-driver control
    i_nmos_ctrl_bat   : in  std_logic;                                      -- Battery NMOS pre-driver control
    i_nmos_ovld_sel   : in  std_logic;                                      -- Selection NMOS over-load control
    i_nmos_ctrl_sel   : in  std_logic;                                      -- Selection NMOS pre-driver control
    i_nmos_cur_sel    : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);      -- Selection NMOS charge/discharge current selection
    i_nmos_tsoff_sel  : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);    -- Selection NMOS strong-OFF timer value
    i_prot_cur_bst    : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);      -- Boost NMOS protection current
    i_prot_tslp_bst   : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);     -- Boost NMOS slope timer value
    i_prot_cur_bat    : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);      -- Battery NMOS protection current
    i_prot_tslp_bat   : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);     -- Battery NMOS slope timer value
    i_prot_set_sel    : in  std_logic;                                      -- Selection NMOS protection register set
    i_prot_clr_sel    : in  std_logic;                                      -- Selection NMOS protection register clear
    i_prot_cur_diag   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);      -- Diagnostics protection current
    i_diag_ctrl       : in  std_logic;                                      -- Diagnostics control
    i_diag_prot_ena   : in  std_logic;                                      -- Diagnostics protection enable
    -- Output ports ------------------------------------------------------------
    o_nmos_trst_sel_n : out std_logic;                                      -- Selection NMOS tri-state control
    o_nmos_ctrl_sel   : out std_logic;                                      -- Selection NMOS pre-driver control
    o_nmos_soff_sel   : out std_logic;                                      -- Selection NMOS strong-OFF control
    o_nmos_cur_sel    : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);      -- Selection NMOS charge/discharge current
    o_prot_cur        : out std_logic_vector(PROT_CUR_LEN-1 downto 0)       -- Protection comparator current threshold
  );
end entity nmos_ls_pdrv;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of nmos_ls_pdrv is
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

-- Check generic NMOS_TSOFF_LEN for valid value -------------------------------------
assert ((NMOS_TSOFF_LEN > 0) and (NMOS_TSOFF_LEN <= 16))
  report "Bit vector length of generic >NMOS_TSOFF_LEN< specified incorrectly!"
  severity error;

-- Check generic PROT_CUR_LEN for valid value ----------------------------------
assert ((PROT_CUR_LEN > 0) and (PROT_CUR_LEN <= 8))
  report "Bit vector length of generic >PROT_CUR_LEN< specified incorrectly!"
  severity error;

-- Check generic PROT_TSLP_LEN for valid value -------------------------------------
assert ((PROT_TSLP_LEN > 0) and (PROT_TSLP_LEN <= 16))
  report "Bit vector length of generic >PROT_TSLP_LEN< specified incorrectly!"
  severity error;

--------------------------------------------------------------------------------
-- Selection NMOS pre-driver control
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
nmos_ls_pdrv_sel_unit: nmos_pdrv_ctrl
  generic map (
    CUR_LEN    => NMOS_CUR_LEN,
    TSOFF_LEN  => NMOS_TSOFF_LEN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys      => i_sys,
    i_ovld     => i_nmos_ovld_sel,
    i_ctrl     => i_nmos_ctrl_sel,
    i_diag     => i_diag_ctrl,
    i_prot_set => i_prot_set_sel,
    i_prot_clr => i_prot_clr_sel,
    i_cur      => i_nmos_cur_sel,
    i_tsoff    => i_nmos_tsoff_sel,
    -- Output ports ------------------------------------------------------------
    o_trst_n   => o_nmos_trst_sel_n,
    o_ctrl     => o_nmos_ctrl_sel,
    o_soff     => o_nmos_soff_sel,
    o_cur      => o_nmos_cur_sel
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- NMOS pre-driver protection control
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
nmos_ls_prdrv_prot_unit: nmos_prot_ctrl
  generic map (
    CUR_LEN         => PROT_CUR_LEN,
    TSLP_LEN        => PROT_TSLP_LEN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys           => i_sys,
    i_ctrl_bst      => i_nmos_ctrl_bst,
    i_ctrl_bat      => i_nmos_ctrl_bat,
    i_diag_prot_ena => i_diag_prot_ena,
    i_cur_bst       => i_prot_cur_bst,
    i_tslp_bst      => i_prot_tslp_bst,
    i_cur_bat       => i_prot_cur_bat,
    i_tslp_bat      => i_prot_tslp_bat,
    i_cur_diag      => i_prot_cur_diag,
    -- Output ports ------------------------------------------------------------
    o_cur           => o_prot_cur
  );

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;