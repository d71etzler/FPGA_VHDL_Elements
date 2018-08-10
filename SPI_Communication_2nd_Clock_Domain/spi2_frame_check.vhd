--------------------------------------------------------------------------------
-- File: spi_frame_check.vhd
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
entity spi_frame_check is
  generic (
    SPI_FRM_LEN  : natural          := 8;                         -- SPI frame length (number of bits)
    SPI_MSG_LEN  : natural          := 6;                         -- SPI message length (number of bits)
    SPI_CRC_POLY : std_logic_vector := b"01";                     -- SPI CRC polynom (without leading '1')
    SPI_MSG_INIT : std_logic_vector := b"11_1111";                -- SPI message buffer initial string
    SPI_ERR_SCLK : std_logic_vector := b"11_1110";                -- SPI clock error message string
    SPI_ERR_CRC  : std_logic_vector := b"11_1101"                 -- SPI frame CRC error message string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;                                -- System control
    i_err_sclk   : in  std_logic;                                 -- SPI clock error
    i_shift_mode : in  spi_shift_mode_t;                          -- SPI shift register mode
    i_pdi        : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);  -- Parallel input frame data
    -- Output ports ------------------------------------------------------------
    o_mdi_load_s : out std_logic;                                 -- Parallel input message data load (one clock cycle pulse)
    o_mdi        : out std_logic_vector(SPI_MSG_LEN-1 downto 0)   -- Parallel input message data
  );
end entity spi_frame_check;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_frame_check is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_FRAME_CHECK_MDI_LOAD_INIT : std_logic                                            := '0';
  constant C_SPI_FRAME_CHECK_MDI_INIT      : std_logic_vector(SPI_MSG_LEN-1 downto 0)             := SPI_MSG_INIT;
  constant C_SPI_FRAME_CHECK_NO_CRC_ERR    : std_logic_vector(SPI_FRM_LEN-SPI_MSG_LEN-1 downto 0) := (others => '0');
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal mdi_load_reg  : std_logic                                            := '0';                         -- Message load register current state
  signal mdi_load_next : std_logic                                            := '0';                         -- Message load register next state
  signal mdi_reg       : std_logic_vector(SPI_MSG_LEN-1 downto 0)             := C_SPI_FRAME_CHECK_MDI_INIT;  -- Message register current state
  signal mdi_next      : std_logic_vector(SPI_MSG_LEN-1 downto 0)             := C_SPI_FRAME_CHECK_MDI_INIT;  -- Message register next state
  signal err_crc       : std_logic                                            := '0';                         -- SPI frame CRC error
  signal crc_res       : std_logic_vector(SPI_FRM_LEN-SPI_MSG_LEN-1 downto 0) := (others => '0');             -- SPI frame CRC calculation result
  signal mdi_mux       : std_logic_vector(SPI_MSG_LEN-1 downto 0)             := C_SPI_FRAME_CHECK_MDI_INIT;  -- Message multiplexer (error priority encoded!) result
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
  attribute KEEP_HIERARCHY : string;
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
  attribute KEEP of mdi_reg : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
--assert SPI_FRM_LEN > SPI_MSG_LEN
--  report "SPI_FRM_LEN <= SPI_MSG_LEN!  The SPI frame must be longer than the SPI message."
--  severity failure;
--assert (SPI_FRM_LEN-SPI_MSG_LEN) = SPI_CRC_POLY'length
--  report "SPI_FRM_LEN-SPI_MSG_LEN != LENGTH(SPI_CRC_POLY)!  Incorrect length of CRC polynom."
--  severity failure;

--------------------------------------------------------------------------------
-- SPI frame check
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------

-- Message load register
proc_register_mdi_load:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      mdi_load_reg <= C_SPI_FRAME_CHECK_MDI_LOAD_INIT;
    else
      mdi_load_reg <= mdi_load_next;
    end if;
  end if;
end process;

-- Message register
proc_register_mdi_reg:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      mdi_reg <= C_SPI_FRAME_CHECK_MDI_INIT;
    else
      mdi_reg <= mdi_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- SPI frame CRC calculation result
proc_in_crc_res:
crc_res <= build_crc(i_pdi, SPI_CRC_POLY);

-- SPI frame CRC error
proc_in_err_crc:
err_crc <= '1' when not(crc_res = C_SPI_FRAME_CHECK_NO_CRC_ERR)
      else '0';

-- Message multiplexer (error priority encoded!) result
proc_in_mdi_mux:
mdi_mux <= SPI_ERR_SCLK when (i_err_sclk = '1')
      else SPI_ERR_CRC  when (err_crc = '1')
      else i_pdi(i_pdi'high downto i_pdi'low+(SPI_FRM_LEN-SPI_MSG_LEN));

-- Next-state logic ------------------------------------------------------------

-- Message load register
proc_next_state_mdi_load:
process(mdi_load_reg, i_sys.ena, i_sys.clr, i_shift_mode)
begin
  mdi_load_next <= mdi_load_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      mdi_load_next <= C_SPI_FRAME_CHECK_MDI_LOAD_INIT;
    elsif (i_shift_mode = LOAD_PDI) then
      mdi_load_next <= not(C_SPI_FRAME_CHECK_MDI_LOAD_INIT);
    else
      mdi_load_next <= C_SPI_FRAME_CHECK_MDI_LOAD_INIT;
    end if;
  end if;
end process;

-- Message register
proc_next_state_mdi_reg:
process(mdi_reg, i_sys.ena, i_sys.clr, i_shift_mode, mdi_mux)
begin
  mdi_next <= mdi_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      mdi_next <= C_SPI_FRAME_CHECK_MDI_INIT;
    elsif (i_shift_mode = LOAD_PDI) then
      mdi_next <= mdi_mux;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- Message load register
proc_out_o_mdi_load_s:
o_mdi_load_s <= mdi_load_reg;

-- Message register
proc_out_o_mdi_reg:
o_mdi <= mdi_reg;

end architecture rtl;