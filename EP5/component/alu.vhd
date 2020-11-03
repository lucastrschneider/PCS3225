-------------------------------------------------------
--! @file alu.vhd
--! @brief Generic ALU from PoliLEG
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-11-03

--! Last submission: #8722
-------------------------------------------------------

-------------------------------------------------------
--! @brief 1-bit full adder
-------------------------------------------------------
entity fulladder is
    port (
        a, b, cin : in bit;
        s, cout : out bit
    );
end entity fulladder;

architecture wakerly of fulladder is
-- Solution Wakerly's Book (4th Edition, page 475)
begin
    s <= (a xor b) xor cin;
    cout <= (a and b) or (cin and a) or (cin and b);
end architecture wakerly;


-------------------------------------------------------
--! @brief 1-bit ALU
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;

entity alu1bit is
    port (
        a, b, less, cin: in bit;
        result, cout, set, overflow: out bit;
        ainvert, binvert: in bit;
        operation: in bit_vector(1 downto 0)
    );
end entity alu1bit;

architecture alu1bit_structural of alu1bit is
    component fulladder is
        port (
            a, b, cin : in bit;
            s, cout : out bit
        );
    end component;
    signal a_in, b_in: bit;
    signal fa_result, fa_cout: bit;
begin
    FA: fulladder port map(a_in, b_in, cin, fa_result, fa_cout);

    with ainvert select
        a_in <= not(a) when '1',
                a when others;

    with binvert select
        b_in <= not(b) when '1',
                b when others;
    
    cout <= fa_cout;
    set <= fa_result;
    overflow <= cin xor fa_cout;

    with operation select
        result <=   a_in and b_in when "00",
                    a_in or b_in when "01",
                    fa_result when "10",
                    b when "11";


end architecture alu1bit_structural;

-------------------------------------------------------
--! @brief Generic ALU
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity alu is
    generic (
        size : natural := 64
    );
    port (
        A, B : in bit_vector(size-1 downto 0); -- inputs
        F : out bit_vector(size-1 downto 0); -- output
        S : in bit_vector(3 downto 0); -- op selection
        Z : out bit; -- zero flag
        Ov : out bit; -- overflow flag
        Co : out bit -- carry out
    );
end entity alu;

architecture alu_structural of alu is
    component alu1bit is
        port(
            a, b, less, cin: in bit;
            result, cout, set, overflow: out bit;
            ainvert, binvert: in bit;
            operation : in bit_vector(1 downto 0)
        );
    end component alu1bit;

    signal carrys, result_in, set_in : bit_vector(size-1 downto 0);
    signal less_in : bit;
begin

    ALU_GEN: for i in 0 to (size-1) generate
        MS_ALU: if (i = (size-1)) generate
            alu_1b: alu1bit port map(A(i), B(i), '0', carrys(i-1), result_in(i), carrys(i), set_in(i), Ov, S(3), S(2), S(1 downto 0));
        end generate;

        MD_ALU: if ((i > 0) and (i < (size-1))) generate
            alu_1b: alu1bit port map(A(i), B(i), '0', carrys(i-1), result_in(i), carrys(i), set_in(i), open, S(3), S(2), S(1 downto 0));
        end generate;

        LS_ALU: if (i = 0) generate
            alu_1b: alu1bit port map(A(i), B(i), less_in, S(2), result_in(i), carrys(i), set_in(i), open, S(3), S(2), S(1 downto 0));
        end generate;
    end generate;
    less_in <= set_in(size-1);

    Co <= carrys(size-1);
    Z <= '1' when (signed(result_in) = 0) else '0';

    F <= result_in;

end architecture alu_structural;