--------------------------------------------------------------------------------
-- File: arbit_rnd_rbn.vhd
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
entity arbit_rnd_rbn is
  generic (
    LEN     : natural := 8                            -- Arbiter vector length
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys   : in  sys_ctrl_t;                         -- System control
    i_ack   : in  std_logic;                          -- Grant acknowledge
    i_req   : in  std_logic_vector(LEN-1 downto 0);   -- Arbiter requests
    -- Output ports ------------------------------------------------------------
    o_grant : out std_logic_vector(LEN-1 downto 0)    -- Round-robin grants
  );
end entity arbit_rnd_rbn;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of arbit_rnd_rbn is
  -- Constants -----------------------------------------------------------------
  constant C_ARBIT_RND_RBN_GRANT_ALL_ZEROS : std_logic_vector(LEN-1 downto 0) := (others => '0');   -- Grant vector initialization value
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal grant_reg       : std_logic_vector(LEN-1 downto 0);  -- Actual grant current state
  signal grant_next      : std_logic_vector(LEN-1 downto 0);  -- Actual grant next state
  signal prev_reg        : std_logic_vector(LEN-1 downto 0);  -- Previous grant current state
  signal prev_next       : std_logic_vector(LEN-1 downto 0);  -- Previous grant next state
  signal mask_prev_grant : std_logic_vector(LEN-1 downto 0);  -- Previous grant mask
  signal sel_new_win     : std_logic_vector(LEN-1 downto 0);  -- New winner selection
  signal isol_lsb        : std_logic_vector(LEN-1 downto 0);  -- Least-significant bit isolation
  signal sel_new_grant   : std_logic_vector(LEN-1 downto 0);  -- New grant selection
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
  attribute keep_hierarchy        : string;
  attribute keep_hierarchy of rtl : architecture is "yes";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Round-robin access control sequencer (arbiter)
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------

-- Actual grant
proc_register_grant:
process(i_sys.clk)
  begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      grant_reg <= C_ARBIT_RND_RBN_GRANT_ALL_ZEROS;
    else
      grant_reg <= grant_next;
    end if;
  end if;
end process;

-- Previous grant
proc_register_prev:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      prev_reg <= C_ARBIT_RND_RBN_GRANT_ALL_ZEROS;
    else
      prev_reg <= prev_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- Mask previous grants
proc_in_mask_prev_grant:
mask_prev_grant <= i_req and not(std_logic_vector(unsigned(prev_reg)-1) or prev_reg);

-- Select new winner
proc_in_sel_new_win:
sel_new_win <= mask_prev_grant and std_logic_vector(unsigned(not(mask_prev_grant))+1);

-- Isolate least significant bit set
proc_in_isol_lsb:
isol_lsb <= i_req and std_logic_vector(unsigned(not(i_req))+1);

-- Select new grant
proc_in_sel_new_grant:
sel_new_grant <= sel_new_win when (mask_prev_grant /= C_ARBIT_RND_RBN_GRANT_ALL_ZEROS)
            else isol_lsb;

-- Next-state logic ------------------------------------------------------------

-- Actual grant next-state
proc_grant_next_state:
process(grant_reg, i_sys.ena, i_sys.clr, i_ack, sel_new_grant)
begin
  grant_next <= grant_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      grant_next <= C_ARBIT_RND_RBN_GRANT_ALL_ZEROS;
    else
      if ((grant_reg = C_ARBIT_RND_RBN_GRANT_ALL_ZEROS) or (i_ack = '1')) then
        grant_next <= sel_new_grant;
      end if;
    end if;
  end if;
end process;

-- Previous grant next-state
process(grant_reg, prev_reg, i_sys.ena, i_sys.clr, i_ack, sel_new_grant)
begin
  prev_next <= prev_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      prev_next <= C_ARBIT_RND_RBN_GRANT_ALL_ZEROS;
    else
      if ((grant_reg = C_ARBIT_RND_RBN_GRANT_ALL_ZEROS) or (i_ack = '1')) then
        if (sel_new_grant /= C_ARBIT_RND_RBN_GRANT_ALL_ZEROS) then
          prev_next <= sel_new_grant;
        end if;
      end if;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------
proc_out_o_grant:
o_grant <= grant_reg;

end architecture rtl;