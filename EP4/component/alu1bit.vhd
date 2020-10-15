-------------------------------------------------------
--! @file alu1bit.vhd
--! @brief 1 bit ALU from PoliLEG
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-10-15

--! Last submission: #6907
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
                    less when "11";


end architecture alu1bit_structural;