--------------------------------------------------------------------------------
-- File: spi_frm_bld_2clkd.vhd
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
library spi_2clkd;
  use spi_2clkd.spi_elements_2clkd.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_frm_bld_2clkd is
  generic (
    SPI_FRM_LEN      : natural          := 8;                         -- SPI frame length (number of bits)
    SPI_PAR_VAR      : spi_parity_var_t := ODD;                       -- SPI parity variant
    SPI_MDO_INIT     : std_logic_vector := b"111_1111";               -- SPI message buffer initial string
    SPI_ERR_OVRN     : std_logic_vector := b"111_1011"                -- SPI message overrun error string
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys            : in  sys_ctrl_t;                                -- System control
    i_csel           : in  std_logic;                                 -- SPI chip select (synchronized to SDI clock domain)
    i_csel_rise      : in  std_logic;                                 -- SPI chip select rising edge (synchronized to SDI clock domain)
    i_sclk_cnt       : in  std_logic;                                 -- SPI clock edge contern (synchronized to SDI domain)
    i_mdo_load_s     : in  std_logic;                                 -- Parallel output message data load strobe
    i_mdo            : in  std_logic_vector(SPI_FRM_LEN-2 downto 0);  -- Parallel output message data
    i_sclk_cnt_2clkd : in  std_logic;                                 -- SPI clock edge counter (2nd clock domain)
    -- Output ports ------------------------------------------------------------
    o_pdo_load       : out std_logic;                                 -- Parallel output frame data load
    o_pdo            : out std_logic_vector(SPI_FRM_LEN-1 downto 0)   -- Parallel output frame data
  );
end entity spi_frm_bld_2clkd;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_frm_bld_2clkd is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_FRM_BLD_2CLKD_PDO_LOAD_INIT : std_logic                                := '0';                                                     -- Frame register data load initial value
  constant C_SPI_FRM_BLD_2CLKD_PDO_INIT      : std_logic_vector(SPI_FRM_LEN-1 downto 0) := get_parity(SPI_MDO_INIT, SPI_PAR_VAR) & SPI_MDO_INIT;    -- Frame register data initial value
  constant C_SPI_FRM_BLD_2CLKD_ERR_OVRN      : std_logic_vector(SPI_FRM_LEN-1 downto 0) := get_parity(SPI_ERR_OVRN, SPI_PAR_VAR) & SPI_ERR_OVRN;    -- Overrun error
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal pdo_load_reg  : std_logic                                := '0';                             -- Frame register load current state
  signal pdo_load_next : std_logic                                := '0';                             -- Frame register load next state
  signal pdo_reg       : std_logic_vector(SPI_FRM_LEN-1 downto 0) := C_SPI_FRM_BLD_2CLKD_PDO_INIT;    -- Frame register current state
  signal pdo_next      : std_logic_vector(SPI_FRM_LEN-1 downto 0) := C_SPI_FRM_BLD_2CLKD_PDO_INIT;    -- Frame register next state
  signal pdo_sum       : std_logic_vector(SPI_FRM_LEN-1 downto 0) := C_SPI_FRM_BLD_2CLKD_PDO_INIT;    -- Frame register summary
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
  attribute KEEP                 : string;
  attribute KEEP of pdo_load_reg : signal is "true";
  attribute KEEP of pdo_reg      : signal is "true";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI frame build
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------

-- Frame register data load
proc_register_pdo_load:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      pdo_load_reg <= C_SPI_FRM_BLD_2CLKD_PDO_LOAD_INIT;
    else
      pdo_load_reg <= pdo_load_next;
    end if;
  end if;
end process;

-- Frame register data
proc_register_pdo:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      pdo_reg <= C_SPI_FRM_BLD_2CLKD_PDO_INIT;
    else
      pdo_reg <= pdo_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- Frame register summary
proc_in_pdo_sum:
pdo_sum <= get_parity(i_mdo, SPI_PAR_VAR) & i_mdo;

-- Next-state logic ------------------------------------------------------------

-- Frame register data load
proc_next_state_pdo_load:
process(pdo_load_reg, i_sys.ena, i_sys.clr, i_csel_rise, i_sclk_cnt)
begin
  pdo_load_next <= pdo_load_reg;
  if (i_sys.ena = '1') then
    if(i_sys.clr = '1') then
      pdo_load_next <= C_SPI_FRM_BLD_2CLKD_PDO_LOAD_INIT;
    elsif (i_csel_rise = '1') then
      pdo_load_next <= '1';
    elsif (i_sclk_cnt = '1') then
      pdo_load_next <= '0';
    end if;
  end if;
end process;

-- Frame register data
proc_next_state_pdo:
process(pdo_reg, i_sys.ena, i_sys.clr, i_csel, i_sclk_cnt, i_mdo_load_s, pdo_sum)
begin
  pdo_next <= pdo_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      pdo_next <= C_SPI_FRM_BLD_2CLKD_PDO_INIT;
    elsif (i_csel = '1') and (i_sclk_cnt = '1') then
      pdo_next <= C_SPI_FRM_BLD_2CLKD_ERR_OVRN;
    elsif (i_mdo_load_s = '1') then
      pdo_next <= pdo_sum;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- Frame register data load
proc_out_o_pdo_load:
o_pdo_load <= '1' when (pdo_load_reg = '1') and (i_sclk_cnt_2clkd = '0')
         else '0';

-- Frame register data
proc_out_o_pdo:
o_pdo <= pdo_reg;

end architecture rtl;