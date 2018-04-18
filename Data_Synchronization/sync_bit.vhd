--------------------------------------------------------------------------------
-- File: sync_bit.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-25 #$: Date of last commit
-- $Rev:: 20           $: Revision of last commit
--
-- Description:
--  Synchronizes a single-bit signal from a source clock domain to a
--  destination clock domain using a chain of flip-flops (synchronizer
--  flip-flop followed by one or more guard flip-flops).
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

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity sync_bit is
  generic (
    GUARD_LEN : positive  := 1;   -- Guard flip-flop shift register length
    SYNC_INIT : std_logic := '0'  -- Synchronization initial register values
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst     : in  std_logic;    -- Reset
    i_clk     : in  std_logic;    -- System clock
    i_bit_a   : in  std_logic;    -- Input bit (asynchronous)
    -- Output ports ------------------------------------------------------------
    o_bit     : out std_logic     -- Output bit (synchronous)
  );
end entity sync_bit;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of sync_bit is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal sync_reg   : std_logic                              := SYNC_INIT;
  signal sync_next  : std_logic                              := SYNC_INIT;
  signal guard_reg  : std_logic_vector(GUARD_LEN-1 downto 0) := (others => SYNC_INIT);
  signal guard_next : std_logic_vector(GUARD_LEN-1 downto 0) := (others => SYNC_INIT);
  -- Attributes ----------------------------------------------------------------
  -- SHREG_EXTRACT instructs the synthesis tool on whether to infer SRL
  -- structures.  Accepted values are:
  --  • YES: The tool infers SRL structures.
  --  • NO: The does not infer SRLs and instead creates registers.
  -- Place SHREG_EXTRACT on the signal declared for SRL or the module/entity
  -- with the SRL.  It can be set in the RTL or the XDC.
  attribute SHREG_EXTRACT               : string;
  attribute SHREG_EXTRACT of sync_reg   : signal is "no";
  attribute SHREG_EXTRACT of sync_next  : signal is "no";
  attribute SHREG_EXTRACT of guard_reg  : signal is "no";
  attribute SHREG_EXTRACT of guard_next : signal is "no";
  -- The ASYNC_REG is an attribute that affects many processes in the Vivado
  -- tools flow.  The purpose of this attribute is to inform the tool that a
  -- register is capable of receiving asynchronous data in the D input pin
  -- relative to the source clock, or that the register is a synchronizing
  -- register within a synchronization chain.
  attribute ASYNC_REG              : string;
  attribute ASYNC_REG of sync_reg  : signal is "true";
  attribute ASYNC_REG of guard_reg : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Input signal synchronization
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------

-- Synchronization register
proc_register_sync:
process(i_clk)
begin
  if (rising_edge(i_clk)) then
    if (i_rst = '1') then
      sync_reg <= SYNC_INIT;
    else
      sync_reg <= sync_next;
    end if;
  end if;
end process;

-- Guard register
proc_register_guard:
process(i_clk)
begin
  if (rising_edge(i_clk)) then
    if (i_rst = '1') then
      guard_reg <= (others => SYNC_INIT);
    else
      guard_reg <= guard_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------
-- (none)

-- Next-state logic ------------------------------------------------------------
proc_next_state_sync_next:
sync_next <= i_bit_a;

-- GENERATE BLOCK: Guard flip-flop register length = 1
gen_next_state_guard_len_eq_1:
if (GUARD_LEN = 1) generate
  proc_next_state_len_eq_1:
  guard_next(GUARD_LEN-1) <= sync_reg;
end generate;

-- GENERATE BLOCK: Guard flip-flop register length > 1
gen_next_state_guard_len_gt_1:
if (GUARD_LEN > 1) generate
  proc_next_state_len_gt_1:
  guard_next <= sync_reg & guard_reg(GUARD_LEN-1 downto 1);
end generate;

-- Output logic ----------------------------------------------------------------
proc_out_o_bit:
o_bit <= guard_reg(0);

end architecture rtl;