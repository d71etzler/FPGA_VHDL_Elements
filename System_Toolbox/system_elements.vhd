--------------------------------------------------------------------------------
-- File: system_elements.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-23 #$: Date of last commit
-- $Rev:: 13           $: Revision of last commit
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
package system_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Function declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- System heartbeat ------------------------------------------------------------
component heart_beat is
  generic (
    SYS_CLK_FREQ : real;
    HRT_BEAT_PER : real
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;
    -- Output ports ------------------------------------------------------------
    o_hrbt       : out std_logic
  );
end component heart_beat;

end package system_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body system_elements is
end package body system_elements;