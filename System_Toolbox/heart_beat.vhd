--------------------------------------------------------------------------------
-- File: heart_beat.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-24 #$: Date of last commit
-- $Rev:: 17           $: Revision of last commit
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
library basic;
  use basic.basic_elements.all;
library math;
  use math.math_functions.all;
library system;
  use system.system_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity heart_beat is
  generic (
    SYS_CLK_FREQ : real := 100.0e+6;  -- System clock frequency
    HRT_BEAT_PER : real := 2.0        -- Heartbeat period
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;    -- System control
    -- Output ports ------------------------------------------------------------
    o_hrbt       : out std_logic      -- Heartbeat double pulse
  );
end entity heart_beat;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of heart_beat is

  -- Constants -----------------------------------------------------------------
  constant C_HRT_BEAT_CNT_MOD   : natural                                 := integer(SYS_CLK_FREQ*HRT_BEAT_PER);
  constant C_HRT_BEAT_CNT_LEN   : natural                                 := clogb2(C_HRT_BEAT_CNT_MOD);
  constant C_HRT_BEAT_CNT_INIT  : natural                                 := 0;
  constant C_HRT_BEAT_CNT_DIR   : cnt_dir_t                               := UP;
  constant C_HRT_BEAT_BT1_START : natural                                 := 1*C_HRT_BEAT_CNT_MOD/2;
  constant C_HRT_BEAT_BT1_STOP  : natural                                 := C_HRT_BEAT_BT1_START+(C_HRT_BEAT_CNT_MOD/8);
  constant C_HRT_BEAT_BT2_START : natural                                 := 3*C_HRT_BEAT_CNT_MOD/4;
  constant C_HRT_BEAT_BT2_STOP  : natural                                 := C_HRT_BEAT_BT2_START+(C_HRT_BEAT_CNT_MOD/8);
  constant C_HRT_BEAT_BT1_LOW   : unsigned(C_HRT_BEAT_CNT_LEN-1 downto 0) := to_unsigned(C_HRT_BEAT_BT1_START, C_HRT_BEAT_CNT_LEN);
  constant C_HRT_BEAT_BT1_HIGH  : unsigned(C_HRT_BEAT_CNT_LEN-1 downto 0) := to_unsigned(C_HRT_BEAT_BT1_STOP, C_HRT_BEAT_CNT_LEN);
  constant C_HRT_BEAT_BT2_LOW   : unsigned(C_HRT_BEAT_CNT_LEN-1 downto 0) := to_unsigned(C_HRT_BEAT_BT2_START, C_HRT_BEAT_CNT_LEN);
  constant C_HRT_BEAT_BT2_HIGH  : unsigned(C_HRT_BEAT_CNT_LEN-1 downto 0) := to_unsigned(C_HRT_BEAT_BT2_STOP, C_HRT_BEAT_CNT_LEN);
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  --(none)
  -- Signals -------------------------------------------------------------------
  signal hrbt_cnt : std_logic_vector(C_HRT_BEAT_CNT_LEN-1 downto 0) := (others => '0');
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

--------------------------------------------------------------------------------
-- Heartbeat timer
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
heart_beat_count: count_mod_m
  generic map (
    M     => C_HRT_BEAT_CNT_MOD,
    INIT  => C_HRT_BEAT_CNT_INIT,
    DIR   => C_HRT_BEAT_CNT_DIR
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => '0',
    i_tck => '1',
    -- Output ports ------------------------------------------------------------
    o_cnt => hrbt_cnt
  );

-- Output logic ----------------------------------------------------------------
proc_o_hrbt:
o_hrbt <= '1' when ((unsigned(hrbt_cnt) >= C_HRT_BEAT_BT1_LOW) and (unsigned(hrbt_cnt) <= C_HRT_BEAT_BT1_HIGH))
     else '1' when ((unsigned(hrbt_cnt) >= C_HRT_BEAT_BT2_LOW) and (unsigned(hrbt_cnt) <= C_HRT_BEAT_BT2_HIGH))
     else '0';

end architecture structural;