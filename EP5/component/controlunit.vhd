-------------------------------------------------------
--! @file controlunit.vhd
--! @brief Control unit from PoliLEG
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-11-03

--! Last submission: #8729
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity controlunit is
    port (
        -- To Datapath
        reg2loc : out bit;
        uncondBranch : out bit;
        branch : out bit;
        memRead : out bit;
        memToReg : out bit;
        aluOp : out bit_vector(1 downto 0);
        memWrite : out bit;
        aluSrc : out bit;
        regWrite : out bit;
        -- From Datapath
        opcode : in bit_vector(10 downto 0)
    );
end entity controlunit;

architecture combinational of controlunit is
    type instruction_t is (LDUR, STUR, CBZ, B, R_format);
    signal inst : instruction_t;

    constant LDUR_OP : bit_vector(10 downto 0) := "11111000010";
    constant STUR_OP : bit_vector(10 downto 0) := "11111000000";
    constant CBZ_OP  : bit_vector(07 downto 0) := "10110100";
    constant B_OP    : bit_vector(05 downto 0) := "000101";
begin

    inst <= LDUR        when (opcode = LDUR_OP) else
            STUR        when (opcode = STUR_OP) else
            CBZ         when (opcode(10 downto 3) = CBZ_OP) else
            B           when (opcode(10 downto 5) = B_OP) else
            R_format;

    with inst select
        reg2loc <=  '1' when STUR | CBZ,
                    '0' when others;

    with inst select
        uncondBranch <= '1' when B,
                        '0' when others;

    with inst select
        branch <=   '1' when CBZ,
                    '0' when others;

    with inst select
        memRead <=  '1' when LDUR,
                    '0' when others;

    with inst select
        memToReg <= '1' when LDUR,
                    '0' when others;

    with inst select
        aluOp <=    "10" when R_format,
                    "01" when CBZ | B,
                    "00" when others;

    with inst select
        memWrite <= '1' when STUR,
                    '0' when others;

    with inst select
        aluSrc <=   '1' when LDUR | STUR,
                    '0' when others;

    with inst select
        regWrite <= '1' when R_format | LDUR,
                    '0' when others;
    
end architecture;