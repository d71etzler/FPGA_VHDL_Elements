--------------------------------------------------------------------------------
-- File: reg_line.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-04-21 #$: Date of last commit
-- $Rev:: 44           $: Revision of last commit
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
library mem;
  use mem.mem_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity reg_line is
  generic (
    REG_WIDTH : natural          := 8;                          -- Register bit length
    REG_INIT  : std_logic_vector := x"00";                      -- Initial value
    REG_OPC   : reg_op_t         := WR_NO_CHANGE_RD_NO_CHANGE   -- Register operation code
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys     : in  sys_ctrl_t;                                 -- System control
    i_ena     : in  std_logic;                                  -- Register enable
    i_wr      : in  std_logic;                                  -- Register write enable
    i_accs_s  : in  std_logic;                                  -- Register access (one clock cycle)
    i_data    : in  std_logic_vector(REG_WIDTH-1 downto 0);     -- Register input data
    -- Output ports ------------------------------------------------------------
    o_data    : out std_logic_vector(REG_WIDTH-1 downto 0)      -- Register output data
  );
end entity reg_line;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of reg_line is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal write_data   : std_logic_vector(REG_WIDTH-1 downto 0) := REG_INIT;   -- Data to be written to storage register
  signal store_data   : std_logic_vector(REG_WIDTH-1 downto 0) := REG_INIT;   -- Stored data
  signal buf_data     : std_logic_vector(REG_WIDTH-1 downto 0) := REG_INIT;   -- Buffered data
  signal store_load_s : std_logic                              := '0';        -- Storage register load (one clock cycle)
  signal buf_load_s   : std_logic                              := '0';        -- Buffer register load (one clock cycle)
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
  attribute KEEP_HIERARCHY                         : string;
  attribute KEEP_HIERARCHY of reg_line_store_unit  : label is "yes";
  attribute KEEP_HIERARCHY of reg_line_buffer_unit : label is "yes";
  -- Use the KEEP attribute to prevent optimizations where signals are either
  -- optimized or absorbed into logic blocks. This attribute instructs the
  -- synthesis tool to keep the signal it was placed on, and that signal is
  -- placed in the netlist.
  -- For example, if a signal is an output of a 2 bit AND gate, and it drives
  -- another AND gate, the KEEP attribute can be used to prevent that signal
  -- from being merged into a larger LUT that encompasses both AND gates.
  -- KEEP is also commonly used in conjunction with timing constraints. If there
  -- is a timing constraint on a signal that would normally be optimized, KEEP
  -- prevents that and allows the correct timing rules to be used.
  -- Note: The KEEP attribute is not supported on the port of a module or
  -- entity. If you need to keep specific ports, either use the
  -- -flatten_hierarchy none setting, or put a DONT_TOUCH on the module or
  -- entity itself.
  attribute KEEP               : string;
  attribute KEEP of write_data : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Storage buffer
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Write data multiplexer for register operation 'write no change - read no change'
gen_write_data_wr_no_change_rd_no_change: if (REG_OPC  = WR_NO_CHANGE_RD_NO_CHANGE) generate
  proc_in_write_data_wr_no_change_rd_no_change:
  write_data <= store_data;
end generate;

-- Write data multiplexer for register operation 'write set data - read no change'
gen_write_data_wr_set_data_rd_no_change: if (REG_OPC = WR_SET_DATA_RD_NO_CHANGE) generate
  proc_in_write_data_wr_set_data_rd_no_change:
  write_data <= i_data when (i_wr = '1')
           else store_data;
end generate;

-- Write data multiplexer for register operation 'write set data - read clear data'
gen_write_data_wr_set_data_rd_clear_data: if (REG_OPC = WR_SET_DATA_RD_CLEAR_DATA) generate
  proc_in_write_data_wr_set_data_rd_clear_data:
  write_data <= i_data when (i_wr = '1')
           else REG_INIT;
end generate;

-- Write data multiplexer for register operation 'write or data - read no change'
gen_write_data_wr_or_data_rd_no_change: if (REG_OPC = WR_OR_DATA_RD_NO_CHANGE) generate
  proc_in_write_data_wr_or_data_rd_no_change:
  write_data <= (i_data or store_data) when (i_wr = '1')
           else store_data;
end generate;

-- Write data multiplexer for register operation 'write or data - read clear data'
gen_write_data_wr_or_data_rd_clear_data: if (REG_OPC = WR_OR_DATA_RD_CLEAR_DATA) generate
  proc_in_write_data_wr_or_data_rd_clear_data:
  write_data <= (i_data or store_data) when (i_wr = '1')
           else REG_INIT;
end generate;

-- Write data multiplexer for register operation 'write xor data - read no change'
gen_write_data_wr_xor_data_rd_no_change: if (REG_OPC = WR_XOR_DATA_RD_NO_CHANGE) generate
  proc_in_write_data_wr_xor_data_rd_no_change:
  write_data <= (i_data xor store_data) when (i_wr = '1')
           else store_data;
end generate;

-- Write data multiplexer for register operation 'write xor data - read clear data'
gen_write_data_wr_xor_data_rd_clear_data: if (REG_OPC = WR_XOR_DATA_RD_CLEAR_DATA) generate
  proc_in_write_data_wr_xor_data_rd_clear_data:
  write_data <= (i_data xor store_data) when (i_wr = '1')
           else REG_INIT;
end generate;

-- Write data multiplexer for register operation 'write and data - read no change'
gen_write_data_wr_and_data_rd_no_change: if (REG_OPC = WR_AND_DATA_RD_NO_CHANGE) generate
  proc_in_write_data_wr_and_data_rd_no_change:
  write_data <= (i_data and store_data) when (i_wr = '1')
           else store_data;
end generate;

-- Write data multiplexer for register operation 'write and data - read clear data'
gen_write_data_wr_and_data_rd_clear_data: if (REG_OPC = WR_AND_DATA_RD_CLEAR_DATA) generate
  proc_in_write_data_wr_and_data_rd_clear_data:
  write_data <= (i_data and store_data) when (i_wr = '1')
           else REG_INIT;
end generate;

-- Storage register load
proc_in_store_load_s:
store_load_s <= (i_ena and i_accs_s);

-- Component instantiation -----------------------------------------------------
reg_line_store_unit: buffer_bvec
  generic map (
    LEN    => REG_WIDTH,
    INIT   => REG_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys  => i_sys,
    i_clr  => '0',
    i_set  => store_load_s,
    i_bvec => write_data,
    -- Output ports ------------------------------------------------------------
    o_bvec => store_data
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Output buffer
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Buffer multiplexed data
proc_in_buf_data:
buf_data <= i_data when (i_wr = '1')
       else store_data;

-- Buffer register load
proc_in_buf_load_s:
buf_load_s <= (i_ena and i_accs_s);

-- Component instantiation -----------------------------------------------------
reg_line_buffer_unit: buffer_bvec
  generic map (
    LEN    => REG_WIDTH,
    INIT   => REG_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys  => i_sys,
    i_clr  => '0',
    i_set  => buf_load_s,
    i_bvec => buf_data,
    -- Output ports ------------------------------------------------------------
    o_bvec => o_data
  );

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;