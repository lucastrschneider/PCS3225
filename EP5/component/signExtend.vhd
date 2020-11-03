-------------------------------------------------------
--! @file sign_extend.vhd
--! @brief Sign extend from PoliLEG
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-11-03

--! Last submission: #8719
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity signExtend is
    port (
        i: in bit_vector(31 downto 0);
        o: out bit_vector(63 downto 0)
    );
end entity signExtend;

architecture combinational of signExtend is
    signal address : bit_vector(63 downto 0);
begin

    with i(31 downto 27) select
        address <=  bit_vector(resize(signed(i(20 downto 12)), 64)) when "11111", -- Type D
                    bit_vector(resize(signed(i(23 downto  5)), 64)) when "10110", -- Type CB
                    bit_vector(resize(signed(i(25 downto  0)), 64)) when "00010", -- Type B
                    bit_vector(to_signed(0, 64)) when others;

    o <= address;

end architecture;