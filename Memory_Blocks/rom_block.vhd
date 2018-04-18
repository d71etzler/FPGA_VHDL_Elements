--------------------------------------------------------------------------------
-- File: rom_block.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-04-21 #$: Date of last commit
-- $Rev:: 44           $: Revision of last commit
--
-- Open Points/Remarks:
--  + Non-standard port interface and register implementation to allow an
--    optimized Xilinx RAM block implementation (e.g. use of the intrinsic RAM
--    output register)
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Used library definitions
--------------------------------------------------------------------------------
library ieee;
  use ieee.numeric_std.all;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_textio.all;
library std;
  use std.textio.all;
library basic;
  use basic.basic_elements.all;
library math;
  use math.math_functions.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity rom_block is
  generic (
    ROM_DEPTH : natural := 4;                                         -- ROM block depth (number of ROM lines)
    ROM_WIDTH : natural := 8;                                         -- ROM block width
    OBUF_INIT : std_logic_vector;                                     -- ROM output buffer initial value
    FILE_INIT : string                                                -- ROM block initialization file name
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys     : in  sys_ctrl_t;                                       -- System control
    i_ena     : in  std_logic;                                        -- ROM block enable
    i_addr    : in  std_logic_vector(clogb2(ROM_DEPTH)-1 downto 0);   -- ROM line address
    -- Output ports ------------------------------------------------------------
    o_data    : out std_logic_vector(ROM_WIDTH-1 downto 0)            -- ROM line output data
 );
end entity rom_block;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of rom_block is
  -- Constants -----------------------------------------------------------------
  constant C_MEM_ROM_BLOCK_INIT_ADDR : std_logic_vector(clogb2(ROM_DEPTH)-1 downto 0) := (others => '0');
  -- Types ---------------------------------------------------------------------
  type rom_block_t is array(0 to ROM_DEPTH-1) of std_logic_vector(ROM_WIDTH-1 downto 0);
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Functions -----------------------------------------------------------------
  impure function read_data_file (
    file_name : string
  ) return rom_block_t is
    -- Constants ---------------------------------------------------------------
    -- (none)
    -- Variables ---------------------------------------------------------------
    file     file_ptr : text is in file_name;   -- Pointer to data file
    variable line_ptr : line;                   -- Pointer to line with data
    variable rom_read : rom_block_t;            -- ROM block read data
  begin
    -- Read data  lines from file
    for i in rom_block_t'range loop
      readline(file_ptr, line_ptr);
      read(line_ptr, rom_read(i));
    end loop;

    -- Return data to caller
    return rom_read;
  end function read_data_file;
  -- Signals -------------------------------------------------------------------
  signal rom_block : rom_block_t                            := read_data_file(FILE_INIT);
  signal data_reg  : std_logic_vector(ROM_WIDTH-1 downto 0) := OBUF_INIT;
  signal data_next : std_logic_vector(ROM_WIDTH-1 downto 0) := OBUF_INIT;
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
  -- ROM_STYLE instructs the synthesis tool how to infer ROM memory.  Accepted
  -- values are:
  --  + block: Instructs the tool to infer RAMB type components
  --  + distributed: Instructs the tool to infer the LUT ROMs
  -- By default, the tool selects which ROM to infer based on heuristics that
  -- give the best results for the most designs.
  -- This can be set in the RTL and the XDC.
  attribute ROM_STYLE              : string;
  attribute ROM_STYLE of rom_block : signal is "block";
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
  attribute KEEP             : string;
  attribute KEEP of data_reg : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- ROM block
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      data_reg <= OBUF_INIT;
    else
      data_reg <= data_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------
-- (none)

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(data_reg, i_sys.ena, i_sys.clr, i_ena, i_addr)
begin
  data_next <= data_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      data_next <= OBUF_INIT;
    else
      if (i_ena = '1') then
        data_next <= rom_block(to_integer(unsigned(i_addr)));
      end if;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------
proc_out_o_data:
o_data <= data_reg;

end architecture rtl;