-------------------------------------------------------
--! @file rom_arquivo_generica.vhd
--! @brief Generic ROM memory loaded from file
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-09-19

--! Last submission: #2795
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity rom_arquivo_generica is
    generic (
        addressSize : natural := 4;
        wordSize : natural := 8;
        datFileName : string := "rom.dat"
    );
    port (
        addr : in bit_vector(addressSize - 1 downto 0);
        data : out bit_vector(wordSize - 1 downto 0)
    );
end rom_arquivo_generica;

architecture rom_arquivo_generica_arch of rom_arquivo_generica is
    type mem_t is array(0 to (2**addressSize) - 1) of bit_vector (wordSize - 1 downto 0);

    impure function init_mem(fileName : in string) return mem_t is
        file mifFile : text open read_mode is fileName;
        variable mifLine : line;
        variable temp_bv : bit_vector(wordSize - 1 downto 0);
        variable temp_mem : mem_t;
        variable it : natural := 0;
    begin
        while not endfile(mifFile) loop
            readline(mifFile, mifLine);
            read(mifLine, temp_bv);
            temp_mem(it) := temp_bv;
            it := it + 1;
        end loop;
        return temp_mem;
    end function init_mem;

    signal mem : mem_t := init_mem(datFileName);
begin
    data <= mem(to_integer(unsigned(addr)));
end rom_arquivo_generica_arch;