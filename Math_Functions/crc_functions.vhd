--------------------------------------------------------------------------------
-- File: crc_functions.vhd
--
-- !THIS FILE IS UNDER REVISION CONTROL!
--
-- $Author:: uid03580  $: Author of last commit
-- $Date:: 2016-08-09 #$: Date of last commit
-- $Rev:: 4            $: Revision of last commit
--
-- Open Points/Remarks:
--  Configuration of CRC bit position as function parameter
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Used library definitions
--------------------------------------------------------------------------------
library ieee;
  use ieee.numeric_std.all;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
library math;
  use math.math_functions.all;
  use math.logic_functions.all;

--------------------------------------------------------------------------------
-- Package declarations
--------------------------------------------------------------------------------
package crc_functions is

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

-- Build CRC hardware ----------------------------------------------------------
function build_crc (
  data    : std_logic_vector;   -- Input data (CRC to be applied to)
  polynom : std_logic_vector    -- CRC polynom (without leading '1')
) return std_logic_vector;      -- CRC remainder for building hardware

-- Get CRC remainder -----------------------------------------------------------
function get_crc (
  data    : std_logic_vector;   -- Input data (CRC to be applied to)
  polynom : std_logic_vector    -- CRC polynom (without leading '1')
) return std_logic_vector;      -- CRC_ remainder

-- Append CRC remainder to data ------------------------------------------------
function append_crc (
  data    : std_logic_vector;   -- Input data (CRC to be applied to)
  polynom : std_logic_vector    -- CRC polynom (without leading '1')
) return std_logic_vector;      -- Data appended by CRC remainder

end package crc_functions;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body crc_functions is

--------------------------------------------------------------------------------
-- Build CRC hardware
--------------------------------------------------------------------------------
function build_crc (
  data    : std_logic_vector;
  polynom : std_logic_vector
) return std_logic_vector is
  -- Constants -----------------------------------------------------------------
  -- Due to the unconstraint definition of the function parameters the standard
  -- logic vector direction (e.g. downto or to) is not defined.  The function
  -- is defined for "downto" standard logic vector direction only.  Thus ,the
  -- constant definitions force the function parameters to be used in "downto"
  -- standard logic vector direction.
  -- Unconstraint function parameter definition has been selected to allow
  -- universal definition of the function for all lengths of standard logic
  -- vectors.
  constant C_BUILD_CRC_DATA_LEN : natural                                           := data'length;
  constant C_BUILD_CRC_POLY_LEN : natural                                           := polynom'length;
  constant C_BUILD_CRC_DATA     : std_logic_vector(C_BUILD_CRC_DATA_LEN-1 downto 0) := data;
  constant C_BUILD_CRC_POLY     : std_logic_vector(C_BUILD_CRC_POLY_LEN-1 downto 0) := polynom;
  -- Variables -----------------------------------------------------------------
  variable crc  : std_logic_vector(C_BUILD_CRC_POLY_LEN-1 downto 0) := (others => '1');     -- Set to '1' for odd parity; set to '0' for even parity
  variable mask : std_logic_vector(C_BUILD_CRC_POLY_LEN-1 downto 0) := (others => '0');
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  -- Build CRC hardware block
  -- Reference design RD1105 (Cyclic Redundancy Check, April 2011) from Lattice
  -- Semiconductor Corporation applied
  for i in (C_BUILD_CRC_DATA_LEN-1) downto 0 loop
    mask := (others => (crc(C_BUILD_CRC_POLY_LEN-1) xor C_BUILD_CRC_DATA(i)));
    crc := (crc(C_BUILD_CRC_POLY_LEN-2 downto 0) & '0') xor (mask and C_BUILD_CRC_POLY);
  end loop;
  -- Return calculated CRC hardware
  return crc;
end function build_crc;

--------------------------------------------------------------------------------
-- Get CRC remainder
--------------------------------------------------------------------------------
function get_crc (
  data    : std_logic_vector;
  polynom : std_logic_vector
) return std_logic_vector is
  -- Constants -----------------------------------------------------------------
  -- Due to the unconstraint definition of the function parameters the standard
  -- logic vector direction (e.g. downto or to) is not defined.  The function
  -- is defined for "downto" standard logic vector direction only.  Thus ,the
  -- constant definitions force the function parameters to be used in "downto"
  -- standard logic vector direction.
  -- Unconstraint function parameter definition has been selected to allow
  -- universal definition of the function for all lengths of standard logic
  -- vectors.
  constant C_GET_CRC_DATA_LEN : natural                                         := data'length;
  constant C_GET_CRC_POLY_LEN : natural                                         := polynom'length;
  constant C_GET_CRC_APND_LEN : natural                                         := data'length+polynom'length;
  constant C_GET_CRC_DATA     : std_logic_vector(C_GET_CRC_DATA_LEN-1 downto 0) := data;
  constant C_GET_CRC_POLY     : std_logic_vector(C_GET_CRC_POLY_LEN-1 downto 0) := polynom;
  constant C_GET_CRC_INIT     : std_logic_vector(C_GET_CRC_POLY_LEN-1 downto 0) := (others => '1');                   -- Set to '1' for odd parity; set to '0' for even parity
  constant C_GET_CRC_APND     : std_logic_vector(C_GET_CRC_APND_LEN-1 downto 0) := C_GET_CRC_DATA & C_GET_CRC_INIT;
  -- Variables -----------------------------------------------------------------
  variable flag : std_logic := '0';
  variable crc  : std_logic_vector(C_GET_CRC_POLY_LEN-1 downto 0) := C_GET_CRC_APND(C_GET_CRC_APND_LEN-1 downto C_GET_CRC_APND_LEN-C_GET_CRC_POLY_LEN);
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  -- Calculate CRC remainder using CRC polynom division
  for i in (C_GET_CRC_APND_LEN-C_GET_CRC_POLY_LEN-1) downto 0 loop
    flag := crc(C_GET_CRC_POLY_LEN-1);
    crc := crc(C_GET_CRC_POLY_LEN-2 downto 0) & C_GET_CRC_APND(i);
    if (flag = '1') then
      crc := crc xor C_GET_CRC_POLY;
    end if;
  end loop;
  -- Return calculated CRC remainder
  return crc;
end function get_crc;

--------------------------------------------------------------------------------
-- Append CRC remainder to data
--------------------------------------------------------------------------------
function append_crc (
  data    : std_logic_vector;
  polynom : std_logic_vector
) return std_logic_vector is
  -- Constants -----------------------------------------------------------------
  -- Due to the unconstraint definition of the function parameters the standard
  -- logic vector direction (e.g. downto or to) is not defined.  The function
  -- is defined for "downto" standard logic vector direction only.  Thus ,the
  -- constant definitions force the function parameters to be used in "downto"
  -- standard logic vector direction.
  -- Unconstraint function parameter definition has been selected to allow
  -- universal definition of the function for all lengths of standard logic
  -- vectors.
  constant C_APPEND_CRC_DATA_LEN : natural                                            := data'length;
  constant C_APPEND_CRC_POLY_LEN : natural                                            := polynom'length;
  constant C_APPEND_CRC_DATA     : std_logic_vector(C_APPEND_CRC_DATA_LEN-1 downto 0) := data;
  constant C_APPEND_CRC_POLY     : std_logic_vector(C_APPEND_CRC_POLY_LEN-1 downto 0) := polynom;
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  -- Return data appended by CRC remainder at MSB position
  return (get_crc(C_APPEND_CRC_DATA, C_APPEND_CRC_POLY) & C_APPEND_CRC_DATA);
  -- Return data appended by CRC remainder at LSB position
  --return (C_APPEND_CRC_DATA & get_crc(C_APPEND_CRC_DATA, C_APPEND_CRC_POLY));
end function append_crc;

end package body crc_functions;