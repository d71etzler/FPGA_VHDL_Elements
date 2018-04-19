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
  use nmos.nmos_pdrv_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity nmos_ls_pdrv is
  generic (
    NMOS_HBNK_LEN    : natural := 3;                                      -- NMOS high side bank length
    NMOS_CUR_LEN     : natural := 3;                                      -- NMOS charge/discharge current selection length (in bits)
    NMOS_TSOFF_LEN   : natural := 16;                                     -- Strong-OFF timer register length (in bits)
    PROT_CUR_LEN     : natural := 8;                                      -- Protection current selection length (in bits)
    PROT_TSLP_LEN    : natural := 16;                                     -- Protection slope timer register length (in bits)
    PROT_CMP_LEN     : natural := 7                                       -- Protection comparator length (in bits)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys            : in  sys_ctrl_t;                                    -- System control
    i_bst_nmos_ctrl  : in  std_logic_vector(NMOS_HBNK_LEN-1 downto 0);    -- Boost NMOS pre-driver control
    i_bat_nmos_ctrl  : in  std_logic_vector(NMOS_HBNK_LEN-1 downto 0);    -- Battery NMOS pre-driver control
    i_diag_nmos_ctrl : in  std_logic;                                     -- Diagnostics NMOS pre-driver control
    i_diag_prot_ena  : in  std_logic;                                     -- Diagnostics protection enable
    i_sel_nmos_ctrl  : in  std_logic;                                     -- Selection NMOS pre-driver control
    i_sel_nmos_cur   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Selection NMOS charge/discharge current selection
    i_sel_nmos_tsoff : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);   -- Selection NMOS strong-OFF timer value
    i_bst_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Boost NMOS protection current
    i_bst_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);    -- Battery-to-Boost NMOS protection slope timer value
    i_bat_prot_cur   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Battery NMOS protection current
    i_bat_prot_tslp  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);    -- Boost-to-Battery NMOS protection slope timer value
    i_diag_prot_cur  : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Diagnostics NMOS protection current
    i_prot_cmp       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);     -- Protection comparator inputs (from all possible instances)
    i_prot_msk       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);     -- Protection comparator masks (cross-links between pre-drivers, topology dependent)
    i_prot_clr       : in  std_logic;                                     -- Protection register clear
    -- Output ports ------------------------------------------------------------
    o_sel_nmos_ctrl  : out std_logic;                                     -- Selection NMOS pre-driver control
    o_sel_nmos_soff  : out std_logic;                                     -- Selection NMOS strong-OFF control
    o_sel_nmos_cur   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Selection NMOS charge/discharge current
    o_prot_cur       : out std_logic_vector(PROT_CUR_LEN-1 downto 0)      -- Protection comparator current threshold
  );
end entity nmos_ls_pdrv;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of nmos_ls_pdrv is
  -- Constants -----------------------------------------------------------------
  constant C_NMOS_LS_PDRV_NMOS_CTRL_PADDING : std_logic_vector(PROT_CMP_LEN-NMOS_HBNK_LEN-1 downto 0) := (others => '0');
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal sel_nmos_ctrl : std_logic := '0';                                -- Selection NMOS control
  signal sel_prot_set  : std_logic := '0';                                -- Selection NMOS protection set
  signal sel_prot_clr  : std_logic := '1';                                -- Selection NMOS protection clear
  signal bst_nmos_ctrl : std_logic := '0';                                -- OR-ed Boost NMOS pre-driver control
  signal bat_nmos_ctrl : std_logic := '0';                                -- OR-ed Battery NMOS pre-driver control
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

-- Check generic PCMP_LEN for valid value --------------------------------------
assert ((PROT_CMP_LEN > 0) and (PROT_CMP_LEN <= 7))
  report "Bit vector length of generic >PROT_CMP_LEN< specified incorrectly!"
  severity error;

--------------------------------------------------------------------------------
-- Selection NMOS pre-driver control
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Selection NMOS pre-driver control
proc_in_sel_nmos_ctrl:
sel_nmos_ctrl <= i_sel_nmos_ctrl;

-- Selection NMOS pre-driver protection set
proc_in_sel_prot_set:
sel_prot_set <= or_reduce(i_prot_cmp and i_prot_msk);

-- Selection NMOS pre-driver protection clear
proc_in_sel_prot_clr:
sel_prot_clr <= '1' when ((i_prot_clr = '1') and (sel_prot_set = '0'))
           else '0';

-- Component instantiation -----------------------------------------------------
nmos_ls_pdrv_sel_unit: nmos_pdrv_ctrl
  generic map (
    CUR_LEN    => NMOS_CUR_LEN,
    TSOFF_LEN  => NMOS_TSOFF_LEN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys      => i_sys,
    i_ctrl     => sel_nmos_ctrl,
    i_diag     => i_diag_nmos_ctrl,
    i_prot_set => sel_prot_set,
    i_prot_clr => sel_prot_clr,
    i_cur      => i_sel_nmos_cur,
    i_tsoff    => i_sel_nmos_tsoff,
    -- Output ports ------------------------------------------------------------
    o_ctrl     => o_sel_nmos_ctrl,
    o_soff     => o_sel_nmos_soff,
    o_cur      => o_sel_nmos_cur
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- NMOS pre-driver protection control
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Boost NMOS pre-driver selection based on protection mask
proc_in_bst_nmos_ctrl:
bst_nmos_ctrl <= or_reduce((i_bst_nmos_ctrl & C_NMOS_LS_PDRV_NMOS_CTRL_PADDING) and i_prot_msk);

-- Battery NMOS pre-driver selection based on protection mask
proc_in_bat_nmos_ctrl:
bat_nmos_ctrl <= or_reduce((i_bat_nmos_ctrl & C_NMOS_LS_PDRV_NMOS_CTRL_PADDING) and i_prot_msk);

-- Component instantiation -----------------------------------------------------
nmos_ls_prdrv_prot_unit: nmos_prot_ctrl
  generic map (
    CUR_LEN         => PROT_CUR_LEN,
    TSLP_LEN        => PROT_TSLP_LEN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys           => i_sys,
    i_bst_ctrl      => bst_nmos_ctrl,
    i_bat_ctrl      => bat_nmos_ctrl,
    i_diag_prot_ena => i_diag_prot_ena,
    i_bst_cur       => i_bst_prot_cur,
    i_bst_tslp      => i_bst_prot_tslp,
    i_bat_cur       => i_bat_prot_cur,
    i_bat_tslp      => i_bat_prot_tslp,
    i_diag_cur      => i_diag_prot_cur,
    -- Output ports ------------------------------------------------------------
    o_cur           => o_prot_cur
  );

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;