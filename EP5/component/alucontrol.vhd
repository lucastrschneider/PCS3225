-------------------------------------------------------
--! @file alucontrol.vhd
--! @brief ALU control from PoliLEG
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-11-03

--! Last submission: #8723
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity alucontrol is
    port (
        aluop: in bit_vector(1 downto 0);
        opcode: in bit_vector(10 downto 0);
        aluCtrl: out bit_vector(3 downto 0)
    );
end entity alucontrol;

architecture combinational of alucontrol is
    signal typeR: bit_vector(3 downto 0);
begin
    with opcode select
        typeR <=    "0010" when "10001011000", -- ADD
                    "0110" when "11001011000", -- SUB
                    "0000" when "10001010000", -- AND
                    "0001" when "10101010000", -- OR
                    "0000" when others;

    with aluop select
        aluCtrl <=  "0010" when "00", -- LDUR or STUR
                    "0111" when "01", -- CBZ
                    typeR  when "10", -- ADD, SUB, AND, OR
                    "0000" when others;

end architecture;