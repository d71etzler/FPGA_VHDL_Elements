--------------------------------------------------------------------------------
-- File: spi_shift_reg.vhd
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
library spi2;
  use spi2.spi2_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi2_shift_reg is
  generic (
    SPI_FRM_LEN    : natural         := 8;                          -- SPI frame length (number of bits)
    SPI_CTRL_MODE  : spi_ctrl_mode_t := CPOL0_CPHA0;                -- SPI control mode
    SPI_SHIFT_DIR  : spi_shift_dir_t := MSB;                        -- SPI shift direction
    SPI_SHIFT_INIT : std_logic_vector:= b"11_1111_11"               -- SPI register initial value
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_res          : in  sys_ctrl_t;                                -- System control
    i_shift_mode   : in  spi_shift_mode_t;                          -- SPI shift register mode
    i_sdi          : in  std_logic;                                 -- Serial input data
    i_pdo          : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);  -- Parallel output frame data
    -- Output ports ------------------------------------------------------------
    o_sdo          : out std_logic;                                 -- Serial output data
    o_pdi          : out std_logic_vector(SPI_FRM_LEN-1 downto 0)   -- Parallel input frame data
  );
end entity spi2_shift_reg;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_shift_reg is
  -- Functions -----------------------------------------------------------------
  -- Evaluate initial value of shift register based on SPI shift direction and
  -- shift register initial vector generics.  (Definition of a constant value
  -- based on a generics value.)
  function init_shift_register (
    shift_dir  : spi_shift_dir_t;   -- Shift direction
    shift_init : std_logic_vector   -- Shift register inital value
  ) return std_logic_vector is
  begin
    case shift_dir is
      when LSB =>
        return shift_init(shift_init'high) & shift_init;
      when MSB =>
        return shift_init & shift_init(shift_init'low);
    end case;
  end function init_shift_register;
  -- Constants -----------------------------------------------------------------
  constant C_SPI_SHIFT_REG_INIT : std_logic_vector(SPI_FRM_LEN downto 0) := init_shift_register(SPI_SHIFT_DIR, SPI_SHIFT_INIT);
  constant C_SPI_SHIFT_REG_LOAD : std_logic                              := '0';
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal shift_reg  : std_logic_vector(SPI_FRM_LEN downto 0) := C_SPI_SHIFT_REG_INIT;   -- Shift register current state
  signal shift_next : std_logic_vector(SPI_FRM_LEN downto 0) := C_SPI_SHIFT_REG_INIT;   -- Shift register next state
  signal reg_load   : std_logic_vector(SPI_FRM_LEN downto 0) := C_SPI_SHIFT_REG_INIT;   -- Shift register loaded value
  signal reg_sample : std_logic_vector(SPI_FRM_LEN downto 0) := C_SPI_SHIFT_REG_INIT;   -- Shift register sampled value
  signal reg_shift  : std_logic_vector(SPI_FRM_LEN downto 0) := C_SPI_SHIFT_REG_INIT;   -- Shift register shifted value
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
-- SPI shift register
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      shift_reg <= C_SPI_SHIFT_REG_INIT;
    else
      shift_reg <= shift_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- GENERATE BLOCK: LSB first
gen_in_shift_lsb:
if (SPI_SHIFT_DIR = LSB) generate
  -- Register load
  proc_in_reg_load_lsb:
  reg_load   <= C_SPI_SHIFT_REG_LOAD & i_pdo;
  -- Register sample
  proc_in_reg_sample_lsb:
  reg_sample <= i_sdi & shift_reg(shift_reg'high-1 downto shift_reg'low);
  -- Register shift
  proc_in_reg_shift_lsb:
  reg_shift  <= '0' & shift_reg(shift_reg'high downto shift_reg'low+1);
end generate;

-- GENERATE BLOCK: MSB first
gen_in_shift_msb:
if (SPI_SHIFT_DIR = MSB) generate
  -- Register load
  proc_in_reg_load_msb:
  reg_load   <= i_pdo & C_SPI_SHIFT_REG_LOAD;
  -- Register sample
  proc_in_reg_sample_msb:
  reg_sample <= shift_reg(shift_reg'high downto shift_reg'low+1) & i_sdi;
  -- Register shift
  proc_in_reg_shift_msb:
  reg_shift  <= shift_reg(shift_reg'high-1 downto shift_reg'low) & '0';
end generate;

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(i_sys.ena, i_sys.clr, i_shift_mode, shift_reg, reg_load, reg_sample, reg_shift)
begin
  shift_next <= shift_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      shift_next <= C_SPI_SHIFT_REG_INIT;
    else
      case i_shift_mode is
        -- SHIFT MODE: LOAD_PDO ------------------------------------------------
        when LOAD_PDO =>
          shift_next <= reg_load;
        -- SHIFT MODE: SAMPLE_SDI ----------------------------------------------
        when SAMPLE_SDI =>
          shift_next <= reg_sample;
        -- SHIFT MODE: SHIFT_DATA ----------------------------------------------
        when SHIFT_DATA =>
          shift_next <= reg_shift;
        -- SHIFT MODE: all others ----------------------------------------------
        when others =>
          null;
      end case;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- GENERATE BLOCK: LSB first
gen_out_shift_lsb:
if (SPI_SHIFT_DIR = LSB) generate
  proc_out_o_sdo_lsb:
  o_sdo <= shift_reg(shift_reg'low);
  -- GENERATE BLOCK: SPI mode 0 (CPOL = 0, CPHA = 0) or SPI mode 2 (CPOL = 1, CPHA = 0)
  gen_out_shift_mode02:
  if ((SPI_CTRL_MODE = CPOL0_CPHA0) or (SPI_CTRL_MODE = CPOL1_CPHA0)) generate
    o_pdi <= shift_reg(shift_reg'high-1 downto shift_reg'low);
  end generate;
  -- GENERATE BLOCK: SPI mode 1 (CPOL = 0, CPHA = 1) or SPI mode 3 (CPOL = 1, CPHA = 1)
  gen_out_shift_mode13:
  if ((SPI_CTRL_MODE = CPOL0_CPHA1) or (SPI_CTRL_MODE = CPOL1_CPHA1)) generate
    o_pdi <= shift_reg(shift_reg'high downto shift_reg'low+1);
  end generate;
end generate;

-- GENERATE BLOCK: MSB first
gen_out_shift_msb:
if (SPI_SHIFT_DIR = MSB) generate
  proc_out_o_sdo_msb:
  o_sdo <= shift_reg(shift_reg'high);
  -- GENERATE BLOCK: SPI mode 0 (CPOL = 0, CPHA = 0) or SPI mode 2 (CPOL = 1, CPHA = 0)
  gen_out_shift_mode02:
  if ((SPI_CTRL_MODE = CPOL0_CPHA0) or (SPI_CTRL_MODE = CPOL1_CPHA0)) generate
    o_pdi <= shift_reg(shift_reg'high downto shift_reg'low+1);
  end generate;
  -- GENERATE BLOCK: SPI mode 1 (CPOL = 0, CPHA = 1) or SPI mode 3 (CPOL = 1, CPHA = 1)
  gen_out_shift_mode13:
  if ((SPI_CTRL_MODE = CPOL0_CPHA1) or (SPI_CTRL_MODE = CPOL1_CPHA1)) generate
    o_pdi <= shift_reg(shift_reg'high-1 downto shift_reg'low);
  end generate;
end generate;

end architecture rtl;