-------------------------------------------------------
--! @file ram.vhd
--! @brief Generic RAM memory
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-09-19

--! Last submission: #2800
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity ram is
    generic (
        addressSize : natural := 4;
        wordSize : natural := 8
    );
    port (
        ck, wr : in bit;
        addr : in bit_vector(addressSize - 1 downto 0);
        data_i : in bit_vector(wordSize - 1 downto 0);
        data_o : out bit_vector(wordSize - 1 downto 0)
    );
end ram;

architecture ram_arch of ram is
    type mem_t is array(0 to (2**addressSize) - 1) of bit_vector (wordSize - 1 downto 0);
    signal mem : mem_t;
begin

    WRITE: process(ck)
    begin
        if (rising_edge(ck) and wr='1') then
            mem(to_integer(unsigned(addr))) <= data_i;
        end if;
    end process;

    data_o <= mem(to_integer(unsigned(addr)));
end ram_arch;