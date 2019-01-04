--------------------------------------------------------------------------------
-- File: spi_elements_2clkd.vhd
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
library math;
  use math.math_functions.all;
  use math.logic_functions.all;

--------------------------------------------------------------------------------
-- Package declarations
--------------------------------------------------------------------------------
package spi_elements_2clkd is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------

-- Enumerated SPI clock polarity -----------------------------------------------
type spi_clk_pol_t  is (
  CPOL0,  -- Clock polarity = 0
  CPOL1   -- Clock polarity = 1
);

-- Enumerated SPI clock phase --------------------------------------------------
type spi_clk_phs_t is (
  CPHA0,  -- Clock phase = 0
  CPHA1   -- Clock phase = 1
);

-- Enumerated SPI shift directions ---------------------------------------------
type spi_shift_dir_t is (
  LSB,  -- Least significant bit first
  MSB   -- Most significant bit first
);

-- Enumerated SPI parity variant -----------------------------------------------
type spi_parity_var_t is (
  ODD,    -- Odd number of ones expected in data
  EVEN    -- Even number of data expected in data
);

--------------------------------------------------------------------------------
-- User functions
--------------------------------------------------------------------------------

-- Get clock polarity ----------------------------------------------------------
function get_clk_pol (
  cpol : spi_clk_pol_t      -- Clock polarity
) return std_logic;

-- Get shift register direction ------------------------------------------------
function get_shift_dir (
  dir : spi_shift_dir_t     -- SPI shift direction
) return shift_dir_t;

-- Get sample register content -------------------------------------------------
function get_sample_reg (
  data : std_logic_vector;  -- SPI shift data content
  dir  : spi_shift_dir_t    -- SPI shift direction
) return std_logic;

-- Get shift register content --------------------------------------------------
function get_shift_reg (
  data : std_logic_vector;  -- SPI shift data content
  dir  : spi_shift_dir_t    -- SPI shift direction
) return std_logic_vector;

-- Get parity bit --------------------------------------------------------------
function get_parity (
  data : std_logic_vector;    -- SPI message data
  par  : spi_parity_var_t     -- SPI parity variant (odd/even)
) return std_logic;

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------

-- SPI IO-synchronization ------------------------------------------------------
component spi_io_sync_2clkd is
  generic (
    SPI_FRM_LEN   : natural;
    SPI_GUARD_LEN : natural;
    SPI_CSEL_INIT : std_logic;
    SPI_SCNT_INIT : std_logic;
    SPI_PDI_INIT  : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst         : in  std_logic;
    i_clk         : in  std_logic;
    i_csel_a      : in  std_logic;
    i_sclk_cnt_a  : in  std_logic;
    i_pdi_a       : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_csel        : out std_logic;
    o_sclk_cnt    : out std_logic;
    o_pdi         : out std_logic_vector(SPI_FRM_LEN-1 downto 0)
  );
end component spi_io_sync_2clkd;

-- SPI chip select edge detection ----------------------------------------------
component spi_csel_edge_2clkd is
  port (
    -- Input ports -------------------------------------------------------------
    i_sys       : in  sys_ctrl_t;
    i_csel      : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_csel_rise : out std_logic;
    o_csel_fall : out std_logic
  );
end component spi_csel_edge_2clkd;

-- SPI clock edge counter with asynchronous clear ------------------------------
component spi_count_mod_m_2clkd is
  generic (
    M            : natural;
    INIT         : natural;
    DIR          : cnt_dir_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst        : in  std_logic;
    i_clr        : in  std_logic;
    i_sclk_2clkd : in  std_logic;
    i_tck_2clkd  : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_cnt_2clkd  : out std_logic_vector(clogb2(M)-1 downto 0)
  );
end component spi_count_mod_m_2clkd;

-- SPI clock edge counter ------------------------------------------------------
component spi_sclk_cnt_2clkd is
  generic (
    SPI_FRM_LEN        : natural;
    SPI_CLK_POL        : spi_clk_pol_t
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst              : in  std_logic;
    i_csel_fall        : in  std_logic;
    i_sclk_2clkd       : in  std_logic;
    i_csel_2clkd       : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_sclk_cnt_2clkd   : out std_logic;
    o_sclk_lead_2clkd  : out std_logic;
    o_sclk_trail_2clkd : out std_logic
  );
end component spi_sclk_cnt_2clkd;

-- SPI shift register ----------------------------------------------------------
component spi_shift_reg_2clkd is
  generic (
    SPI_FRM_LEN      : natural;
    SPI_CLK_POL      : spi_clk_pol_t;
    SPI_SHIFT_DIR    : spi_shift_dir_t;
    SPI_SHIFT_INIT   : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_rst            : in  std_logic;
    i_sclk_2clkd     : in  std_logic;
    i_csel_2clkd     : in  std_logic;
    i_sdi_2clkd      : in  std_logic;
    i_pdo_load_2clkd : in  std_logic;
    i_pdo_2clkd        : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd      : out std_logic;
    o_pdi_2clkd      : out std_logic_vector(SPI_FRM_LEN-1 downto 0)
  );
end component spi_shift_reg_2clkd;

-- SPI frame parity check ------------------------------------------------------
component spi_frm_chk_2clkd is
  generic (
    SPI_FRM_LEN  : natural;
    SPI_PAR_VAR  : spi_parity_var_t;
    SPI_MDI_INIT : std_logic_vector;
    SPI_ERR_SCLK : std_logic_vector;
    SPI_ERR_PAR  : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys        : in  sys_ctrl_t;
    i_csel_fall  : in  std_logic;
    i_sclk_cnt   : in  std_logic;
    i_pdi        : in  std_logic_vector(SPI_FRM_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_mdi_load_s : out std_logic;
    o_mdi        : out std_logic_vector(SPI_FRM_LEN-2 downto 0)
  );
end component spi_frm_chk_2clkd;

-- SPI frame parity build ------------------------------------------------------
component spi_frm_bld_2clkd is
  generic (
    SPI_FRM_LEN      : natural;
    SPI_PAR_VAR      : spi_parity_var_t;
    SPI_MDO_INIT     : std_logic_vector;
    SPI_ERR_OVRN     : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys            : in  sys_ctrl_t;
    i_csel           : in  std_logic;
    i_csel_rise      : in  std_logic;
    i_sclk_cnt       : in  std_logic;
    i_mdo_load_s     : in  std_logic;
    i_mdo            : in  std_logic_vector(SPI_FRM_LEN-2 downto 0);
    i_sclk_cnt_2clkd : in  std_logic;
    -- Output ports ------------------------------------------------------------
    o_pdo_load       : out std_logic;
    o_pdo            : out std_logic_vector(SPI_FRM_LEN-1 downto 0)
  );
end component spi_frm_bld_2clkd;

-- SPI engine ------------------------------------------------------------------
component spi_engine_2clkd is
  generic (
    SPI_MSG_LEN   : natural;
    SPI_CLK_POL   : spi_clk_pol_t;
    SPI_SHIFT_DIR : spi_shift_dir_t;
    SPI_PAR_VAR   : spi_parity_var_t;
    SPI_MSG_INIT  : std_logic_vector;
    SPI_ERR_SCLK  : std_logic_vector;
    SPI_ERR_PAR   : std_logic_vector;
    SPI_ERR_OVRN  : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys         : in  sys_ctrl_t;
    i_sclk_2clkd  : in  std_logic;
    i_csel_2clkd  : in  std_logic;
    i_sdi_2clkd   : in  std_logic;
    i_mdo_load_s  : in  std_logic;
    i_mdo         : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd   : out std_logic;
    o_mdi_load_s  : out std_logic;
    o_mdi         : out std_logic_vector(SPI_MSG_LEN-1 downto 0)
  );
end component spi_engine_2clkd;

-- SPI slave -------------------------------------------------------------------
component spi_slave_2clkd is
  generic (
    SPI_MSG_LEN    : natural;
    SPI_CLK_POL    : spi_clk_pol_t;
    SPI_SHIFT_DIR  : spi_shift_dir_t;
    SPI_PAR_VAR    : spi_parity_var_t;
    SPI_MSG_INIT   : std_logic_vector;
    SPI_ERR_SCLK   : std_logic_vector;
    SPI_ERR_PAR    : std_logic_vector;
    SPI_ERR_OVRN   : std_logic_vector
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys          : in  sys_ctrl_t;
    i_sclk_2clkd   : in  std_logic;
    i_csel_2clkd_n : in  std_logic;
    i_sdi_2clkd    : in  std_logic;
    i_mdo_load_s   : in  std_logic;
    i_mdo_data     : in  std_logic_vector(SPI_MSG_LEN-1 downto 0);
    -- Output ports ------------------------------------------------------------
    o_sdo_2clkd_t  : out std_logic;
    o_mdi_load_s   : out std_logic;
    o_mdi_data     : out std_logic_vector(SPI_MSG_LEN-1 downto 0)
  );
end component spi_slave_2clkd;

end package spi_elements_2clkd;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body spi_elements_2clkd is

--------------------------------------------------------------------------------
-- Get clock polarity
-- Translate enumerated clock polarity into std_logic value.
--------------------------------------------------------------------------------
function get_clk_pol (
  cpol : spi_clk_pol_t
) return std_logic is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  if (cpol = CPOL0) then
    return '0';   -- Clock polarity (CPOL0)
  else
    return '1';   -- Clock polarity (CPOL1)
  end if;
end function get_clk_pol;

--------------------------------------------------------------------------------
-- Get shift register direction
-- Translate enumerated SPI shift direction into basic shift register shift
-- direction.
--------------------------------------------------------------------------------
function get_shift_dir (
  dir : spi_shift_dir_t
) return shift_dir_t is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  if (dir = LSB) then
    return RSHIFT;    -- SPI shift direction: LSB
  else
    return LSHIFT;    -- SPI shift direction: MSB
  end if;
end function get_shift_dir;

--------------------------------------------------------------------------------
-- Get sample register content
--------------------------------------------------------------------------------
function get_sample_reg (
  data : std_logic_vector;
  dir  : spi_shift_dir_t
) return std_logic is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  if (dir = LSB) then
    return data(data'high);   -- SPI shift direction: LSB
  else
    return data(data'low);    -- SPI shift direction: MSB
  end if;
end function get_sample_reg;

--------------------------------------------------------------------------------
-- Get shift register content
--------------------------------------------------------------------------------
function get_shift_reg (
  data : std_logic_vector;
  dir  : spi_shift_dir_t
) return std_logic_vector is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  if (dir = LSB) then
    return data((data'high)-1 downto (data'low)) & '0';   -- SPI shift direction: LSB
  else
    return '0' & data((data'high) downto (data'low)+1);   -- SPI shift direction: MSB
  end if;
end function get_shift_reg;

--------------------------------------------------------------------------------
-- Get parity of data
-- Returns necessary parity bit value for given data and parity variant
--------------------------------------------------------------------------------
function get_parity (
  data : std_logic_vector;
  par  : spi_parity_var_t
) return std_logic is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  if (par = ODD) then
    return not(xor_reduce(data));
  else
    return xor_reduce(data);
  end if;
end function get_parity;

end package body spi_elements_2clkd;