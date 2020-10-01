-------------------------------------------------------
--! @file calc.vhd
--! @brief Generic register bank
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-10-01

--! Last submission: #5347
-------------------------------------------------------

-------------------------------------------------------
--! @brief Generic 1 bit demux
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;

entity demux_1b is
    generic (
        sel_size : natural := 4
    );
    port (
        a_in : in bit;
        sel : in bit_vector(sel_size-1 downto 0);
        a_out : out bit_vector(2**sel_size - 1 downto 0)
    );
end entity;

architecture demux_1b_arch of demux_1b is
begin
    process(sel, a_in)
    begin
        a_out <= (others => '0');
        a_out(to_integer(unsigned(sel))) <= a_in;
    end process;
end architecture;


-------------------------------------------------------
--! @brief Generic register with asynchronous reset
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;

entity reg is
    generic (
        wordSize : natural := 4
    );
    port (
        clock: in bit;
        reset: in bit;
        load: in bit;
        d: in bit_vector(wordSize-1 downto 0);
        q: out bit_vector(wordSize-1 downto 0)
    );
end reg;

architecture reg_arch of reg is
    signal data: bit_vector(wordSize-1 downto 0);
begin
    process(clock, reset)
    begin
        if reset = '1' then
            data <= (others => '0');
        elsif rising_edge(clock) then
            if load = '1' then
                data <= d;
            end if;
        end if;
    end process;
    q <= data;
end reg_arch;

-------------------------------------------------------
--! @brief Generic register bank
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity regfile is
    generic (
        regn: natural := 32;
        wordSize: natural := 64
    );
    port (
        clock: in bit;
        reset: in bit;
        regWrite: in bit;
        rr1, rr2, wr: in bit_vector(natural(ceil(log2(real(regn))))-1 downto 0);
        d: in bit_vector(wordSize-1 downto 0);
        q1, q2: out bit_vector(wordSize-1 downto 0)
    );
end regfile;

architecture regfile_arch of regfile is
    component reg is
        generic (
            wordSize : natural := 4
        );
        port (
            clock: in bit;
            reset: in bit;
            load: in bit;
            d: in bit_vector(wordSize-1 downto 0);
            q: out bit_vector(wordSize-1 downto 0)
        );
    end component;

    component demux_1b is
        generic (
            sel_size : natural := 4
        );
        port (
            a_in : in bit;
            sel : in bit_vector(sel_size-1 downto 0);
            a_out : out bit_vector(2**sel_size - 1 downto 0)
        );
    end component;

    constant regn_bits : natural := natural(ceil(log2(real(regn))));

    signal load_mask: bit_vector((2**regn_bits)-1 downto 0);

    type reg_bank_t is array(0 to regn-1) of bit_vector(wordSize-1 downto 0);
    signal q_mask: reg_bank_t;

begin

    gen_reg_bank: for i in 0 to regn-2 generate
        reg_bank: reg   generic map(wordSize)
                        port map(clock, reset, load_mask(i), d, q_mask(i));
    end generate gen_reg_bank;

    DEMUX: demux_1b generic map(regn_bits)
                    port map(regWrite, wr, load_mask);

    q_mask(regn-1) <= (others => '0');

    q1 <= q_mask(to_integer(unsigned(rr1)));
    q2 <= q_mask(to_integer(unsigned(rr2)));
end regfile_arch;


-------------------------------------------------------
--! @brief 1-bit full adder
-------------------------------------------------------
entity fa_1bit is
    port (
        A,B : in bit;       -- adends
        CIN : in bit;       -- carry-in
        SUM : out bit;      -- sum
        COUT : out bit      -- carry-out
    );
end entity fa_1bit;

architecture wakerly of fa_1bit is
-- Solution Wakerly's Book (4th Edition, page 475)
begin
    SUM <= (A xor B) xor CIN;
    COUT <= (A and B) or (CIN and A) or (CIN and B);
end architecture wakerly;


-------------------------------------------------------
--! @brief 16-bit full adder
-------------------------------------------------------

entity fa_16b is
    port(
        A, B : in bit_vector(15 downto 0);
        CIN : in bit;
        SUM : out bit_vector(15 downto 0);
        COUT : out bit;
        OV : out bit
    );
end entity;

architecture ripple of fa_16b is
    component fa_1bit is
        port (
            A,B : in bit;       -- adends
            CIN : in bit;       -- carry-in
            SUM : out bit;      -- sum
            COUT : out bit      -- carry-out
        );
    end component;

    signal carry : bit_vector(16 downto 0);
    signal result : bit_vector(15 downto 0);
begin
    gen_ripple: for i in 0 to 15 generate
        full_adder: fa_1bit port map(A(i), B(i), carry(i), result(i), carry(i+1));
    end generate;

    OV <= carry(15) xor carry(16);
    COUT <= carry(16);
    SUM <= result;
end architecture;


-------------------------------------------------------
--! @brief Calculator
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity calc is
    port (
        clock : in bit;
        reset : in bit;
        instruction : in bit_vector(15 downto 0);
        overflow : out bit;
        q1 : out bit_vector(15 downto 0)
    );
end entity;

architecture calc_arch of calc is
    component regfile is
        generic (
            regn: natural := 32;
            wordSize: natural := 64
        );
        port (
            clock: in bit;
            reset: in bit;
            regWrite: in bit;
            rr1, rr2, wr: in bit_vector(natural(ceil(log2(real(regn))))-1 downto 0);
            d: in bit_vector(wordSize-1 downto 0);
            q1, q2: out bit_vector(wordSize-1 downto 0)
        );
    end component;

    component fa_16b is
        port(
            A, B : in bit_vector(15 downto 0);
            CIN : in bit;
            SUM : out bit_vector(15 downto 0);
            COUT : out bit;
            OV : out bit
        );
    end component;

    signal opcode, ov_flag : bit;
    signal oper1, oper2, dest : bit_vector(4 downto 0);
    signal result, oper1_reg, oper2_reg : bit_vector(15 downto 0);
    signal imediate_or_reg2 : bit_vector(15 downto 0);
begin

    REG_BANK: regfile   generic map(32, 16)
                        port map(clock, reset, '1', oper1, oper2, dest, result, oper1_reg, oper2_reg);

    ADDER: fa_16b port map(oper1_reg, imediate_or_reg2, '0', result, open, ov_flag);

    opcode <= instruction(15);
    oper2 <= instruction(14 downto 10);
    oper1 <= instruction(9 downto 5);
    dest <= instruction(4 downto 0);

    with opcode select
        imediate_or_reg2 <=  bit_vector(to_signed(to_integer(signed(oper2)), 16)) when '0',
                            oper2_reg when '1',
                            oper2_reg when others;



    overflow <= ov_flag;
    q1 <= oper1_reg;
end calc_arch;