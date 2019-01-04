--------------------------------------------------------------------------------
-- File: spi_elements.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2017-02-28 #$: Date of last commit
-- $Rev:: 33           $: Revision of last commit
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
-- Package declarations
--------------------------------------------------------------------------------
package spi_elements is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------

-- Initial SPI clock level for SPI control modes 0 and 1 -----------------------
constant C_SPI_SCLK_INIT_LEVEL_CPOL0 : std_logic := '0';

-- Initial SPI clock level for SPI control modes 2 and 3 -----------------------
constant C_SPI_SCLK_INIT_LEVEL_CPOL1 : std_logic := '1';

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------

-- Enumerated SPI CRC data transformation modes --------------------------------
type spi_crc_mode_t   is (
  UNCHANGED,              -- Data unchanged
  TRANSPOSE,              -- Data transposed
  COMPLEMENT,             -- Data complemented
  TRANSPOSE_COMPLEMENT    -- Data transposed and complemented
);

-- Enumerated SPI control mode (CPOL and CPHA) ---------------------------------
type spi_ctrl_mode_t  is (
  CPOL0_CPHA0,  -- SPI Mode 0: Clock polarity = 0, clock phase = 0
  CPOL0_CPHA1,  -- SPI Mode 1: Clock polarity = 0, clock phase = 1
  CPOL1_CPHA0,  -- SPI Mode 2: Clock polarity = 1, clock phase = 0
  CPOL1_CPHA1   -- SPI Mode 3: Clock polarity = 1, clock phase = 1
);

-- Enumerated SPI shift directions ---------------------------------------------
type spi_shift_dir_t  is (
  LSB,  -- Least significant bit first
  MSB   -- Most significant bit first
);

-- Enumerated SPI shift register modes -----------------------------------------
type spi_shift_mode_t is (
  NONE,         -- No action
  LOAD_PDO,     -- Load parallel output data
  LOAD_PDI,     -- Load parallel input data
  SAMPLE_SDI,   -- Sample serial input data
  SHIFT_DATA    -- Shift data
);

--------------------------------------------------------------------------------
-- User functions
--------------------------------------------------------------------------------

-- Set SPI clock level based on SPI mode ---------------------------------------
function set_sclk_level (
  spi_ctrl_mode : spi_ctrl_mode_t   -- SPI shift control mode
) return std_logic;

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- SPI input signal synchronization --------------------------------------------
component spi_io_sync is
  generic (
    SPI_GUARD_LEN   : natural;
    SPI_CSEL_N_INIT : std_logic;
    SPI_SCLK_INIT   : std_logic;
    SPI_SDI_INIT    : std_logic
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst           : in  std_logic;
    i_clk           : in  std_logic;
    i_csel_na       : in  std_logic;
    i_sclk_a        : in  std_logic;
    i_sdi_a         : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_csel_n        : out std_logic;
    o_sclk          : out std_logic;
    o_sdi           : out std_logic
  );
end component spi_io_sync;

-- SPI shift register ----------------------------------------------------------
component spi_shift_reg is
  generic (
    SPI_FRM_LEN    : natural;
    SPI_CTRL_MODE  : spi_ctrl_mode_t;
    SPI_SHIFT_DIR  : spi_shift_dir_t;
    SPI_SHIFT_INIT : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys          : in  sys_ctrl_t;
    i_shift_mode   : in  spi_shift_mode_t;
    i_sdi          : in  std_logic;
    i_pdo          : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_sdo          : out std_logic;
    o_pdi          : out std_logic_vector(SPI_FRM_LEN-1 downto 0)
  );
end component spi_shift_reg;

-- SPI shift register control sequencer ----------------------------------------
component spi_ctrl_seq is
  generic (
    SPI_CTRL_MODE : spi_ctrl_mode_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys         : in  sys_ctrl_t;
    i_csel        : in  std_logic;
    i_sclk_edges  : in  signal_edge_t;
    i_cnt_ovr     : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_cnt_clr     : out std_logic;
    o_cnt_tck     : out std_logic;
    o_err_sclk    : out std_logic;
    o_shift_mode  : out spi_shift_mode_t
  );
end component spi_ctrl_seq;

-- SPI control core ------------------------------------------------------------
component spi_ctrl_core is
  generic (
    SPI_FRM_LEN   : natural;
    SPI_CTRL_MODE : spi_ctrl_mode_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys         : in  sys_ctrl_t;
    i_csel        : in  std_logic;
    i_sclk        : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_err_sclk    : out std_logic;
    o_shift_mode  : out spi_shift_mode_t
  );
end component spi_ctrl_core;

-- SPI frame check -------------------------------------------------------------
component spi_frame_check is
  generic (
    SPI_FRM_LEN  : natural;
    SPI_MSG_LEN  : natural;
    SPI_CRC_POLY : std_logic_vector;
    SPI_MSG_INIT : std_logic_vector;
    SPI_ERR_SCLK : std_logic_vector;
    SPI_ERR_CRC  : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;
    i_err_sclk   : in  std_logic;
    i_shift_mode : in  spi_shift_mode_t;
    i_pdi        : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_mdi_load_s : out std_logic;
    o_mdi        : out std_logic_vector(SPI_MSG_LEN-1 downto 0)
  );
end component spi_frame_check;

-- SPI frame build -------------------------------------------------------------
component spi_frame_build is
  generic (
    SPI_FRM_LEN  : natural;
    SPI_MSG_LEN  : natural;
    SPI_CRC_POLY : std_logic_vector;
    SPI_FRM_INIT : std_logic_vector;
    SPI_ERR_OVRN : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;
    i_shift_mode : in  spi_shift_mode_t;
    i_mdo_load_s : in  std_logic;
    i_mdo        : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_pdo        : out std_logic_vector(SPI_FRM_LEN-1 downto 0)
  );
end component spi_frame_build;

-- SPI engine -----------------------------------------------------------------
component spi_engine is
  generic (
    SPI_MSG_LEN    : natural;
    SPI_CTRL_MODE  : spi_ctrl_mode_t;
    SPI_SHIFT_DIR  : spi_shift_dir_t;
    SPI_CRC_POLY   : std_logic_vector;
    SPI_SHIFT_INIT : std_logic_vector;
    SPI_FRM_INIT   : std_logic_vector;
    SPI_MSG_INIT   : std_logic_vector;
    SPI_ERR_SCLK   : std_logic_vector;
    SPI_ERR_CRC    : std_logic_vector;
    SPI_ERR_OVRN   : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys          : in  sys_ctrl_t;
    i_csel         : in  std_logic;
    i_sclk         : in  std_logic;
    i_sdi          : in  std_logic;
    i_mdo_load_s   : in  std_logic;
    i_mdo          : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_sdo          : out std_logic;
    o_mdi_load_s   : out std_logic;
    o_mdi          : out std_logic_vector(SPI_MSG_LEN-1 downto 0)
  );
end component spi_engine;

-- SPI input data handshake sequencer (SPI=>RAM) -------------------------------
component spi_hshk_din_seq is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys    : in  sys_ctrl_t;
    i_ena    : in  std_logic;
    i_load_s : in  std_logic;
    i_ack    : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_req    : out std_logic;
    o_err    : out std_logic
  );
end component spi_hshk_din_seq;

-- SPI slave -------------------------------------------------------------------
component spi_slave is
  generic (
    SPI_MSG_LEN    : natural;
    SPI_CTRL_MODE  : spi_ctrl_mode_t;
    SPI_SHIFT_DIR  : spi_shift_dir_t;
    SPI_CRC_POLY   : std_logic_vector;
    SPI_STAT_CMD   : std_logic_vector;
    SPI_STAT_ADDR  : std_logic_vector;
    SPI_SHIFT_INIT : std_logic_vector;
    SPI_FRM_INIT   : std_logic_vector;
    SPI_MSG_INIT   : std_logic_vector;
    SPI_ERR_SCLK   : std_logic_vector;
    SPI_ERR_CRC    : std_logic_vector;
    SPI_ERR_OVRN   : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys          : in  sys_ctrl_t;
    i_csel_na      : in  std_logic;
    i_sclk_a       : in  std_logic;
    i_sdi_a        : in  std_logic;
    i_mdo_load_s   : in  std_logic;
    i_mdo_data     : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_sdo_t        : out std_logic;
    o_mdi_load_s   : out std_logic;
    o_mdi_data     : out std_logic_vector(SPI_MSG_LEN-1 downto 0)
  );
end component spi_slave;

end package spi_elements;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body spi_elements is

--------------------------------------------------------------------------------
-- Set SPI clock level based on SPI mode
--------------------------------------------------------------------------------
function set_sclk_level (
  spi_ctrl_mode : spi_ctrl_mode_t
) return std_logic is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  case spi_ctrl_mode is
    when CPOL0_CPHA0 | CPOL0_CPHA1 =>
      return C_SPI_SCLK_INIT_LEVEL_CPOL0;
    when CPOL1_CPHA0 | CPOL1_CPHA1 =>
      return C_SPI_SCLK_INIT_LEVEL_CPOL1;
  end case;
end function set_sclk_level;

end package body spi_elements;