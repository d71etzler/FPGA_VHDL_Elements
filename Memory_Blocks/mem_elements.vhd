--------------------------------------------------------------------------------
-- File: mem_elements.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-05-12 #$: Date of last commit
-- $Rev:: 45           $: Revision of last commit
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
  use math.math_functions.all;

--------------------------------------------------------------------------------
-- Package declarations
--------------------------------------------------------------------------------
package mem_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------

-- Register operation type -----------------------------------------------------
type reg_op_t is (
  WR_NO_CHANGE_RD_NO_CHANGE,  -- No change during write; no change during read
  WR_SET_DATA_RD_NO_CHANGE,   -- Set data during write; no change during read
  WR_SET_DATA_RD_CLEAR_DATA,  -- Set data during write; clear data during read
  WR_OR_DATA_RD_NO_CHANGE,    -- OR new data during write; no change during read
  WR_OR_DATA_RD_CLEAR_DATA,   -- OR new data during write; clear data during read
  WR_XOR_DATA_RD_NO_CHANGE,   -- XOR new data during write; no change during read
  WR_XOR_DATA_RD_CLEAR_DATA,  -- XOR new data during write; clear data during read
  WR_AND_DATA_RD_NO_CHANGE,   -- AND new data during write; no change during read
  WR_AND_DATA_RD_CLEAR_DATA   -- AND new data during write; clear data during read
);

--------------------------------------------------------------------------------
-- Function declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- Register line ---------------------------------------------------------------
component reg_line is
  generic (
    REG_WIDTH : natural;
    REG_INIT  : std_logic_vector;
    REG_OPC   : reg_op_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys     : in  sys_ctrl_t;
    i_ena     : in  std_logic;
    i_wr      : in  std_logic;
    i_accs_s  : in  std_logic;
    i_data    : in  std_logic_vector(REG_WIDTH-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_data    : out std_logic_vector(REG_WIDTH-1 downto 0)
  );
end component reg_line;

-- ROM block -------------------------------------------------------------------
component rom_block is
  generic (
    ROM_DEPTH : natural;
    ROM_WIDTH : natural;
    OBUF_INIT : std_logic_vector;
    FILE_INIT : string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys     : in  sys_ctrl_t;
    i_ena     : in  std_logic;
    i_addr    : in  std_logic_vector(clogb2(ROM_DEPTH)-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_data    : out std_logic_vector(ROM_WIDTH-1 downto 0)
 );
end component rom_block;

end package mem_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body mem_elements is
end package body mem_elements;