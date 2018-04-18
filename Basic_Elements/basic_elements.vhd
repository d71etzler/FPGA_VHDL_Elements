--------------------------------------------------------------------------------
-- File: basic_elements.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-03-23 #$: Date of last commit
-- $Rev:: 39           $: Revision of last commit
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
library math;
  use math.math_functions.all;

--------------------------------------------------------------------------------
-- Package declarations
--------------------------------------------------------------------------------
package basic_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------

-- Enumerated counter direction ------------------------------------------------
type cnt_dir_t is (
  UP,   -- Upwards counting
  DOWN  -- Downwards counting
);

-- Enumerated signal edge direction --------------------------------------------
type edge_dir_t is (
  RISE,   -- Rising edge
  FALL    -- Falling edge
);

-- Array of rise and fall edges ------------------------------------------------
type signal_edge_t is array(edge_dir_t) of std_logic;

-- 2D array of standard logic bits ---------------------------------------------
type std_logic_array2d_t is array(natural range <>, natural range <>) of std_logic;

-- System control --------------------------------------------------------------
type sys_ctrl_t is record
  rst : std_logic;   -- System reset
  clk : std_logic;   -- System clock
  ena : std_logic;   -- System block enable
  clr : std_logic;   -- System block clear
end record sys_ctrl_t;

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- Arbiter (round-robin) -------------------------------------------------------
component arbit_rnd_rbn is
  generic (
    LEN     : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys   : in  sys_ctrl_t;
    i_ack   : in  std_logic;
    i_req   : in  std_logic_vector(LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_grant : out std_logic_vector(LEN-1 downto 0)
  );
end component arbit_rnd_rbn;

-- Buffer bit ------------------------------------------------------------------
component buffer_bit is
  generic (
    INIT  : std_logic
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;
    i_clr : in  std_logic;
    i_set : in  std_logic;
    i_bit : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_bit : out std_logic
  );
end component buffer_bit;

-- Buffer bit vector -----------------------------------------------------------
component buffer_bvec is
  generic (
    LEN    : positive;
    INIT   : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys  : in  sys_ctrl_t;
    i_clr  : in  std_logic;
    i_set  : in  std_logic;
    i_bvec : in  std_logic_vector(LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_bvec : out std_logic_vector(LEN-1 downto 0)
  );
end component buffer_bvec;

-- Delay single bit ------------------------------------------------------------
component delay_bit is
  generic (
    DELAY : natural;
    INIT  : std_logic
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;
    i_clr : in  std_logic;
    i_bit : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_bit : out std_logic
  );
end component delay_bit;

-- Delay bit vector ------------------------------------------------------------
component delay_bvec is
  generic (
    LEN    : positive;
    DELAY  : natural;
    INIT   : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys  : in  sys_ctrl_t;
    i_clr  : in  std_logic;
    i_bvec : in  std_logic_vector(LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_bvec : out std_logic_vector(LEN-1 downto 0)
  );
end component delay_bvec;

-- Signal edge detector --------------------------------------------------------
component detect_edge is
  generic (
    LEN    : natural;
    INIT   : std_logic_vector;
    DIR    : edge_dir_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys  : in  sys_ctrl_t;
    i_sdi  : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_edge : out std_logic
  );
end component detect_edge;

-- Modulo-m counter ------------------------------------------------------------
component count_mod_m is
  generic (
    M     : natural;
    INIT  : natural;
    DIR   : cnt_dir_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;
    i_clr : in  std_logic;
    i_tck : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_cnt : out std_logic_vector(clogb2(M)-1 downto 0)
  );
end component count_mod_m;

-- Modulo-m divider ------------------------------------------------------------
component divide_mod_m is
  generic (
    M     : natural;
    INIT  : natural;
    DIR   : cnt_dir_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;
    i_clr : in  std_logic;
    i_tck : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_div : out std_logic
  );
end component divide_mod_m;

-- Ring counter ----------------------------------------------------------------
component count_ring_n is
  generic (
    N     : natural;
    INIT  : std_logic_vector;
    DIR   : cnt_dir_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;
    i_clr : in  std_logic;
    i_tck : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_cnt : out std_logic_vector(N-1 downto 0)
  );
end component count_ring_n;

-- Pulse widening --------------------------------------------------------------
component widen_pulse is
  generic (
    LEN      : natural
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys    : in  sys_ctrl_t;
    i_clr    : in  std_logic;
    i_pls_s  : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_pls_xs : out std_logic
  );
end component widen_pulse;

end package basic_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body basic_elements is
end package body basic_elements;