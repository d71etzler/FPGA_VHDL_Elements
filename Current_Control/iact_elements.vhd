--------------------------------------------------------------------------------
-- File: iact_elements.vhd
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
library math;
  use math.math_functions.all;

--------------------------------------------------------------------------------
-- Package declarations
--------------------------------------------------------------------------------
package iact_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------

-- Comparator states -----------------------------------------------------------
type cmp_states_t is (
  BELOW_MIN_S,        -- Input signal below minimum limit
  BETWEEN_LIMITS_S,   -- Input signal between minimum and maximum limit
  ABOVE_MAX_S,        -- Input signal above maximum limit
  INVALID_S           -- Invalid input signal
);

-- Control core states ---------------------------------------------------------
type core_states_t is (
  CLEAR_OUTPUT_CLEAR_TIME_S,  -- Clear control output and clear timer
  SET_OUTPUT_CLEAR_TIME_S,    -- Set control output and clear timer
  KEEP_OUTPUT_CLEAR_TIME_S,   -- Do not change output and clear timer
  KEEP_OUTPUT_KEEP_TIME_S,    -- Do not change output and do not clear timer
  INVALID_S                   -- Invalid selection
);

-- Control output structure ----------------------------------------------------
type iact_ctrl_t is record
  level : std_logic;  -- Control level
  error : std_logic;  -- Control error
end record iact_ctrl_t;

--------------------------------------------------------------------------------
-- Function declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- Current control sequencer ---------------------------------------------------
component iact_ctrl_seq is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;
    i_clr        : in  std_logic;
    i_set        : in  std_logic;
    i_isns_state : in  cmp_states_t;
    i_ton_state  : in  cmp_states_t;
    i_toff_state : in  cmp_states_t;
    -- Output ports ------------------------------------------------------------
    o_ctrl       : out iact_ctrl_t
  );
end component iact_ctrl_seq;

-- Current control core --------------------------------------------------------
component iact_ctrl_core is
  generic (
    ISET_DATA_LEN      : positive;
    TSET_DATA_LEN      : positive
  );
  port (
    -- Output ports ------------------------------------------------------------
    o_ctrl             : out iact_ctrl_t;
    o_iset_buf_min     : out std_logic_vector(ISET_DATA_LEN-1 downto 0);
    o_iset_buf_max     : out std_logic_vector(ISET_DATA_LEN-1 downto 0);
    -- Input ports -------------------------------------------------------------
    i_sys              : in  sys_ctrl_t;
    i_tck              : in  std_logic;
    i_ctrl_core_load_s : in  std_logic;
    i_ctrl_core        : in  core_states_t;
    i_iset_min         : in  std_logic_vector(ISET_DATA_LEN-1 downto 0);
    i_iset_max         : in  std_logic_vector(ISET_DATA_LEN-1 downto 0);
    i_isns_min         : in  std_logic;
    i_isns_max         : in  std_logic;
    i_tset_on_min      : in  std_logic_vector(TSET_DATA_LEN-1 downto 0);
    i_tset_on_max      : in  std_logic_vector(TSET_DATA_LEN-1 downto 0);
    i_tset_off_min     : in  std_logic_vector(TSET_DATA_LEN-1 downto 0);
    i_tset_off_max     : in  std_logic_vector(TSET_DATA_LEN-1 downto 0)
  );
end component iact_ctrl_core;

end package iact_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body iact_elements is
end package body iact_elements;