--------------------------------------------------------------------------------
-- File: spi_frame_build.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-04-21 #$: Date of last commit
-- $Rev:: 44           $: Revision of last commit
--
-- Open Points/Remarks:
--  + CRC transprose and complement fucntionality to be included based on
--    a generics (e.g. SPI_CRC_MODE : spi_crc_mode_t := 0)
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
  use math.crc_functions.all;
library spi;
  use spi.spi_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_frame_build is
  generic (
    SPI_FRM_LEN  : natural          := 8;                         -- SPI frame length (number of bits)
    SPI_MSG_LEN  : natural          := 6;                         -- SPI message length (number of bits)
    SPI_CRC_POLY : std_logic_vector := b"01";                     -- SPI CRC polynom (without leading '1')
    SPI_FRM_INIT : std_logic_vector := b"11_1111";                -- SPI frame buffer initial string
    SPI_ERR_OVRN : std_logic_vector := b"11_0111"                 -- SPI message overrun error string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;                                -- System control
    i_shift_mode : in  spi_shift_mode_t;                          -- SPI shift register mode
    i_mdo_load_s : in  std_logic;                                 -- Parallel output message data load
    i_mdo        : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);  -- Parallel output message data
    -- Output ports ------------------------------------------------------------
    o_pdo        : out std_logic_vector(SPI_FRM_LEN-1 downto 0)   -- Parallel output frame data
  );
end entity spi_frame_build;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_frame_build is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_FRAME_BUILD_PDO_INIT : std_logic_vector(SPI_FRM_LEN-1 downto 0) := append_crc(SPI_FRM_INIT, SPI_CRC_POLY);
  constant C_SPI_FRAME_BUILD_PDO_OVRN : std_logic_vector(SPI_FRM_LEN-1 downto 0) := append_crc(SPI_ERR_OVRN, SPI_CRC_POLY);
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal pdo_reg  : std_logic_vector(SPI_FRM_LEN-1 downto 0)             := C_SPI_FRAME_BUILD_PDO_INIT;   -- Frame register current state
  signal pdo_next : std_logic_vector(SPI_FRM_LEN-1 downto 0)             := C_SPI_FRAME_BUILD_PDO_INIT;   -- Frame register next state
  signal pdo_sum  : std_logic_vector(SPI_FRM_LEN-1 downto 0)             := C_SPI_FRAME_BUILD_PDO_INIT;   -- Frame register summary
  signal crc_res  : std_logic_vector(SPI_FRM_LEN-SPI_MSG_LEN-1 downto 0) := (others => '0');              -- SPI message CRC calculation result
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
  attribute KEEP            : string;
  attribute KEEP of pdo_reg : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
--assert SPI_FRM_LEN > SPI_MSG_LEN
--  report "SPI_FRM_LEN <= SPI_MSG_LEN!  The SPI frame must be longer than the SPI message."
--  severity failure;
--assert (SPI_FRM_LEN-SPI_MSG_LEN) = SPI_CRC_POLY'length
--  report "SPI_FRM_LEN-SPI_MSG_LEN != LENGTH(SPI_CRC_POLY)!  Incorrect length of CRC polynom."
--  severity failure;

--------------------------------------------------------------------------------
-- SPI frame build
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      pdo_reg <= C_SPI_FRAME_BUILD_PDO_INIT;
    else
      pdo_reg <= pdo_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- SPI message CRC calculation result
proc_in_crc_res:
crc_res <= build_crc(i_mdo, SPI_CRC_POLY);

-- Frame register summary
proc_in_pdo_sum:
pdo_sum <= i_mdo & crc_res;

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(pdo_reg, i_sys.ena, i_sys.clr, i_shift_mode, i_mdo_load_s, pdo_sum)
begin
  pdo_next <= pdo_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      pdo_next <= C_SPI_FRAME_BUILD_PDO_INIT;
    elsif not(i_shift_mode = NONE) then
      pdo_next <= C_SPI_FRAME_BUILD_PDO_OVRN;
    elsif (i_mdo_load_s = '1') then
      pdo_next <= pdo_sum;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------
proc_out_o_pdo:
o_pdo <= pdo_reg;

end architecture rtl;