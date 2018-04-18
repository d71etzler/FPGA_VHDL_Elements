--------------------------------------------------------------------------------
-- File: iact_ctrl_core.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-09 #$: Date of last commit
-- $Rev:: 8            $: Revision of last commit
--
-- Open Points/Remarks:
--  + (none)
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Used library definitions
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--  use unisim.vcomponents.all;

library basic;
  use basic.basic_elements.all;
library iact;
  use iact.iact_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity iact_ctrl_core is
  generic (
    ISET_DATA_LEN      : positive := 8;                                   -- Current set point data length
    TSET_DATA_LEN      : positive := 16                                   -- On-time/Off-time set point data length
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys              : in  sys_ctrl_t;                                  -- System control
    i_tck              : in  std_logic;                                   -- Clock tick
    i_ctrl_core_load_s : in  std_logic;                                   -- Control core state load (one clock cycle pulse)
    i_ctrl_core        : in  core_states_t;                               -- Control core state
    i_iset_min         : in  std_logic_vector(ISET_DATA_LEN-1 downto 0);  -- Minimum current set point
    i_iset_max         : in  std_logic_vector(ISET_DATA_LEN-1 downto 0);  -- Maximum current set point
    i_isns_min         : in  std_logic;                                   -- Minimum current comparator signal
    i_isns_max         : in  std_logic;                                   -- Maximum current comparator signal
    i_tset_on_min      : in  std_logic_vector(TSET_DATA_LEN-1 downto 0);  -- Minimum On-time set point
    i_tset_on_max      : in  std_logic_vector(TSET_DATA_LEN-1 downto 0);  -- Maximum On-time set point
    i_tset_off_min     : in  std_logic_vector(TSET_DATA_LEN-1 downto 0);  -- Minimum Off-time set point
    i_tset_off_max     : in  std_logic_vector(TSET_DATA_LEN-1 downto 0);  -- Maximum Off-time set point
    -- Output ports ------------------------------------------------------------
    o_ctrl             : out iact_ctrl_t;                                 -- Current control
    o_iset_buf_min     : out std_logic_vector(ISET_DATA_LEN-1 downto 0);  -- Buffered minimum current set point
    o_iset_buf_max     : out std_logic_vector(ISET_DATA_LEN-1 downto 0)   -- Buffered maximum current set point
  );
end entity iact_ctrl_core;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of iact_ctrl_core is

  -- Constants -----------------------------------------------------------------
  constant C_IACT_CTRL_CORE_ISET_BUF_LEN  : positive                                   := ISET_DATA_LEN;
  constant C_IACT_CTRL_CORE_ISET_BUF_INIT : std_logic_vector(ISET_DATA_LEN-1 downto 0) := (others => '0');
  constant C_IACT_CTRL_CORE_ISET_BUF_CLR  : std_logic                                  := '0';
  constant C_IACT_CTRL_CORE_TSET_BUF_LEN  : positive                                   := TSET_DATA_LEN;
  constant C_IACT_CTRL_CORE_TSET_BUF_INIT : std_logic_vector(TSET_DATA_LEN-1 downto 0) := (others => '0');
  constant C_IACT_CTRL_CORE_TSET_BUF_CLR  : std_logic                                  := '0';
  constant C_IACT_CTRL_CORE_TSET_CNT_LEN  : positive                                   := TSET_DATA_LEN;
  constant C_IACT_CTRL_CORE_TSET_CNT_INIT : natural                                    := 0;
  constant C_IACT_CTRL_CORE_TSET_CNT_DIR  : cnt_dir_t                                  := UP;
  -- Types ---------------------------------------------------------------------
    -- Enumerated current limits
    type iset_lim_t is (MIN_E, MAX_E);
    --  Minimum/maximum current limit structure
    type iset_array_t is array(iset_lim_t) of std_logic_vector(ISET_DATA_LEN-1 downto 0);
    -- Enumerated time limits
    type tset_lim_t is (ON_MIN_E, ON_MAX_E, OFF_MIN_E, OFF_MAX_E);
    -- Minimum/maxium On-time/Off-time limit structure
    type tset_array_t is array(tset_lim_t) of std_logic_vector(TSET_DATA_LEN-1 downto 0);
    -- Enumerated time counters
    type tcnt_t is (ON_CNT_E, OFF_CNT_E);
    -- On-time/Off-time counter clear structure
    type tcnt_clr_array_t is array(tcnt_t) of std_logic;
    -- On-time/Off-time counter value (count) structure
    type tcnt_cnt_array_t is array(tcnt_t) of std_logic_vector(TSET_DATA_LEN-1 downto 0);
  -- Aliases -------------------------------------------------------------------
  --(none)
  -- Signals -------------------------------------------------------------------
  signal iset_ubuf      : iset_array_t := (others => C_IACT_CTRL_CORE_ISET_BUF_INIT);
  signal iset_buf       : iset_array_t := (others => C_IACT_CTRL_CORE_ISET_BUF_INIT);
  signal tset_ubuf      : tset_array_t := (others => C_IACT_CTRL_CORE_TSET_BUF_INIT);
  signal tset_buf       : tset_array_t := (others => C_IACT_CTRL_CORE_TSET_BUF_INIT);
  signal isns_state     : cmp_states_t     := INVALID_S;
  signal tcnt_state_on  : cmp_states_t     := INVALID_S;
  signal tcnt_state_off : cmp_states_t     := INVALID_S;
  signal tcnt_clr       : tcnt_clr_array_t := (others => '1');
  signal tcnt_cnt       : tcnt_cnt_array_t := (others => C_IACT_CTRL_CORE_TSET_BUF_INIT);
  signal ctrl_clr       : std_logic        := '1';
  signal ctrl_set       : std_logic        := '0';
  signal ctrl           : iact_ctrl_t      := (others => '0');
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

--------------------------------------------------------------------------------
-- Current set point buffers
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Unbuffered minimum current set point
proc_in_iset_ubuf_min:
iset_ubuf(MIN_E) <= i_iset_min;

-- Unbuffered maximum current set point
proc_in_iset_ubuf_max:
iset_ubuf(MAX_E) <= i_iset_max;

-- Component instantiation -----------------------------------------------------
gen_iact_ctrl_core_iact_buf: for i in iset_lim_t generate
  iact_ctrl_core_iact_buf: buffer_bvec
  generic map (
    LEN    => C_IACT_CTRL_CORE_ISET_BUF_LEN,
    INIT   => C_IACT_CTRL_CORE_ISET_BUF_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys  => i_sys,
    i_clr  => C_IACT_CTRL_CORE_ISET_BUF_CLR,
    i_set  => i_ctrl_core_load_s,
    i_bvec => iset_ubuf(i),
    -- Output ports ------------------------------------------------------------
    o_bvec => iset_buf(i)
  );
end generate;

-- Output logic ----------------------------------------------------------------

-- Buffered minimum current set point
proc_out_o_iset_buf_min:
o_iset_buf_min <= iset_buf(MIN_E);

-- Buffered maximum current set point
proc_out_o_iset_buf_max:
o_iset_buf_max <= iset_buf(MAX_E);

--------------------------------------------------------------------------------
-- On-time/Off-time set point buffers
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Unbuffered minimum On-time set point
proc_in_tset_ubuf_on_min:
tset_ubuf(ON_MIN_E) <= i_tset_on_min;

-- Unbuffered maximum On-time set point
proc_in_tset_ubuf_on_max:
tset_ubuf(ON_MAX_E) <= i_tset_off_min;

-- Unbuffered minimum Off-time set point
proc_in_tset_ubuf_off_min:
tset_ubuf(OFF_MIN_E) <= i_tset_off_min;

-- Unbuffered maximum Off-time set point
proc_in_tset_ubuf_off_max:
tset_ubuf(OFF_MAX_E) <= i_tset_off_max;

-- Component instantiation -----------------------------------------------------
gen_iact_ctrl_core_tact_buf: for i in tset_lim_t generate
  iact_ctrl_core_tact_buf: buffer_bvec
  generic map (
    LEN    => C_IACT_CTRL_CORE_TSET_BUF_LEN,
    INIT   => C_IACT_CTRL_CORE_TSET_BUF_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys  => i_sys,
    i_clr  => C_IACT_CTRL_CORE_TSET_BUF_CLR,
    i_set  => i_ctrl_core_load_s,
    i_bvec => tset_ubuf(i),
    -- Output ports ------------------------------------------------------------
    o_bvec => tset_buf(i)
  );
end generate;

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- NMOS On-time counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
proc_in_tcnt_clr_on :
tcnt_clr(ON_CNT_E) <= '1' when (ctrl.level = '0')
                 else '1' when (i_ctrl_core_load_s = '1') and (i_ctrl_core = KEEP_OUTPUT_CLEAR_TIME_S)
                 else '1' when (i_ctrl_core_load_s = '1') and (i_ctrl_core = INVALID_S)
                 else '0';

proc_in_tcnt_clr_off :
tcnt_clr(OFF_CNT_E) <= '1' when (ctrl.level = '1')
                  else '1' when (i_ctrl_core_load_s = '1') and (i_ctrl_core = KEEP_OUTPUT_CLEAR_TIME_S)
                  else '1' when (i_ctrl_core_load_s = '1') and (i_ctrl_core = INVALID_S)
                  else '0';

-- Component instantiation -----------------------------------------------------
gen_iact_ctrl_core_tcnt_cnt: for i in tcnt_t generate
  iact_ctrl_core_tcnt_cnt_mod_m: count_mod_m
  generic map (
    M     => (2**C_IACT_CTRL_CORE_TSET_CNT_LEN)-1,
    INIT  => C_IACT_CTRL_CORE_TSET_CNT_INIT,
    DIR   => C_IACT_CTRL_CORE_TSET_CNT_DIR
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => tcnt_clr(i),
    i_tck => i_tck,
    -- Output ports ------------------------------------------------------------
    o_cnt => tcnt_cnt(i)
  );
end generate;

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Current control sequencer
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- TODO:: To be cross-checked whether asserting ctrl_clr with invalid core state
-- is necessary.  The current control sequencer outputs are set based on the
-- invalid comparator states already (redundant assertion).
proc_in_ctrl_clr:
ctrl_clr <= '1' when (i_ctrl_core_load_s = '1') and (i_ctrl_core = CLEAR_OUTPUT_CLEAR_TIME_S)
       else '1' when (i_ctrl_core_load_s = '1') and (i_ctrl_core = INVALID_S)
       else '0';

proc_in_ctrl_set:
ctrl_set <= '1' when (i_ctrl_core_load_s = '1') and (i_ctrl_core = SET_OUTPUT_CLEAR_TIME_S)
       else '0';

-- An invalid core state (e.g. INVALID_S) sets the current comparator state to
-- invalid; thus, forcing the current control sequencer to assert the control
-- error.
proc_in_isns_state:
isns_state <= BELOW_MIN_S      when (i_isns_min = '0') and (i_isns_max = '0') and (i_ctrl_core /= INVALID_S)
             else BETWEEN_LIMITS_S when (i_isns_min = '1') and (i_isns_max = '0') and (i_ctrl_core /= INVALID_S)
             else ABOVE_MAX_S      when (i_isns_min = '1') and (i_isns_max = '1') and (i_ctrl_core /= INVALID_S)
             else INVALID_S;

-- An invalid core state (e.g. INVALID_S) sets the On-time-comparator state to
-- invalid; thus forcing the current control sequencer to assert the control
-- error.
proc_in_tcnt_state_on:
tcnt_state_on <=  BELOW_MIN_S      when (tcnt_cnt(ON_CNT_E) <  tset_buf(ON_MIN_E)) and (tcnt_cnt(ON_CNT_E) <  tset_buf(ON_MAX_E)) and (i_ctrl_core /= INVALID_S)
             else BETWEEN_LIMITS_S when (tcnt_cnt(ON_CNT_E) >= tset_buf(ON_MIN_E)) and (tcnt_cnt(ON_CNT_E) <  tset_buf(ON_MAX_E)) and (i_ctrl_core /= INVALID_S)
             else ABOVE_MAX_S      when (tcnt_cnt(ON_CNT_E) >= tset_buf(ON_MIN_E)) and (tcnt_cnt(ON_CNT_E) >= tset_buf(ON_MAX_E)) and (i_ctrl_core /= INVALID_S)
             else INVALID_S;

-- An invalid core state (e.g. INVALID_S) sets the Off-time-comparator state to
-- invalid; thus forcing the current control sequencer to assert the control
-- error.
proc_in_tcnt_state_off:
tcnt_state_off <= BELOW_MIN_S      when (tcnt_cnt(OFF_CNT_E) <  tset_buf(OFF_MIN_E)) and (tcnt_cnt(OFF_CNT_E) <  tset_buf(OFF_MAX_E)) and (i_ctrl_core /= INVALID_S)
             else BETWEEN_LIMITS_S when (tcnt_cnt(OFF_CNT_E) >= tset_buf(OFF_MIN_E)) and (tcnt_cnt(OFF_CNT_E) <  tset_buf(OFF_MAX_E)) and (i_ctrl_core /= INVALID_S)
             else ABOVE_MAX_S      when (tcnt_cnt(OFF_CNT_E) >= tset_buf(OFF_MIN_E)) and (tcnt_cnt(OFF_CNT_E) >= tset_buf(OFF_MAX_E)) and (i_ctrl_core /= INVALID_S)
             else INVALID_S;

-- Component instantiation -----------------------------------------------------
iact_ctrl_core_iact_ctrl_seq: iact_ctrl_seq
port map (
  -- Output ports --------------------------------------------------------------
  o_ctrl       => ctrl,
  -- Input ports ---------------------------------------------------------------
  i_sys        => i_sys,
  i_clr        => ctrl_clr,
  i_set        => ctrl_set,
  i_isns_state => isns_state,
  i_ton_state  => tcnt_state_on,
  i_toff_state => tcnt_state_off
);

-- Output logic ----------------------------------------------------------------
proc_out_o_ctrl:
o_ctrl <= ctrl;

end architecture structural;