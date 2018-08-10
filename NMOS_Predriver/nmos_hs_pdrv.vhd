--------------------------------------------------------------------------------
-- File: nmos_hs_pdrv.vhd
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
entity nmos_hs_pdrv is
  generic (
    NMOS_CUR_LEN     : natural := 3;                                      -- NMOS charge/discharge current selection length (in bits)
    NMOS_TSOFF_LEN   : natural := 16;                                     -- NMOS strong-OFF timer register length (in bits)
    PROT_CUR_LEN     : natural := 8;                                      -- Protection current selection register length (in bits)
    PROT_TSLP_LEN    : natural := 16;                                     -- Protection slope timer register length (in bits)
    PROT_CMP_LEN     : natural := 7                                       -- Protection comparator register length (in bits)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys            : in  sys_ctrl_t;                                    -- System control
    i_nmos_ctrl_bst  : in  std_logic;                                     -- Boost NMOS pre-driver control
    i_nmos_ctrl_bat  : in  std_logic;                                     -- Battery NMOS pre-driver control
    i_nmos_cur_bst   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Boost NMOS charge/discharge current selection
    i_nmos_tsoff_bst : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);   -- Boost NMOS strong-OFF timer/counter value
    i_nmos_cur_bat   : in  std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Battery NMOS charge/discharge current selection
    i_nmos_tsoff_bat : in  std_logic_vector(NMOS_TSOFF_LEN-1 downto 0);   -- Battery NMOS strong-OFF timer/counter value
    i_diag_ctrl      : in  std_logic;                                     -- Diagnostics control
    i_diag_prot_ena  : in  std_logic;                                     -- Diagnostics protection enable
    i_prot_cur_bst   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Boost NMOS protection current
    i_prot_tslp_bst  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);    -- Boost NMOS slope timer/counter value
    i_prot_cur_bat   : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Battery NMOS protection current
    i_prot_tslp_bat  : in  std_logic_vector(PROT_TSLP_LEN-1 downto 0);    -- Battery NMOS slope timer/counter value
    i_prot_cur_diag  : in  std_logic_vector(PROT_CUR_LEN-1 downto 0);     -- Diagnostics protection current
    i_prot_cmp       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);     -- Protection comparator inputs (from all possible instances)
    i_prot_msk       : in  std_logic_vector(PROT_CMP_LEN-1 downto 0);     -- Protection comparator masks (cross-links between pre-drivers, topology dependent)
    i_prot_clr       : in  std_logic;                                     -- Protection register clear
    -- Output ports ------------------------------------------------------------
    o_nmos_ctrl_bst  : out std_logic;                                     -- Boost NMOS pre-driver control
    o_nmos_soff_bst  : out std_logic;                                     -- Boost NMOS strong-OFF control
    o_nmos_cur_bst   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Boost NMOS charge/discharge current
    o_nmos_ctrl_bat  : out std_logic;                                     -- Battery NMOS pre-driver control
    o_nmos_soff_bat  : out std_logic;                                     -- Battery NMOS strong-OFF control
    o_nmos_cur_bat   : out std_logic_vector(NMOS_CUR_LEN-1 downto 0);     -- Battery NMOS charge/discharge control
    o_prot_cur       : out std_logic_vector(PROT_CUR_LEN-1 downto 0)      -- Protection comparator current threshold
  );
end entity nmos_hs_pdrv;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of nmos_hs_pdrv is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal prot_set_bst : std_logic                                 := '0';               -- Boost NMOS protection set
  signal prot_clr_bst : std_logic                                 := '1';               -- Boost NMOS protection clear
  signal prot_msk_bst : std_logic_vector(PROT_CMP_LEN-1 downto 0) := (others => '0');   -- Masked Boost NMOS protection compare
  signal prot_set_bat : std_logic                                 := '0';               -- Battery NMOS protection set
  signal prot_clr_bat : std_logic                                 := '1';               -- Battery NMOS protection clear
  signal prot_msk_bat : std_logic_vector(PROT_CMP_LEN-1 downto 0) := (others => '0');   -- Masked Battery NMOS protection compare
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
-- Boost NMOS pre-driver control
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Masked pre-driver NMOS Boost compare
proc_in_prot_msk_bst:
prot_msk_bst <= i_prot_cmp and i_prot_msk;

-- Pre-driver NMOS Boost protection set
proc_in_prot_set_bst:
prot_set_bst <= or_reduce(prot_msk_bst);

-- Pre-driver NMOS Boost protection clear
proc_in_prot_clr_bst:
prot_clr_bst <= '1' when ((i_prot_clr = '1') and (prot_set_bst = '0'))
           else '0';

-- Component instantiation -----------------------------------------------------
nmos_hs_pdrv_bst_unit: nmos_pdrv_ctrl
  generic map (
    CUR_LEN    => NMOS_CUR_LEN,
    TSOFF_LEN  => NMOS_TSOFF_LEN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys      => i_sys,
    i_ctrl     => i_nmos_ctrl_bst,
    i_diag     => i_diag_ctrl,
    i_prot_set => prot_set_bst,
    i_prot_clr => prot_clr_bst,
    i_cur      => i_nmos_cur_bst,
    i_tsoff    => i_nmos_tsoff_bst,
    -- Output ports ------------------------------------------------------------
    o_ctrl     => o_nmos_ctrl_bst,
    o_soff     => o_nmos_soff_bst,
    o_cur      => o_nmos_cur_bst
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Battery NMOS pre-driver control
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Masked pre-driver NMOS Battery compare
proc_in_prot_msk_bat:
prot_msk_bat <= i_prot_cmp and i_prot_msk;

-- Pre-driver NMOS Battery protection set
proc_in_prot_set_bat:
prot_set_bat <= or_reduce(prot_msk_bat);

-- Pre-driver NMOS Battery protection clear
proc_in_prot_clr_bat:
prot_clr_bat <= '1' when ((i_prot_clr = '1') and (prot_set_bat = '0'))
           else '0';

-- Component instantiation -----------------------------------------------------
nmos_hs_pdrv_bat_unit: nmos_pdrv_ctrl
  generic map (
    CUR_LEN    => NMOS_CUR_LEN,
    TSOFF_LEN  => NMOS_TSOFF_LEN
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys      => i_sys,
    i_ctrl     => i_nmos_ctrl_bat,
    i_diag     => i_diag_ctrl,
    i_prot_set => prot_set_bat,
    i_prot_clr => prot_clr_bat,
    i_cur      => i_nmos_cur_bat,
    i_tsoff    => i_nmos_tsoff_bat,
    -- Output ports ------------------------------------------------------------
    o_ctrl     => o_nmos_ctrl_bat,
    o_soff     => o_nmos_soff_bat,
    o_cur      => o_nmos_cur_bat
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- NMOS pre-driver protection control
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
nmos_hs_prdrv_prot_unit: nmos_prot_ctrl
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