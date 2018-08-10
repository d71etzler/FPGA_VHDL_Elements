--------------------------------------------------------------------------------
-- File: detect_edge.vhd
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
entity detect_edge is
  generic (
    LEN    : natural          := 2;       -- Shift register length
    INIT   : std_logic_vector := b"00";   -- Initial register value
    DIR    : edge_dir_t       := RISE     -- Detected edge direction
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys  : in  sys_ctrl_t;              -- System control
    i_sdi  : in  std_logic;               -- Serial input data stream
    -- Output ports ------------------------------------------------------------
    o_edge : out std_logic                -- Detected edge
  );
end entity detect_edge;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of detect_edge is
  -- Functions -----------------------------------------------------------------
  function init_cmp_pattern (
    dir : edge_dir_t
    ) return std_logic_vector is
    -- Constants ---------------------------------------------------------------
    constant init_vector : std_logic_vector(LEN-1 downto 0) := (0 => '0', others => '1');
    -- Variables ---------------------------------------------------------------
    -- (none)
  begin
    case dir is
      when RISE =>
        return init_vector;
      when others =>
        return not(init_vector);
    end case;
  end function init_cmp_pattern;
  -- Constants -----------------------------------------------------------------
  constant C_DETECT_EDGE_PATTERN : std_logic_vector(LEN-1 downto 0) := init_cmp_pattern(DIR);
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal shift_reg  : std_logic_vector(LEN-1 downto 0) := INIT;   -- Shift register current state
  signal shift_next : std_logic_vector(LEN-1 downto 0) := INIT;   -- Shift register next state
  signal shift_temp : std_logic_vector(LEN-1 downto 0) := INIT;   -- Shift register temporary shifting result
  -- Attributes ----------------------------------------------------------------
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
--assert (LEN > 1)
--  report "LEN <= 1!  Shift register length must larger than 1."
--  severity error;

--------------------------------------------------------------------------------
-- Shift register with output pattern comparator
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      shift_reg <= INIT;
    else
      shift_reg <= shift_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------
proc_in_shift_temp:
shift_temp <= i_sdi & shift_reg(shift_reg'high downto shift_reg'low+1);

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(shift_reg, shift_temp, i_sys.ena, i_sys.clr)
begin
  shift_next <= shift_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      shift_next <= INIT;
    else
      shift_next <= shift_temp;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------
proc_out_o_edge:
o_edge <= '1' when (shift_reg = C_DETECT_EDGE_PATTERN)
     else '0';

end architecture rtl;