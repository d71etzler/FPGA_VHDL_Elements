--------------------------------------------------------------------------------
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-09 #$: Date of last commit
-- $Rev:: 8            $: Revision of last commit
--
-- Create Date    : 10/02/2015 12:10:20 PM
-- Design Name    : N/A
-- Module Name    : ictrl_wrapper - structural
-- Project Name   : SDI Current Control
-- Target Devices : xc7z10clg400-1
-- Tool Versions  : Vivado 2015.2 / VHDL-2002
-- Description    : This component wraps the current control element for use
--    in the top AXI4-Lite element.
--
-- Dependencies   : basic_defs package
--                  ictrl_defs package
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
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

library work;
  use work.basic_defs.all;
  use work.ictrl_defs.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity ictrl_wrapper is
  generic (
    ISET_DATA_WIDTH : positive := 8;  -- Current set point data width
    TSET_DATA_WIDTH : positive := 16  -- On-time/Off-time set point data width
  );
  port (
    -- Output ports ------------------------------------------------------------
    o_ctrl_level   : out std_logic;                                     -- Control output level
    o_ctrl_error   : out std_logic;                                     -- Control output error
    o_iset_buf_min : out std_logic_vector(ISET_DATA_WIDTH-1 downto 0);  -- Buffered minimum current set point
    o_iset_buf_max : out std_logic_vector(ISET_DATA_WIDTH-1 downto 0);  -- Buffered maximum current set point
    -- Input ports -------------------------------------------------------------
    i_ares_n       : in  std_logic;                                     -- Asynchronous reset (low-active)
    i_clock        : in  std_logic;                                     -- Clock
    i_tck          : in  std_logic;                                     -- Clock tick
    i_trans_1p     : in  std_logic;                                     -- Core state transition (1 clock cycle pulse) - TODO:: Include correct input port!
    i_trans_clr    : in  std_logic;                                     -- Transition MOS counter clear - TODO:: Include correct input port!
    i_trans_start  : in  std_logic_vector(1 downto 0);                  -- Transition MOS start state - TODO:: Include correct input port!
    i_iset_min     : in  std_logic_vector(ISET_DATA_WIDTH-1 downto 0);  -- Minimum current set point
    i_iset_max     : in  std_logic_vector(ISET_DATA_WIDTH-1 downto 0);  -- Maximum current set point
    i_isns_min     : in  std_logic;                                     -- Minimum current comparator signal
    i_isns_max     : in  std_logic;                                     -- Maximum current comparator signal
    i_tset_on_min  : in  std_logic_vector(TSET_DATA_WIDTH-1 downto 0);  -- Minimum On-time set point
    i_tset_on_max  : in  std_logic_vector(TSET_DATA_WIDTH-1 downto 0);  -- Maximum On-time set point
    i_tset_off_min : in  std_logic_vector(TSET_DATA_WIDTH-1 downto 0);  -- Minimum Off-time set point
    i_tset_off_max : in  std_logic_vector(TSET_DATA_WIDTH-1 downto 0)   -- Maximum Off-time set point
  );
end entity ictrl_wrapper;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of ictrl_wrapper is

-- Attributes ------------------------------------------------------------------
attribute keep_hierarchy : string;
attribute keep_hierarchy of structural : architecture is "YES";

-- Constants -------------------------------------------------------------------
-- (none)
-- Types -----------------------------------------------------------------------
-- (none)
-- Signals ---------------------------------------------------------------------
signal ctrl       : ictrl_t       := (level => '0', error => '0');
signal core_state : core_states_t := INVALID_S;
-- Aliases ---------------------------------------------------------------------
-- (none)

begin

--------------------------------------------------------------------------------
-- Current control core
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Core state ------------------------------------------------------------------
-- This translates the separated NMOS start state and the timer clear into
-- enumerated core states.  All invalid combinations of both input variables
-- will be mapped to an invalid core state INVALID_S.
proc_input_core_state :
core_state <= CLEAR_OUTPUT_CLEAR_TIME_S when  ((i_trans_start = b"00") and (i_trans_clr = '1'))
         else SET_OUTPUT_CLEAR_TIME_S   when  ((i_trans_start = b"01") and (i_trans_clr = '1'))
         else KEEP_OUTPUT_CLEAR_TIME_S  when (((i_trans_start = b"10") or  (i_trans_start = b"11")) and (i_trans_clr = '1'))
         else KEEP_OUTPUT_KEEP_TIME_S   when (((i_trans_start = b"10") or  (i_trans_start = b"11")) and (i_trans_clr = '0'))
         else INVALID_S;

-- Component instantiation -----------------------------------------------------
ictrl_core_inst0 :
ictrl_core
generic map (
  ISET_DATA_WIDTH => ISET_DATA_WIDTH,
  TSET_DATA_WIDTH => TSET_DATA_WIDTH
)
port map (
  -- Output ports --------------------------------------------------------------
  o_ctrl         => ctrl,
  o_iset_buf_min => o_iset_buf_min,
  o_iset_buf_max => o_iset_buf_max,
  -- Input ports ---------------------------------------------------------------
  i_ares_n       => i_ares_n,
  i_clock        => i_clock,
  i_tck          => i_tck,
  i_trans_1p     => i_trans_1p,
  i_core_state   => core_state,
  i_iset_min     => i_iset_min,
  i_iset_max     => i_iset_max,
  i_isns_min     => i_isns_min,
  i_isns_max     => i_isns_max,
  i_tset_on_min  => i_tset_on_min,
  i_tset_on_max  => i_tset_on_max,
  i_tset_off_min => i_tset_off_min,
  i_tset_off_max => i_tset_off_max
);

-- Output logic ----------------------------------------------------------------

-- Control output level --------------------------------------------------------
proc_output_o_ctrl_level :
o_ctrl_level <= ctrl.level;

-- Control output error --------------------------------------------------------
proc_output_o_ctrl_error :
o_ctrl_error <= ctrl.error;

end architecture structural;