--------------------------------------------------------------------------------
-- File: spi_shift_reg_2clkd.vhd
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
library spi_2clkd;
  use spi_2clkd.spi_elements_2clkd.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_shift_reg_2clkd is
  generic (
    SPI_FRM_LEN      : natural         := 8;                            -- SPI frame length (number of bits)
    SPI_CLK_POL      : spi_clk_pol_t   := CPOL0;                        -- SPI clock polarity
    SPI_SHIFT_DIR    : spi_shift_dir_t := MSB;                          -- SPI shift direction
    SPI_SHIFT_INIT   : std_logic_vector:= b"1111_1111"                  -- SPI shift register initial value
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst            : in  std_logic;                                   -- SPI block reset
    i_sclk_2clkd     : in  std_logic;                                   -- SPI clock (2nd clock domain)
    i_csel_2clkd     : in  std_logic;                                   -- SPI chip select (2nd clock domain)
    i_sdi_2clkd      : in  std_logic;                                   -- SPI serial input data (2nd clock domain)
    i_pdo_load_2clkd : in  std_logic;                                   -- Parallel output frame data load strobe (2nd clock domain)
    i_pdo_2clkd      : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);    -- Parallel output frame data (2nd clock domain)
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd      : out std_logic;                                   -- SPI serial output data (2nd clock domain)
    o_pdi_2clkd      : out std_logic_vector(SPI_FRM_LEN-1 downto 0)     -- Parallel input frame data (2nd clock domain)
  );
end entity spi_shift_reg_2clkd;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_shift_reg_2clkd is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_SHIFT_REG_2CLKD_CPOL        : std_logic                                := get_clk_pol(SPI_CLK_POL);                        -- Shift register clock polarity as std_logic for combinatorical assignment
  constant C_SPI_SHIFT_REG_2CLKD_SHIFT_DIR   : shift_dir_t                              := get_shift_dir(SPI_SHIFT_DIR);                    -- Shift register shift direction a basic shift direction value
  constant C_SPI_SHIFT_REG_2CLKD_SAMPLE_INIT : std_logic                                := get_sample_reg(SPI_SHIFT_INIT, SPI_SHIFT_DIR);   -- SPI sample bit buffer initial value based on shift direction
  constant C_SPI_SHIFT_REG_2CLKD_SHIFT_INIT  : std_logic_vector(SPI_FRM_LEN-1 downto 0) := get_shift_reg(SPI_SHIFT_INIT, SPI_SHIFT_DIR);    -- SPI shift register initial value based on shift direction
  constant C_SPI_SHIFT_REG_2CLKD_SAMPLE_CLR  : std_logic                                := '0';                                             -- SPI sample bit buffer clear (never clear)
  constant C_SPI_SHIFT_REG_2CLKD_SHIFT_CLR   : std_logic                                := '0';                                             -- SPI shift register clear (never clear)
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal spi_shift_ctrl   : sys_ctrl_t := (                                                                 -- SPI shift register control
    rst => '1',
    clk => '0',
    ena => '1',
    clr => '0'
  );
  signal spi_sample_ctrl  : sys_ctrl_t := (                                                                 -- SPI sample register control
    rst => '1',
    clk => '0',
    ena => '1',
    clr => '0'
  );
  signal spi_sample_shift : std_logic                                := C_SPI_SHIFT_REG_2CLKD_SAMPLE_INIT;  -- Connection between sample bit and shift register
  signal spi_shift_psd    : std_logic_vector(SPI_FRM_LEN-1 downto 0) := C_SPI_SHIFT_REG_2CLKD_SHIFT_INIT;   -- Shift register content
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
-- (none)

--------------------------------------------------------------------------------
-- Common input signal assignments
--------------------------------------------------------------------------------

-- SPI sample register control reset
proc_in_spi_sample_ctrl_rst:
spi_sample_ctrl.rst <= i_rst;

-- SPI sample register control clock
-- Translate SPI clock based on clock polarity and clock phase to sample with
-- rising edge as defined in basic buffer bit component (buffer_bit).
proc_in_spi_sample_ctrl_clk:
spi_sample_ctrl.clk <= i_sclk_2clkd xor (not(C_SPI_SHIFT_REG_2CLKD_CPOL));

-- SPI sample register control enable
proc_in_spi_sample_ctrl_ena:
spi_sample_ctrl.ena <= '1';

-- SPI sample register control clear
proc_in_spi_sample_ctrl_clr:
spi_sample_ctrl.clr <= '0';

-- SPI shift register control reset
proc_in_spi_shift_ctrl_rst:
spi_shift_ctrl.rst <= i_rst;

-- SPI shift register control clock
-- Translate SPI clock based on clock polarity and clock phase to shift with
-- rising edge as defined in basic shift register component (shift_reg).
proc_in_spi_shift_ctrl_clk:
spi_shift_ctrl.clk <= i_sclk_2clkd xor C_SPI_SHIFT_REG_2CLKD_CPOL;

-- SPI shift register control enable
proc_in_spi_shift_ctrl_ena:
spi_shift_ctrl.ena <= '1';

-- SPI shift register control clear
proc_in_spi_shift_ctrl_clr:
spi_shift_ctrl.clr <= '0';

--------------------------------------------------------------------------------
-- SPI sample register (2nd clock domain) for MSB shift direction
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_shift_reg_2clkd_sample_unit: buffer_bit
  generic map (
    INIT  => C_SPI_SHIFT_REG_2CLKD_SAMPLE_INIT
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => spi_sample_ctrl,
    i_clr => C_SPI_SHIFT_REG_2CLKD_SAMPLE_CLR,
    i_tck => i_csel_2clkd,
    i_bit => i_sdi_2clkd,
    -- Output ports ------------------------------------------------------------
    o_bit => spi_sample_shift
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI shift register (2nd clock domain) for MSB shift direction
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_shift_reg_2clkd_shift_unit: shift_reg
  generic map (
    LEN   => SPI_FRM_LEN,
    INIT  => C_SPI_SHIFT_REG_2CLKD_SHIFT_INIT,
    DIR   => C_SPI_SHIFT_REG_2CLKD_SHIFT_DIR
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => spi_shift_ctrl,
    i_clr => C_SPI_SHIFT_REG_2CLKD_SHIFT_CLR,
    i_set => i_pdo_load_2clkd,
    i_tck => i_csel_2clkd,
    i_ssd => spi_sample_shift,
    i_psd => i_pdo_2clkd,
    -- Output ports ------------------------------------------------------------
    o_ssd => o_sdo_2clkd,
    o_psd => spi_shift_psd
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Common output signal assignments
--------------------------------------------------------------------------------

-- Parallel data output (parallel data into design)
proc_out_o_pdi:
o_pdi_2clkd <= spi_shift_psd(SPI_FRM_LEN-2 downto 0) & spi_sample_shift;

end architecture rtl;