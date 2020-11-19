-------------------------------------------------------
--! @file polilegsc.vhd
--! @brief PoliLEG
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-11-18

--! Last submission:
-------------------------------------------------------

-------------------------------------------------------
--! @brief Generic register bank
--! @ref EP3/regfile.vhd
--! @author Lucas Schneider (lucastrschneider@usp.br)
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
--! @brief Generic ALU from PoliLEG
--! @ref EP5/alu.vhd
--! @author Lucas Schneider (lucastrschneider@usp.br)
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





-------------------------------------------------------
--! @brief Sign extend from PoliLEG
--! @ref EP5/sign_extend.vhd
--! @author Lucas Schneider (lucastrschneider@usp.br)
-------------------------------------------------------

-------------------------------------------------------
--! @brief Sign extend unit
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



-------------------------------------------------------
--! @brief PoliLEG datapath
--! @author Lucas Schneider (lucastrschneider@usp.br)
-------------------------------------------------------

-------------------------------------------------------
--! @brief Datapath
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity datapath is
    port (
        -- Common
        clock : in bit;
        reset : in bit;
        -- From Control Unit
        reg2loc : in bit;
        pcsrc : in bit;
        memToReg : in bit;
        aluCtrl : in bit_vector(3 downto 0);
        aluSrc : in bit;
        regWrite : in bit;
        -- To Control Unit
        opcode : out bit_vector(10 downto 0);
        zero : out bit;
        -- IM interface
        imAddr : out bit_vector(63 downto 0);
        imOut : in bit_vector(31 downto 0);
        -- DM interface
        dmAddr : out bit_vector(63 downto 0);
        dmIn : out bit_vector(63 downto 0);
        dmOut : in bit_vector(63 downto 0)
    );

end entity datapath;

architecture structural of datapath is

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

    component alu is
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
    end component;

    component signExtend is
        port (
            i: in bit_vector(31 downto 0);
            o: out bit_vector(63 downto 0)
        );
    end component;

    signal pc_reg_d, pc_reg_q : bit_vector(63 downto 0);  -- PC register input and output
    signal pc_plus_4 : bit_vector(63 downto 0);
    signal sign_extension_shifted, pc_plus_sign : bit_vector(63 downto 0);

    signal rr1_in, rr2_in, wr_in : bit_vector(4 downto 0);  -- Regfile adressess
    signal write_data : bit_vector(63 downto 0);  -- Data to be writtten in reg file
    signal read_data_1, read_data_2 : bit_vector(63 downto 0);  -- Data tridden from reg file

    signal sign_extension : bit_vector(63 downto 0);

    signal main_alu_in_2, main_alu_result : bit_vector(63 downto 0);
    signal zero_flag : bit;

begin
    PROGRAM_COUNTER: reg    generic map(64)
                            port map(clock, reset, '1', pc_reg_d, pc_reg_q);

    REGISTER_BANK: regfile  generic map(32, 64)
                            port map(clock, reset, regWrite, rr1_in, rr2_in, wr_in, write_data, read_data_1, read_data_2);

    SIGN_EXTEND: signExtend port map(imOut, sign_extension);

    MAIN_ALU: alu   generic map(64)
                    port map(read_data_1, main_alu_in_2, main_alu_result, aluCtrl, zero_flag, open, open);


    -- PC
    pc_plus_4 <= bit_vector(unsigned(pc_reg_q) + 4);
    sign_extension_shifted <= sign_extension(61 downto 0) & "00";
    pc_plus_sign <= bit_vector(unsigned(pc_reg_q) + unsigned(sign_extension_shifted));

    with pcsrc select
        pc_reg_d <= pc_plus_sign when '1',
                    pc_plus_4 when others;

    -- REGFILE
    rr1_in <= imOut(9 downto 5);

    with reg2loc select
        rr2_in <=   imOut(4 downto 0) when '1',
                    imOut(20 downto 16) when others;

    wr_in <= imOut(4 downto 0);

    with memToReg select
        write_data <=   dmOut when '1',
                        main_alu_result when '0';

    -- ALU
    with aluSrc select
        main_alu_in_2 <=    sign_extension when '1',
                            read_data_2 when others;

    -- To Control Unit
    opcode <= imOut(31 downto 21);
    zero <= zero_flag;

    -- IM interface
    imAddr <= pc_reg_q;

    -- DM interface
    dmAddr <= main_alu_result;
    dmIn <= read_data_2;

end architecture;





-------------------------------------------------------
--! @brief ALU control from PoliLEG
--! @ref EP5/alucontrol.vhd
--! @author Lucas Schneider (lucastrschneider@usp.br)
-------------------------------------------------------

-------------------------------------------------------
--! @brief ALU control unit
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




-------------------------------------------------------
--! @brief Control unit from PoliLEG
--! @ref EP5/controlunit.vhd
--! @author Lucas Schneider (lucastrschneider@usp.br)
-------------------------------------------------------

-------------------------------------------------------
--! @brief Main control unit
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




-------------------------------------------------------
--! @brief PoliLEG
--! @author Lucas Schneider (lucastrschneider@usp.br)
-------------------------------------------------------

-------------------------------------------------------
--! @brief PoliLEG
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity polilegsc is
    port(
        clock, reset : in bit;
        -- Data Memory
        dmem_addr : out bit_vector(63 downto 0);
        dmem_dati : out bit_vector(63 downto 0);
        dmem_dato : in  bit_vector(63 downto 0);
        dmem_we   : out bit;
        -- Instruction Memory
        imem_addr : out bit_vector(63 downto 0);
        imem_data : in  bit_vector(31 downto 0)
    );
end entity polilegsc;

architecture structural of polilegsc is
    component datapath is
        port (
            -- Common
            clock : in bit;
            reset : in bit;
            -- From Control Unit
            reg2loc : in bit;
            pcsrc : in bit;
            memToReg : in bit;
            aluCtrl : in bit_vector(3 downto 0);
            aluSrc : in bit;
            regWrite : in bit;
            -- To Control Unit
            opcode : out bit_vector(10 downto 0);
            zero : out bit;
            -- IM interface
            imAddr : out bit_vector(63 downto 0);
            imOut : in bit_vector(31 downto 0);
            -- DM interface
            dmAddr : out bit_vector(63 downto 0);
            dmIn : out bit_vector(63 downto 0);
            dmOut : in bit_vector(63 downto 0)
        );

    end component;

    component alucontrol is
        port (
            aluop: in bit_vector(1 downto 0);
            opcode: in bit_vector(10 downto 0);
            aluCtrl: out bit_vector(3 downto 0)
        );
    end component;

    component controlunit is
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
    end component;

begin


end architecture structural;