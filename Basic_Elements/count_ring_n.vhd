--------------------------------------------------------------------------------
-- File: count_ring_n.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-25 #$: Date of last commit
-- $Rev:: 18           $: Revision of last commit
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
entity count_ring_n is
  generic (
    N     : natural          := 2;              -- Ring counter length
    INIT  : std_logic_vector := b"00";          -- Initial value
    DIR   : cnt_dir_t        := UP              -- Counter direction
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys : in  sys_ctrl_t;                     -- System control
    i_clr : in  std_logic;                      -- Counter clear
    i_tck : in  std_logic;                      -- Counter tick
    -- Output ports ------------------------------------------------------------
    o_cnt : out std_logic_vector(N-1 downto 0)  -- Counter value
  );
end entity count_ring_n;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of count_ring_n is
  -- Constants -----------------------------------------------------------------
  constant C_COUNT_RING_CNT_INIT : std_logic_vector(N-1 downto 0) := INIT;
  constant C_COUNT_RING_CNT_CMP  : std_logic_vector(N-2 downto 0) := (others => '0');
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal cnt_feed : std_logic;
  signal cnt_reg  : std_logic_vector(N-1 downto 0) := C_COUNT_RING_CNT_INIT;
  signal cnt_next : std_logic_vector(N-1 downto 0) := C_COUNT_RING_CNT_INIT;
  signal cnt_back : std_logic_vector(N-1 downto 0) := C_COUNT_RING_CNT_INIT;
  -- Atributes -----------------------------------------------------------------
  -- KEEP_HIERARCHY is used to prevent optimizations along the hierarchy
  -- boundaries.  The Vivado synthesis tool attempts to keep the same general
  -- hierarchies specified in the RTL, but for QoR reasons it can flatten or
  -- modify them.
  -- If KEEP_HIERARCHY is placed on the instance, the synthesis tool keeps the
  -- boundary on that level static.
  -- This can affect QoR and also should not be used on modules that describe
  -- the control logic of 3-state outputs and I/O buffers.  The KEEP_HIERARCHY
  -- can be placed in the module or architecture level or the instance.  This
  -- attribute can only be set in the RTL.
  attribute KEEP_HIERARCHY        : string;
  attribute KEEP_HIERARCHY of rtl : architecture is "yes";
begin

-- Assertions ------------------------------------------------------------------
--assert (N > 1)
--  report "N <= 1!  The ring counter length must be longer than 1."
--  severity failure;

--------------------------------------------------------------------------------
-- Ring counter
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      cnt_reg <= C_COUNT_RING_CNT_INIT;
    else
      cnt_reg <= cnt_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- GENERATE BLOCK: DOWN-counter
gen_in_count_down:
if (DIR = DOWN) generate
  proc_in_cnt_feed_down:
  cnt_feed <= '1' when (cnt_reg(N-1 downto 1) = C_COUNT_RING_CNT_CMP)
         else '0';
  proc_in_cnt_back_down:
  cnt_back <= cnt_feed & cnt_reg(N-1 downto 1);
end generate;

-- GENERATE BLOCK: UP-counter
gen_in_count_up:
if (DIR = UP) generate
  proc_in_cnt_feed_up:
  cnt_feed <= '1' when (cnt_reg(N-2 downto 0) = C_COUNT_RING_CNT_CMP)
         else '0';
  proc_in_cnt_back_up:
  cnt_back <= cnt_reg(N-2 downto 0) & cnt_feed;
end generate;

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(cnt_reg, i_sys.ena, i_sys.clr, i_clr, i_tck, cnt_back)
begin
  cnt_next <= cnt_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      cnt_next <= C_COUNT_RING_CNT_INIT;
    else
      if (i_clr = '1') then
        cnt_next <= C_COUNT_RING_CNT_INIT;
      elsif (i_tck = '1') then
        cnt_next <= cnt_back;
      end if;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------
proc_out_o_cnt:
o_cnt <= cnt_reg;

end architecture rtl;