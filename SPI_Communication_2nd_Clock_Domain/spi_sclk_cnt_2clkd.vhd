--------------------------------------------------------------------------------
-- File: spi_sclk_cnt_2clkd.vhd
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
library math;
  use math.math_functions.all;
library spi_2clkd;
  use spi_2clkd.spi_elements_2clkd.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_sclk_cnt_2clkd is
  generic (
    SPI_FRM_LEN        : natural       := 8;      -- SPI frame length (in bits)
    SPI_CLK_POL        : spi_clk_pol_t := CPOL0   -- SPI control mode
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst              : in  std_logic;           -- SPI block reset
    i_csel_fall        : in  std_logic;           -- SPI chip select falling edge (Synchronized to SDI clock domain)
    i_sclk_2clkd       : in  std_logic;           -- Rising/falling edge of SPI clock
    i_csel_2clkd       : in  std_logic;           -- SPI chip select
    -- Output ports ------------------------------------------------------------
    o_sclk_cnt_2clkd   : out std_logic;           -- SPI clock edge counting
    o_sclk_lead_2clkd  : out std_logic;           -- SPI clokc leading edge
    o_sclk_trail_2clkd : out std_logic            -- SPI clock trailing edge
  );
end entity spi_sclk_cnt_2clkd;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_sclk_cnt_2clkd is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_SCLK_CNT_2CLKD_CPOL          : std_logic                        := get_clk_pol(SPI_CLK_POL);     -- (Positive/neagtive) clock edge counter clock polarity as std_logic for combinatorical assignment
  constant C_SPI_SCLK_CNT_2CLKD_EDGE_CNT_INIT : natural                          := 0;                            -- (Positive/negative) clock edge counter initial value
  constant C_SPI_SCLK_CNT_2CLKD_EDGE_CNT_DIR  : cnt_dir_t                        := UP;                           -- (Positive/negative) clock edge counter direction
  constant C_SPI_SCLK_CNT_2CLKD_EDGE_ZERO_CMP : unsigned(SPI_FRM_LEN-1 downto 0) := to_unsigned(0, SPI_FRM_LEN);  -- Zero value comparison
  constant C_SPI_SCLK_CNT_2CLKD_EDGE_ONE_CMP  : unsigned(SPI_FRM_LEN-1 downto 0) := to_unsigned(1, SPI_FRM_LEN);  -- One value comparison
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal sclk_pos     : std_logic                                        := '0';                -- Positive SPI clock
  signal sclk_neg     : std_logic                                        := '1';                -- Negative SPI clock
  signal sclk_pos_cnt : std_logic_vector(clogb2(SPI_FRM_LEN)-1 downto 0) := (others => '0');    -- Positive SPI clock edge counter
  signal sclk_neg_cnt : std_logic_vector(clogb2(SPI_FRM_LEN)-1 downto 0) := (others => '0');    -- Negative SPI clock edge counter
  -- Attributes ----------------------------------------------------------------
  -- (none)

begin
-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI clock positive edge counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Positive SPI clock edge counter control clock
-- Translate SPI clock based on clock polarity and clock phase to sample with
-- rising edge as defined in basic buffer bit component (buffer_bit).
proc_in_sclk_pos:
sclk_pos <= i_sclk_2clkd xor C_SPI_SCLK_CNT_2CLKD_CPOL;


-- Component instantiation -----------------------------------------------------
spi_sclk_cnt_pos_edge_unit: spi_count_mod_m_2clkd
  generic map (
    M            => SPI_FRM_LEN,
    INIT         => C_SPI_SCLK_CNT_2CLKD_EDGE_CNT_INIT,
    DIR          => C_SPI_SCLK_CNT_2CLKD_EDGE_CNT_DIR
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst        => i_rst,
    i_clr        => i_csel_fall,
    i_sclk_2clkd => sclk_pos,
    i_tck_2clkd  => i_csel_2clkd,
    -- Output ports ------------------------------------------------------------
    o_cnt_2clkd  => sclk_pos_cnt
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI clock negative edge counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------

-- Negative SPI clock edge counter control clock
-- Translate SPI clock based on clock polarity and clock phase to sample with
-- rising edge as defined in basic buffer bit component (buffer_bit).
proc_in_sclk_neg:
sclk_neg <= i_sclk_2clkd xor (not(C_SPI_SCLK_CNT_2CLKD_CPOL));

-- Component instantiation -----------------------------------------------------
spi_sclk_cnt_neg_edge_unit: spi_count_mod_m_2clkd
  generic map (
    M            => SPI_FRM_LEN,
    INIT         => C_SPI_SCLK_CNT_2CLKD_EDGE_CNT_INIT,
    DIR          => C_SPI_SCLK_CNT_2CLKD_EDGE_CNT_DIR
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_rst        => i_rst,
    i_clr        => i_csel_fall,
    i_sclk_2clkd => sclk_neg,
    i_tck_2clkd  => i_csel_2clkd,
    -- Output ports ------------------------------------------------------------
    o_cnt_2clkd  => sclk_neg_cnt
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Common output signal assignments
--------------------------------------------------------------------------------

-- SPI clock edge counting
proc_out_o_sclk_cnt_2clkd:
o_sclk_cnt_2clkd <= '1' when (unsigned(sclk_pos_cnt) /= C_SPI_SCLK_CNT_2CLKD_EDGE_ZERO_CMP)
               else '1' when (unsigned(sclk_neg_cnt) /= C_SPI_SCLK_CNT_2CLKD_EDGE_ZERO_CMP)
               else '0';

-- SPI leading clock edge flag
proc_out_o_sclk_lead_2clkd:
o_sclk_lead_2clkd <= '1' when (unsigned(sclk_pos_cnt) = C_SPI_SCLK_CNT_2CLKD_EDGE_ONE_CMP)
                else '0';

-- SPI trailing clock edge flag
proc_out_o_sclk_trail_2clkd:
o_sclk_trail_2clkd <= '1' when (unsigned(sclk_neg_cnt) = C_SPI_SCLK_CNT_2CLKD_EDGE_ZERO_CMP)
                 else '0';

end architecture rtl;