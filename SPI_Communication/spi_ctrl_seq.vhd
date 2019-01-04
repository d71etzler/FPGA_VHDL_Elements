--------------------------------------------------------------------------------
-- File: spi_ctrl_seq.vhd
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
library spi;
  use spi.spi_elements.all;

--------------------------------------------------------------------------------
-- ENTITY definition
--------------------------------------------------------------------------------
entity spi_ctrl_seq is
  generic (
    SPI_CTRL_MODE : spi_ctrl_mode_t := CPOL0_CPHA0  -- SPI control mode
  );
  port (
    -- Input ports -------------------------------------------------------------
    i_sys         : in  sys_ctrl_t;                 -- System control
    i_csel        : in  std_logic;                  -- SPI chip select
    i_sclk_edges  : in  signal_edge_t;              -- Rising/falling edge of SPI clock
    i_cnt_ovr     : in  std_logic;                  -- SPI clock counter overflow
    -- Output ports ------------------------------------------------------------
    o_cnt_clr     : out std_logic;                  -- SPI clock counter clear
    o_cnt_tck     : out std_logic;                  -- SPI clock counter tick
    o_err_sclk    : out std_logic;                  -- SPI clock error
    o_shift_mode  : out spi_shift_mode_t            -- SPI shift register mode
  );
end entity spi_ctrl_seq;

--------------------------------------------------------------------------------
-- ARCHITECTURE definition
--------------------------------------------------------------------------------
architecture rtl of spi_ctrl_seq is
  -- Constants -----------------------------------------------------------------
  -- (none)
  -- Types ---------------------------------------------------------------------
  type ctrl_state_t is (IDLE, WAIT_SCLK, TRANSFER_DATA, WAIT_CSEL);
  -- Aliases -------------------------------------------------------------------
  -- (none)
  -- Signals -------------------------------------------------------------------
  signal state_reg      : ctrl_state_t := IDLE;   -- State-machine current state
  signal state_next     : ctrl_state_t := IDLE;   -- State-machine next state
  signal sclk_edges     : std_logic    := '0';    -- OR-ed SPI clock edges (rising/falling)
  signal sdi_sample_tck : std_logic    := '0';    -- Serial data input sample tick
  signal sdi_shift_tck  : std_logic    := '0';    -- Serial data input shift tick
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
  -- FSM_ENCODING controls encoding on the state machine.  Typically, the Vivado
  -- tools choose an encoding protocol for state machines based on heuristics that
  -- do the best for the most designs.  Certain design types work better with a
  -- specific encoding protocol.
  -- FSM_ENCODING can be placed on the state machine registers.  The legal values
  -- for this are "one_hot", "sequential", "johnson", "gray", "auto", and "none".
  -- The "auto" value is the default, and allows the tool to determine best
  -- encoding.  This attribute can be set in the RTL or the XDC.
  attribute FSM_ENCODING : string;
  attribute FSM_ENCODING of state_reg : signal is "gray";
  -- FSM_SAFE_STATE instructs Vivado synthesis to insert logic into the state
  -- machine that detects there is an illegal state, then puts it into a known,
  -- good state on the next clock cycle.
  -- For example, if there were a state machine with a "one_hot" encode, and that
  -- is in a "0101" state (which is an illegal for "one_hot"), the state machine
  -- would be able to recover.  Place the FSM_SAFE_STATE attribute on the state
  -- machine registers.  You can set this attribute in either the RTL or in the
  -- XDC.
  -- The legal values for FSM_SAFE_STATE are:
  -- • "auto": Uses Hamming-3 encoding for auto-correction for one bit/flip.
  -- • "reset_state": Forces the state machine into the reset state using
  --   Hamming-2 encoding detection for one bit/flip.
  -- • "power_on_state": Forces the state machine into the power-on state using
  --   Hamming-2 encoding detection for one bit/flip.
  -- • "default_state": Forces the state machine into the default state specified
  --   in RTL: the state that is specified in "default" branch of the case
  --   statement in Verilog or the state specified in the others branch of the
  --   case statement in VHDL; even if that state is unreachable, using Hamming-2
  --   encoding detection for one bit/flip.
  attribute FSM_SAFE_STATE : string;
  attribute FSM_SAFE_STATE of state_reg : signal is "reset_state";
begin

-- Assertions ------------------------------------------------------------------
-- (none)

--------------------------------------------------------------------------------
-- SPI shift register control sequencer
--------------------------------------------------------------------------------

-- Registers -------------------------------------------------------------------
proc_register:
process(i_sys.clk)
begin
  if (rising_edge(i_sys.clk)) then
    if (i_sys.rst = '1') then
      state_reg <= IDLE;
    else
      state_reg <= state_next;
    end if;
  end if;
end process;

-- Input logic -----------------------------------------------------------------

-- ORed SCLK edges
proc_in_sclk_edges:
sclk_edges <= i_sclk_edges(RISE) or i_sclk_edges(FALL);

-- GENERATE BLOCK: SPI mode 0 (CPOL = 0, CPHA = 0) or SPI mode 3 (CPOL = 1, CPHA = 1)
-- For CPOL = 0 the base value of the clock is zero, i.e. the active state is 1
-- and idle state is 0.  With CPHA = 0, data are captured on the clock's rising
-- edge (clock transition low => high) and data is output on a falling edge
-- (clock transition high => low).
--
-- For CPOL = 1 the base value of the clock is one (inversion of CPOL = 0), i.e.
-- the active state is 0 and idle state is 1.  With CPHA = 1, data are captured
-- on clock's rising edge and data is output on a falling edge.
--
-- (That is, CPHA = 0 means sampling on the first clock edge, while CPHA = 1 means
-- sampling on the second clock edge, regardless of whether that clock edge is
-- rising or falling.  Note that with CPHA = 0, the data must be stable for a
-- half cycle before the first clock cycle.)
gen_in_spi_mode03:
if ((SPI_CTRL_MODE = CPOL0_CPHA0) or (SPI_CTRL_MODE = CPOL1_CPHA1)) generate
  sdi_sample_tck <= i_sclk_edges(RISE);
  sdi_shift_tck  <= i_sclk_edges(FALL);
end generate;

-- GENERATE BLOCK: SPI mode 1 (CPOL = 0, CPHA = 1) or SPI mode 2 (CPOL = 1, CPHA = 0)
-- For CPOL = 1 the base value of the clock is one (inversion of CPOL = 0), i.e.
-- the active state is 0 and idle state is 1.  With CPHA = 0, data are captured
-- on clock's falling edge and data is output on a rising edge.
--
-- For CPOL = 0 the base value of the clock is zero, i.e. the active state is 1
-- and idle state is 0.  With CPHA = 1, data are captured on the clock's falling
-- edge and data is output on a rising edge.
--
-- (That is, CPHA = 0 means sampling on the first clock edge, while CPHA = 1 means
-- sampling on the second clock edge, regardless of whether that clock edge is
-- rising or falling.  Note that with CPHA = 0, the data must be stable for a
-- half cycle before the first clock cycle.)
gen_in_spi_mode12:
if ((SPI_CTRL_MODE = CPOL1_CPHA0) or (SPI_CTRL_MODE = CPOL0_CPHA1)) generate
  sdi_sample_tck <= i_sclk_edges(FALL);
  sdi_shift_tck  <= i_sclk_edges(RISE);
end generate;

-- Next-state logic ------------------------------------------------------------
proc_next_state:
process(state_reg, i_sys.ena, i_sys.clr, i_csel, i_cnt_ovr, sclk_edges)
begin
  state_next <= state_reg;
  if (i_sys.ena = '1') then
    if (i_sys.clr = '1') then
      state_next <= IDLE;
    else
      case state_reg is
        -- STATE: IDLE ---------------------------------------------------------
        when IDLE =>
          if (i_csel = '1') then
            state_next <= WAIT_SCLK;
          end if;
        -- STATE: WAIT_SCLK ----------------------------------------------------
        when WAIT_SCLK =>
          if (i_csel = '0') then
            state_next <= IDLE;
          elsif (sclk_edges = '1') then
            state_next <= TRANSFER_DATA;
          end if;
        -- STATE: TRANSFER_DATA ------------------------------------------------
        when TRANSFER_DATA =>
          if (i_csel = '0') then
            state_next <= IDLE;
          elsif (i_cnt_ovr = '1') then
            state_next <= WAIT_CSEL;
          end if;
        -- STATE: WAIT_CSEL ----------------------------------------------------
        when WAIT_CSEL =>
          if (i_csel = '0') then
            state_next <= IDLE;
          elsif (sclk_edges = '1') then
            state_next <= WAIT_SCLK;
          end if;
      end case;
    end if;
  end if;
end process;

-- Output logic ----------------------------------------------------------------

-- SPI clock counter clear
proc_out_o_cnt_clr:
o_cnt_clr <= '1' when (state_reg = IDLE)
        else '0';

-- SPI clock counter tick
proc_out_o_cnt_tck:
o_cnt_tck <= '1' when (not(state_reg = IDLE) and (sclk_edges = '1'))
        else '0';

-- GENERATE BLOCK: SPI mode 0 (CPOL = 0, CPHA = 0) or SPI mode 2 (CPOL = 1, CPHA = 0)
gen_out_spi_mode02:
if ((SPI_CTRL_MODE = CPOL0_CPHA0) or (SPI_CTRL_MODE = CPOL1_CPHA0)) generate
  -- SPI shift register mode ---------------------------------------------------
  proc_out_o_shift_mode_spi_mode02:
  o_shift_mode <= LOAD_PDO   when ((state_reg = IDLE)    and (i_csel = '1'))
             else LOAD_PDI   when (not(state_reg = IDLE) and (i_csel = '0'))
             else SAMPLE_SDI when (not(state_reg = IDLE) and (sdi_sample_tck = '1'))
             else SHIFT_DATA when (not(state_reg = IDLE) and (sdi_shift_tck = '1'))
             else NONE;
  -- SPI clock error signal ----------------------------------------------------
  proc_out_o_err_sclk_spi_mode02:
  o_err_sclk <= '1' when (state_reg = WAIT_SCLK)
           else '1' when (state_reg = TRANSFER_DATA)
           else '0';
end generate;

-- GENERATE BLOCK: SPI mode 1 (CPOL = 0, CPHA = 1) or SPI mode 3 (CPOL = 1, CPHA = 1)
gen_out_spi_mode13:
if ((SPI_CTRL_MODE = CPOL0_CPHA1) or (SPI_CTRL_MODE = CPOL1_CPHA1)) generate
  -- SPI shift register mode ---------------------------------------------------
  proc_out_o_shift_mode_spi_mode13:
  o_shift_mode <= LOAD_PDO   when ((state_reg = WAIT_SCLK)     and (sdi_shift_tck = '1'))
             else LOAD_PDO   when ((state_reg = WAIT_CSEL)     and (sdi_shift_tck = '1'))
             else LOAD_PDI   when ((state_reg = TRANSFER_DATA) and (i_cnt_ovr = '1'))
             else LOAD_PDI   when ((state_reg = TRANSFER_DATA) and (i_csel = '0'))
             else SAMPLE_SDI when (not(state_reg = IDLE)       and (sdi_sample_tck = '1'))
             else SHIFT_DATA when ((state_reg = TRANSFER_DATA) and (sdi_shift_tck = '1'))
             else NONE;
  -- SPI clock error signal ----------------------------------------------------
  proc_out_o_err_sclk_spi_mode13:
  o_err_sclk <= '1' when (state_reg = WAIT_SCLK)
           else '1' when ((state_reg = TRANSFER_DATA) and (i_cnt_ovr = '0'))
           else '0';
end generate;

end architecture rtl;