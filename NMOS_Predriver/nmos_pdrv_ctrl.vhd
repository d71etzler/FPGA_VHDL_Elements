--------------------------------------------------------------------------------
-- File: nmos_pdrv_ctrl.vhd
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

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity nmos_pdrv_ctrl is
  generic (
    CUR_LEN    : natural := 3;                                -- NMOS charge/discharge current selection length (in bits)
    TSOFF_LEN  : natural := 16                                -- Strong OFF-path register length (in bits)
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys      : in  sys_ctrl_t;                              -- System control
    i_ctrl     : in  std_logic;                               -- Pre-driver control
    i_diag     : in  std_logic;                               -- Diagnostics control
    i_prot_set : in  std_logic;                               -- Protection disable set
    i_prot_clr : in  std_logic;                               -- Protection disable clear
    i_cur      : in  std_logic_vector(CUR_LEN-1 downto 0);    -- NMOS charge/discharge current selection
    i_tsoff    : in  std_logic_vector(TSOFF_LEN-1 downto 0);  -- Strong OFF-path delay compare value
    -- Output ports ------------------------------------------------------------
    o_ctrl     : out std_logic;                               -- NMOS switch control
    o_soff     : out std_logic;                               -- Strong OFF-path control
    o_cur      : out std_logic_vector(CUR_LEN-1 downto 0)     -- NMOS charge/discharge current selection
  );
end entity nmos_pdrv_ctrl;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of nmos_pdrv_ctrl is
  -- Constants -----------------------------------------------------------------
  constant C_NMOS_PDRV_CTRL_PROT_EVENT_BUF_INIT      : std_logic := '0';                                                                          -- Protection event buffer initial value
  constant C_NMOS_PDRV_CTRL_TSOFF_COUNT_MODULO_PLUS1 : natural   := (2**TSOFF_LEN);                                                               -- Strong OFF-path delay counter modulo value (due to counter implementation Modulo+1)
  constant C_NMOS_PDRV_CTRL_TSOFF_COUNT_INIT         : natural   := 0;                                                                            -- Strong OFF-path delay counter initial value
  constant C_NMOS_PDRV_CTRL_CUR_SEL_LIM              : natural   := 4;                                                                            -- NMOS current selection limit (4 x limited current options plus 1 x unlimited currents)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal prot_event_buf  : std_logic                              := '0';                                                                         -- Protection event buffer
  signal tsoff_count_clr : std_logic                              := '1';                                                                         -- Strong OFF-path delay counter clear
  signal tsoff_count_tck : std_logic                              := '0';                                                                         -- Strong OFF-path delay counter tick
  signal tsoff_count_cnt : std_logic_vector(TSOFF_LEN-1 downto 0) := std_logic_vector(to_unsigned(C_NMOS_PDRV_CTRL_TSOFF_COUNT_INIT,TSOFF_LEN));  -- Strong OFF-path delay counter value
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------

-- Check generic CUR_LEN for valid value ---------------------------------------
assert ((CUR_LEN > 0) and (CUR_LEN <= 3))
  report "Bit vector length of generic >CUR_LEN< specified incorrectly!"
  severity error;

-- Check generic TSOFF_LEN for valid value -------------------------------------
assert ((TSOFF_LEN > 0) and (TSOFF_LEN <= 16))
  report "Bit vector length of generic >TSOFF_LEN< specified incorrectly!"
  severity error;

-- Check concurrent activation of "i_prot_set" and "i_prot_clr" ----------------
assert ((i_prot_set = '0') or (i_prot_clr = '0'))
  report "Concurrent assertion of protection event inputs >i_prot_set< and " &
         ">i_prot_clr< at simulation time t = " & time'image(now) & " detected."
  severity note;

--------------------------------------------------------------------------------
-- Protection event buffer
-- Store a protection event until cleared explicitely.
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
nmos_pdrv_prot_event_unit: buffer_bit
  generic map (
    INIT  => C_NMOS_PDRV_CTRL_PROT_EVENT_BUF_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => i_prot_clr,
    i_set => i_prot_set,
    i_bit => '1',
    -- Output ports ------------------------------------------------------------
    o_bit => prot_event_buf
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Strong OFF-path delay counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Strong OFF-path delay counter clear
proc_in_tsoff_count_clr:
tsoff_count_clr <= '1' when (i_ctrl = '1')
              else '0';

-- Strong OFF-path delay counter tick
proc_in_tsoff_count_tck:
tsoff_count_tck <= '1' when ((i_ctrl = '0') and (tsoff_count_cnt < i_tsoff))
              else '0';

-- Component instantiation -----------------------------------------------------
nmos_pdrv_tsoff_count_unit: count_mod_m
  generic map (
    M     => C_NMOS_PDRV_CTRL_TSOFF_COUNT_MODULO_PLUS1,
    INIT  => C_NMOS_PDRV_CTRL_TSOFF_COUNT_INIT,
    DIR   => UP
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => tsoff_count_clr,
    i_tck => tsoff_count_tck,
    -- Output ports ------------------------------------------------------------
    o_cnt => tsoff_count_cnt
  );

-- Output logic ----------------------------------------------------------------

-- NMOS charge/discharge current selection
proc_out_o_cur:
o_cur <= i_cur when (unsigned(i_cur) <= to_unsigned(C_NMOS_PDRV_CTRL_CUR_SEL_LIM, CUR_LEN))
    else std_logic_vector(to_unsigned(C_NMOS_PDRV_CTRL_CUR_SEL_LIM, CUR_LEN));

-- NMOS control
proc_out_o_ctrl:
o_ctrl <= i_ctrl when ((prot_event_buf = '0') and (i_diag = '0'))
     else '1'    when (i_diag = '1')
     else '0';

-- Strong OFF-path
-- Additional 'and' of tsoff_count_clr in first branch is necessary for correct
-- operation for a set point of i_tsoff = 0.
proc_out_o_soff:
o_soff <= '1' when ((tsoff_count_cnt >= i_tsoff) and (tsoff_count_clr = '0') and (i_diag = '0'))
     else '1' when ((prot_event_buf = '1') and (i_diag = '0'))
     else '0';

end architecture structural;