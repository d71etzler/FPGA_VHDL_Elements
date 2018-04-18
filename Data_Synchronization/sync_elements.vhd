--------------------------------------------------------------------------------
-- File: sync_elements.vhd
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
-- Package declarations
--------------------------------------------------------------------------------
package sync_elements is

--------------------------------------------------------------------------------
-- User constant declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- Asynchronous external input signal synchronization --------------------------
component sync_bit is
  generic (
    GUARD_LEN : positive;
    SYNC_INIT : std_logic
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst     : in  std_logic;
    i_clk     : in  std_logic;
    i_bit_a   : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_bit     : out std_logic
  );
end component sync_bit;

end package sync_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body sync_elements is
end package body sync_elements;