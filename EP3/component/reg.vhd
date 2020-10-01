-------------------------------------------------------
--! @file reg.vhd
--! @brief Generic register
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-10-01

--! Last submission: #5319
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