--------------------------------------------------------------------------------
-- File: spi_ctrl_core.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-19 #$: Date of last commit
-- $Rev:: 11           $: Revision of last commit
--
-- Open Points/Remarks:
--  + Level of constant C_SPI_CTRL_CORE_EDGE_DETECT_INIT to be checked against
--    different SPI modes
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
library spi;
  use spi.spi_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_ctrl_core is
  generic (
    SPI_FRM_LEN   : natural         := 8;             -- SPI frame length (number of bits)
    SPI_CTRL_MODE : spi_ctrl_mode_t := CPOL0_CPHA0    -- SPI control mode
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys         : in  sys_ctrl_t;                   -- System control
    i_csel        : in  std_logic;                    -- SPI chip select
    i_sclk        : in  std_logic;                    -- SPI clock
    -- Output ports ------------------------------------------------------------
    o_err_sclk    : out std_logic;                    -- SPI clock error
    o_shift_mode  : out spi_shift_mode_t              -- SPI shift register mode
  );
end entity spi_ctrl_core;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture structural of spi_ctrl_core is
  -- Constants -----------------------------------------------------------------
  constant C_SPI_CTRL_CORE_EDGE_DETECT_LEN  : natural                                                      := 3;
  constant C_SPI_CTRL_CORE_EDGE_DETECT_INIT : std_logic_vector(C_SPI_CTRL_CORE_EDGE_DETECT_LEN-1 downto 0) := (others => set_sclk_level(SPI_CTRL_MODE));  -- TODO:: Check correct level of signal
  constant C_CPI_CTRL_CORE_SCLK_CNT_MODULO  : natural                                                      := (2*SPI_FRM_LEN)+1;
  constant C_SPI_CTRL_CORE_SCLK_CNT_INIT    : natural                                                      := 0;
  -- Types ---------------------------------------------------------------------
  -- (none)
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal sclk_edges   : signal_edge_t := (others => '0');   -- SPI clock edges (rising/falling)
  signal sclk_cnt_clr : std_logic     := '1';               -- SPI clock counter clear
  signal sclk_cnt_tck : std_logic     := '0';               -- SPI clock counter tick
  signal sclk_cnt_ovr : std_logic     := '0';               -- SPI clock counter overflow
  -- Attributes ----------------------------------------------------------------
  -- (none)
begin

-- Assertions ------------------------------------------------------------------
--assert SPI_FRM_LEN > 2
--  report "SPI_FRM_LEN <= 2!  SPI frame lenght must be greater than or equal to 3."
--  severity failure;

--------------------------------------------------------------------------------
-- SPI clock signal edges(s) detector
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
gen_spi_sclk_edges_unit:
for i in edge_dir_t generate
  spi_sclk_edge_unit: detect_edge
    generic map (
      LEN    => C_SPI_CTRL_CORE_EDGE_DETECT_LEN,
      INIT   => C_SPI_CTRL_CORE_EDGE_DETECT_INIT,
      DIR    => edge_dir_t(i)
    )
    port map (
      -- Input ports -----------------------------------------------------------
      i_sys  => i_sys,
      i_sdi  => i_sclk,
      -- Output ports ----------------------------------------------------------
      o_edge => sclk_edges(i)
    );
end generate;

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI shift register control sequencer
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_ctrl_seq_unit: spi_ctrl_seq
  generic map (
    SPI_CTRL_MODE => SPI_CTRL_MODE
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys        => i_sys,
    i_csel       => i_csel,
    i_sclk_edges => sclk_edges,
    i_cnt_ovr    => sclk_cnt_ovr,
    -- Output ports ------------------------------------------------------------
    o_cnt_clr    => sclk_cnt_clr,
    o_cnt_tck    => sclk_cnt_tck,
    o_err_sclk   => o_err_sclk,
    o_shift_mode => o_shift_mode
  );

-- Output logic ----------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI clock edge(s) counter
--------------------------------------------------------------------------------

-- Input logic -----------------------------------------------------------------
-- (none)

-- Component instantiation -----------------------------------------------------
spi_sclk_cnt_unit: divide_mod_m
  generic map (
    M     => C_CPI_CTRL_CORE_SCLK_CNT_MODULO,
    INIT  => C_SPI_CTRL_CORE_SCLK_CNT_INIT,
    DIR   => UP
  )
  port map (
    -- Input ports -------------------------------------------------------------
    i_sys => i_sys,
    i_clr => sclk_cnt_clr,
    i_tck => sclk_cnt_tck,
    -- Output ports ------------------------------------------------------------
    o_div => sclk_cnt_ovr
  );

-- Output logic ----------------------------------------------------------------
-- (none)

end architecture structural;