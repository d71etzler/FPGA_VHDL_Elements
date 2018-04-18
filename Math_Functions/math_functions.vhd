--------------------------------------------------------------------------------
-- File: math_functions.vhd
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

--------------------------------------------------------------------------------
-- Package declarations
--------------------------------------------------------------------------------
package math_functions is

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

-- Log base 2 ------------------------------------------------------------------
function clogb2 (
  a : positive  -- Input number
) return natural;

-- Integer division rounded-up -------------------------------------------------
function cdivintur (
  a : natural;  -- Dividend input number
  d : positive  -- Divisor input number
) return natural;

-- Minimum of two integers -----------------------------------------------------
function minimum (
  a : integer;  -- Integer number a
  b : integer   -- Integer number b
) return integer;

-- Maximum of two integers -----------------------------------------------------
function maximum (
  a : integer;  -- Integer number a
  b : integer   -- Integer number b
) return integer;

end package math_functions;

--------------------------------------------------------------------------------
-- Package definitions
--------------------------------------------------------------------------------
package body math_functions is

--------------------------------------------------------------------------------
-- Log base 2
--------------------------------------------------------------------------------
function clogb2 (
  a : positive
) return natural is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  return integer(ceil(log2(real(a))));
end function clogb2;

--------------------------------------------------------------------------------
-- Integer division rounded-up (result rounded up to next bigger integer)
--------------------------------------------------------------------------------
function cdivintur (
  a : natural;
  d : positive
) return natural is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  return integer(ceil(real(a)/real(d)));
end function cdivintur;

--------------------------------------------------------------------------------
-- Minimum of two integers
--------------------------------------------------------------------------------
function minimum (
  a : integer;
  b : integer
) return integer is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  if (a <= b) then
    return a;
  else
    return b;
  end if;
end function minimum;

--------------------------------------------------------------------------------
-- Maximum of two integers
--------------------------------------------------------------------------------
function maximum (
  a : integer;
  b : integer
) return integer is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Variables -----------------------------------------------------------------
  -- (none)
  -- Assertions ----------------------------------------------------------------
  -- (none)
begin
  if (a >= b) then
    return a;
  else
    return b;
  end if;
end function maximum;

end package body math_functions;