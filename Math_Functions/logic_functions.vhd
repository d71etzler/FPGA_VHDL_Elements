--------------------------------------------------------------------------------
-- File: logic_functions.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-09 #$: Date of last commit
-- $Rev:: 4            $: Revision of last commit
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
  use ieee.math_real.all;
library basic;
  use basic.basic_elements.all;
library math;
  use math.math_functions.all;

--------------------------------------------------------------------------------
-- Package declarations
--------------------------------------------------------------------------------
package logic_functions is

--------------------------------------------------------------------------------
-- User constants
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Type declarations
--------------------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- Function declarations
--------------------------------------------------------------------------------

-- AND vector reduction --------------------------------------------------------
function and_reduce (
  bvec : std_logic_vector   -- Input data vector
) return std_logic;

-- OR vector reduction ---------------------------------------------------------
function or_reduce (
  bvec : std_logic_vector   -- Input data vector
) return std_logic;

-- XOR vector reduction --------------------------------------------------------
function xor_reduce (
  bvec : std_logic_vector   -- Input data vector
) return std_logic;

-- NAND vector reduction -------------------------------------------------------
function nand_reduce (
  bvec : std_logic_vector   -- Input data vector
) return std_logic;

-- NOR vector reduction --------------------------------------------------------
function nor_reduce (
  bvec : std_logic_vector   -- Input data vector
) return std_logic;

-- Transpose bit vector --------------------------------------------------------
function transpose_bvec (
  bvec : std_logic_vector   -- Input bit vector
) return std_logic_vector;

-- Multiplex bit vector with binary-coded selection signal ---------------------
function mux_bin_sel (
  sel  : std_logic_vector;  -- Binary multiplexer selection
  bvec : std_logic_vector   -- Input data vector
) return std_logic;

-- Multiplex standard logic vector with one-hot-coded selection ----------------
function mux_bvec_one_sel (
  sel  : std_logic_vector;  -- One-hot multiplexer selection
  bvec : std_logic_vector   -- Input data vector
) return std_logic;

-- Multiplex standard logic array across rows with one-hot-coded selection -----
function mux_bary_one_sel (
  sel  : std_logic_vector;    -- One-hot multiplexer selection
  bary : std_logic_array2d_t  -- Input data bit array (COL, ROW)
) return std_logic_vector;

-- Decode binary number to one-hot-coded selection -----------------------------
function dcd_bin_onehot (
  bvec : std_logic_vector   -- Binary coded number
) return std_logic_vector;

end package logic_functions;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body logic_functions is

--------------------------------------------------------------------------------
-- AND vector reduction
--------------------------------------------------------------------------------
function and_reduce (
  bvec : std_logic_vector
) return std_logic is
  -- Constants -----------------------------------------------------------------
  constant C_STAGE_NUM : natural := clogb2(bvec'length);
  -- Variables -----------------------------------------------------------------
  variable stages : std_logic_array2d_t(C_STAGE_NUM downto 0, (2**C_STAGE_NUM)-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
  -- (none)
  -- Re-assign input vector and pad remaining inputs ---------------------------
  for i in 0 to ((2**C_STAGE_NUM)-1) loop
    if (i < bvec'length) then
      stages(C_STAGE_NUM,i) := bvec(i);
    else
      stages(C_STAGE_NUM,i) := '1';
    end if;
  end loop;
  -- Logical AND of neighbouring lines across all stages -----------------------
  for i in (C_STAGE_NUM-1) downto 0 loop
    for j in 0 to ((2**i)-1) loop
      stages(i,j) := (stages(i+1,2*j)) and (stages(i+1,(2*j)+1));
    end loop;
  end loop;
  -- Return reduced AND result -------------------------------------------------
  return stages(0,0);
end function and_reduce;

--------------------------------------------------------------------------------
-- OR vector reduction
--------------------------------------------------------------------------------
function or_reduce (
  bvec : std_logic_vector
) return std_logic is
  -- Constants -----------------------------------------------------------------
  constant C_STAGE_NUM : natural := clogb2(bvec'length);
  -- Variables -----------------------------------------------------------------
  variable stages : std_logic_array2d_t(C_STAGE_NUM downto 0, (2**C_STAGE_NUM)-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
  -- (none)
  -- Re-assign input vector and pad remaining inputs ---------------------------
  for i in 0 to ((2**C_STAGE_NUM)-1) loop
    if (i < bvec'length) then
      stages(C_STAGE_NUM,i) := bvec(i);
    else
      stages(C_STAGE_NUM,i) := '0';
    end if;
  end loop;
  -- Logical OR of neighbouring lines across all stages ------------------------
  for i in (C_STAGE_NUM-1) downto 0 loop
    for j in 0 to ((2**i)-1) loop
      stages(i,j) := (stages(i+1,2*j)) or (stages(i+1,(2*j)+1));
    end loop;
  end loop;
  -- Return reduced OR result --------------------------------------------------
  return stages(0,0);
end function or_reduce;

--------------------------------------------------------------------------------
-- XOR vector reduction
--------------------------------------------------------------------------------
function xor_reduce (
  bvec : std_logic_vector
) return std_logic is
  -- Constants -----------------------------------------------------------------
  constant C_STAGE_NUM : natural := clogb2(bvec'length);
  -- Variables -----------------------------------------------------------------
  variable stages : std_logic_array2d_t(C_STAGE_NUM downto 0, (2**C_STAGE_NUM)-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
  -- (none)
  -- Re-assign input vector and pad remaining inputs ---------------------------
  for i in 0 to ((2**C_STAGE_NUM)-1) loop
    if (i < bvec'length) then
      stages(C_STAGE_NUM,i) := bvec(i);
    else
      stages(C_STAGE_NUM,i) := '0';
    end if;
  end loop;
  -- Logical XOR of neighbouring lines across all stages -----------------------
  for i in (C_STAGE_NUM-1) downto 0 loop
    for j in 0 to ((2**i)-1) loop
      stages(i,j) := (stages(i+1,2*j)) xor (stages(i+1,(2*j)+1));
    end loop;
  end loop;
  -- Return reduced XOR result -------------------------------------------------
  return stages(0,0);
end function xor_reduce;

--------------------------------------------------------------------------------
-- NAND vector reduction
--------------------------------------------------------------------------------
function nand_reduce (
  bvec : std_logic_vector
) return std_logic is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
begin
  -- Assertions ----------------------------------------------------------------
  -- (none)
  return not(and_reduce(bvec));
end function nand_reduce;

--------------------------------------------------------------------------------
-- NOR vector reduction
--------------------------------------------------------------------------------
function nor_reduce (
  bvec : std_logic_vector
) return std_logic is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
begin
  -- Assertions ----------------------------------------------------------------
  -- (none)
  return not(or_reduce(bvec));
end function nor_reduce;

--------------------------------------------------------------------------------
-- Transpose bit vector
--------------------------------------------------------------------------------
function transpose_bvec (
  bvec : std_logic_vector
) return std_logic_vector is
  -- Constants -----------------------------------------------------------------
  constant C_BVEC_LEN : natural := bvec'length;
  -- Variables -----------------------------------------------------------------
  variable bvec_buf : std_logic_vector(C_BVEC_LEN-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
  -- (none)
  -- Transpose bit vector ------------------------------------------------------
  for i in C_BVEC_LEN-1 downto 0 loop
    bvec_buf(i) := bvec((C_BVEC_LEN-1)-i);
  end loop;
  -- Return transposed result --------------------------------------------------
  return bvec_buf;
end transpose_bvec;

--------------------------------------------------------------------------------
-- Multiplex bit vector with binary-coded selection signal
--------------------------------------------------------------------------------
function mux_bin_sel (
  sel  : std_logic_vector;
  bvec : std_logic_vector
) return std_logic is
  -- Constants -----------------------------------------------------------------
  constant C_STAGE_NUM : natural := clogb2(bvec'length);
  -- Variables -----------------------------------------------------------------
  variable stages : std_logic_array2d_t(C_STAGE_NUM downto 0, (2**C_STAGE_NUM)-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
--  assert bvec'length <= 2**sel'length
--    report "Bit vector length > Selection vector!"
--    severity failure;
  -- Re-assign input vector and pad remaining inputs ---------------------------
  for i in 0 to ((2**C_STAGE_NUM)-1) loop
    if (i < bvec'length) then
      stages(C_STAGE_NUM,i) := bvec(i);
    else
      stages(C_STAGE_NUM,i) := '0';
    end if;
  end loop;
  -- Multiplex neighbouring lines across all stages ----------------------------
  for i in (C_STAGE_NUM-1) downto 0 loop
    for j in 0 to ((2**i)-1) loop
      if (sel((C_STAGE_NUM-1)-i) = '0') then
        stages(i,j) := stages(i+1,2*j);
      else
        stages(i,j) := stages(i+1,(2*j)+1);
      end if;
    end loop;
  end loop;
  -- Return final multiplexed result -------------------------------------------
  return stages(0,0);
end function mux_bin_sel;

--------------------------------------------------------------------------------
-- Multiplex standard logic bit vector with one-hot-coded selection
--------------------------------------------------------------------------------
function mux_bvec_one_sel (
  sel  : std_logic_vector;
  bvec : std_logic_vector
) return std_logic is
  -- Constants -----------------------------------------------------------------
  constant C_SEL_LEN : natural := sel'length;
  -- Variables -----------------------------------------------------------------
  variable mask : std_logic_vector(C_SEL_LEN-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
--  assert bvec'length <= sel'length
--    report "Bit vector length > selection vector!  One-hot selection signal does not address all choices."
--    severity failure;
  -- Re-assign input vector and pad remaining inputs ---------------------------
  for i in 0 to (C_SEL_LEN-1) loop
    if (i < bvec'length) then
      mask(i) := bvec(i) and sel(i);
    else
      mask(i) := '0';
    end if;
  end loop;
  -- Return multiplexed standard logic -----------------------------------------
  return or_reduce(mask);
end function mux_bvec_one_sel;

--------------------------------------------------------------------------------
-- Multiplex standard logic array across rows with one-hot-coded selection
-- Structure: Standard logic vector in every row of the standard logic array
--------------------------------------------------------------------------------
function mux_bary_one_sel (
  sel  : std_logic_vector;
  bary : std_logic_array2d_t
) return std_logic_vector is
  -- Constants -----------------------------------------------------------------
  constant C_SEL_LEN      : natural := sel'length;
  constant C_BARY_COL_LEN : natural := bary'length(1);
  constant C_BARY_ROW_LEN : natural := bary'length(2);
  -- Variables -----------------------------------------------------------------
  variable mvec : std_logic_vector(C_SEL_LEN-1 downto 0);
  variable bvec : std_logic_vector(C_BARY_COL_LEN-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
--  assert bary'length(2) <= sel'length
--    report "Array row length > selection vector!  One-hot selection signal does not address all choices (e.g. all rows in array)."
--    severity failure;
  -- Re-assign input array to 2d-vector and pad remaining inputs ---------------
  for i in 0 to (C_BARY_COL_LEN-1) loop
    for j in 0 to (C_SEL_LEN-1) loop
      if (j < C_BARY_ROW_LEN) then
        mvec(j) := bary(i,j);
      else
        mvec(j) := '0';
      end if;
    end loop;
    -- Multiplex column vector into result bit ---------------------------------
    bvec(i) := mux_bvec_one_sel(sel, mvec);
  end loop;
  -- Return multiplexed standard logic vector ----------------------------------
  return bvec;
end function mux_bary_one_sel;

--------------------------------------------------------------------------------
-- Decode binary number to one-hot-coded selection
--------------------------------------------------------------------------------
function dcd_bin_onehot (
  bvec : std_logic_vector
) return std_logic_vector is
  -- Constants -----------------------------------------------------------------
  constant C_STAGE_NUM : natural := bvec'length;
  -- Variables -----------------------------------------------------------------
  variable stages : std_logic_array2d_t(C_STAGE_NUM downto 0, (2**C_STAGE_NUM)-1 downto 0);
  variable onehot : std_logic_vector((2**C_STAGE_NUM)-1 downto 0);
begin
  -- Assertions ----------------------------------------------------------------
  -- (none)
  -- Leftmost stage ------------------------------------------------------------
    stages(C_STAGE_NUM,0) := '1';
  -- Middle stages -------------------------------------------------------------
  for i in (C_STAGE_NUM) downto 1 loop
    for j in 0 to ((2**(C_STAGE_NUM-i))-1) loop
      stages(i-1,2*j)   := ((not(bvec(i-1))) and (stages(i,j)));
      stages(i-1,2*j+1) := ((bvec(i-1)) and (stages(i,j)));
    end loop;
  end loop;
  -- Rightmost stage -----------------------------------------------------------
  for i in 0 to ((2**C_STAGE_NUM)-1) loop
    onehot(i) := stages(0,i);
  end loop;
  -- Return onehot standard logic vector ---------------------------------------
  return onehot;
end function dcd_bin_onehot;

end package body logic_functions;