-------------------------------------------------------
--! @file multiplicador_fd.vhd
--! @brief synchronous multiplier FD
--! @author Edson Midorikawa (emidorik@usp.br)
--! @author Lucas Schneider (lucastrschneider@usp.br)
--! @date 2020-09-04
-------------------------------------------------------

-------------------------------------------------------
--! @brief 4-bit register with asynchronous reset
-------------------------------------------------------
library ieee;
--use ieee.numeric_bit.rising_edge;

entity reg4 is
  port (
    clock, reset, enable: in bit;
    D: in  bit_vector(3 downto 0);
    Q: out bit_vector(3 downto 0)
  );
end entity;

architecture arch_reg4 of reg4 is
  signal dado: bit_vector(3 downto 0);
begin
  process(clock, reset)
  begin
    if reset = '1' then
      dado <= (others=>'0');
--    elsif (rising_edge(clock)) then
    elsif (clock'event and clock='1') then
      if enable='1' then
        dado <= D;
      end if;
    end if;
  end process;
  Q <= dado;
end architecture;

-------------------------------------------------------
--! @brief 8-bit register with asynchronous reset
-------------------------------------------------------

library ieee;
--use ieee.numeric_bit.rising_edge;

entity reg8 is
  port (
    clock, reset, enable: in bit;
    D: in  bit_vector(7 downto 0);
    Q: out bit_vector(7 downto 0)
  );
end entity;

architecture arch_reg8 of reg8 is
  signal dado: bit_vector(7 downto 0);
begin
  process(clock, reset)
  begin
    if reset = '1' then
      dado <= (others=>'0');
--    elsif (rising_edge(clock)) then
    elsif (clock'event and clock='1') then
      if enable='1' then
        dado <= D;
      end if;
    end if;
  end process;
  Q <= dado;
end architecture;

-------------------------------------------------------
--! @brief 2-to-1 4-bit multiplexer
-------------------------------------------------------

entity mux4_2to1 is
  port (
    SEL : in bit;    
    A :   in bit_vector  (3 downto 0);
    B :   in bit_vector  (3 downto 0);
    Y :   out bit_vector (3 downto 0)
    );
end entity mux4_2to1;

architecture with_select of mux4_2to1 is
begin
  with SEL select
    Y <= A when '0',
         B when '1',
         "0000" when others;
end architecture with_select;

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

architecture sum_minterm of fa_1bit is
-- Canonical sum solution (sum of minterms)
begin
  -- SUM = m1 + m2 + m4 + m7
  SUM <= (not(CIN) and not(A) and B) or
         (not(CIN) and A and not(B)) or
         (CIN and not(A) and not(B)) or
         (CIN and A and B);
  -- COUT = m3 + m5 + m6 + m7
  COUT <= (not(CIN) and A and B) or
          (CIN and not(A) and B) or
          (CIN and A and not(B)) or
          (CIN and A and B);
end architecture sum_minterm;

architecture product_maxterm of fa_1bit is
-- Canonical product solution (product of maxterms)
begin
  -- SUM = M0 . M3 . M5 . M6
  SUM <= (CIN or A or B) and
         (CIN or not(A) or not(B)) and
         (not(CIN) or A or not(B)) and
         (not(CIN) or not(A) or B);

  -- COUT = M0 . M1 . M2 . M4
  COUT <= (CIN or A or B) and
         (CIN or A or not(B)) and
         (CIN or not(A) or B) and
         (not(CIN) or A or B);
end architecture product_maxterm;
  
architecture wakerly of fa_1bit is
-- Solution Wakerly's Book (4th Edition, page 475)
begin
  SUM <= (A xor B) xor CIN;
  COUT <= (A and B) or (CIN and A) or (CIN and B);
end architecture wakerly;

architecture bug1 of fa_1bit is
-- Canonical sum solution with bug
begin
  -- SUM = m1 + m2 + m4 + m7
  SUM <= (CIN and not(A) and B) or
         (not(CIN) and A and not(B)) or
         (CIN and not(A) and not(B)) or
         (CIN and A and B);
  -- COUT = m3 + m5 + m6 + m7
  COUT <= (not(CIN) and A and B) or
          (CIN and not(A) and B) or
          (CIN and A and not(B)) or
          (CIN and A and B);
end architecture bug1;

architecture bug2 of fa_1bit is
-- Canonical product solution with bug
begin
  -- SUM = M0 . M3 . M5 . M6
  SUM <= (CIN or A or B) and
         (CIN or not(A) or not(B)) and
         (not(CIN) or A or not(B)) and
         (not(CIN) or not(A) or B);

  -- COUT = M0 . M1 . M2 . M4
  COUT <= (CIN or A or B) and
         (CIN or A or not(B)) and
         (CIN or not(A) or not(B)) and
         (not(CIN) or A or B);
end architecture bug2;

-------------------------------------------------------
--! @brief 4-bit full adder
-------------------------------------------------------
 
entity fa_4bit is
  port (
    A,B : in bit_vector(3 downto 0);    -- adends
    CIN : in bit;                       -- carry-in
    SUM : out bit_vector(3 downto 0);   -- sum
    COUT : out bit                      -- carry-out
    );
end entity fa_4bit;

architecture ripple of fa_4bit is
-- Ripple adder solution

  --  Declaration of the 1 bit adder.  
  component fa_1bit
    port (
      A,B : in bit;       -- adends
      CIN : in bit;       -- carry-in
      SUM : out bit;      -- sum
      COUT : out bit      -- carry-out
    );
  end component fa_1bit;

  signal x,y :   bit_vector(3 downto 0);
  signal s :     bit_vector(3 downto 0);
  signal cin0 :  bit;
  signal cin1 :  bit;
  signal cin2 :  bit;
  signal cin3 :  bit;
  signal cout0 : bit;  
  signal cout1 : bit;
  signal cout2 : bit;
  signal cout3 : bit;
  
begin
  
  -- Components instantiation
  ADDER0: entity work.fa_1bit(wakerly) port map (
    A => x(0),
    B => y(0),
    CIN => cin0,
    SUM => s(0),
    COUT => cout0
    );

  ADDER1: entity work.fa_1bit(wakerly) port map (
    A => x(1),
    B => y(1),
    CIN => cout0,
    SUM => s(1),
    COUT => cout1
    );

  ADDER2: entity work.fa_1bit(wakerly) port map (
    A => x(2),
    B => y(2),
    CIN => cout1,
    SUM => s(2),
    COUT => cout2
    );  

  ADDER3: entity work.fa_1bit(wakerly) port map (
    A => x(3),
    B => y(3),
    CIN => cout2,
    SUM => s(3),
    COUT => cout3
    );

  x <= A;
  y <= B;
  cin0 <= CIN;
  SUM <= s;
  COUT <= cout3;
  
end architecture ripple;

-------------------------------------------------------
--! @brief 8-bit full adder
-------------------------------------------------------
-- baseado em fa_4bit.vhd (gomi@usp.br)
-------------------------------------------------------
 
entity fa_8bit is
  port (
    A,B  : in  bit_vector(7 downto 0);
    CIN  : in  bit;
    SUM  : out bit_vector(7 downto 0);
    COUT : out bit
    );
end entity;

architecture ripple of fa_8bit is
-- Ripple adder solution

  --  Declaration of the 1-bit adder.  
  component fa_1bit
    port (
      A, B : in  bit;   -- adends
      CIN  : in  bit;   -- carry-in
      SUM  : out bit;   -- sum
      COUT : out bit    -- carry-out
    );
  end component fa_1bit;

  signal x,y :   bit_vector(7 downto 0);
  signal s :     bit_vector(7 downto 0);
  signal cin0 :  bit;
  signal cout0 : bit;  
  signal cout1 : bit;
  signal cout2 : bit;
  signal cout3 : bit;
  signal cout4 : bit;  
  signal cout5 : bit;
  signal cout6 : bit;
  signal cout7 : bit;
  
begin
  
  -- Components instantiation
  ADDER0: entity work.fa_1bit(wakerly) port map (
    A => x(0),
    B => y(0),
    CIN => cin0,
    SUM => s(0),
    COUT => cout0
    );

  ADDER1: entity work.fa_1bit(wakerly) port map (
    A => x(1),
    B => y(1),
    CIN => cout0,
    SUM => s(1),
    COUT => cout1
    );

  ADDER2: entity work.fa_1bit(wakerly) port map (
    A => x(2),
    B => y(2),
    CIN => cout1,
    SUM => s(2),
    COUT => cout2
    );  

  ADDER3: entity work.fa_1bit(wakerly) port map (
    A => x(3),
    B => y(3),
    CIN => cout2,
    SUM => s(3),
    COUT => cout3
    );

  ADDER4: entity work.fa_1bit(wakerly) port map (
    A => x(4),
    B => y(4),
    CIN => cout3,
    SUM => s(4),
    COUT => cout4
    );

  ADDER5: entity work.fa_1bit(wakerly) port map (
    A => x(5),
    B => y(5),
    CIN => cout4,
    SUM => s(5),
    COUT => cout5
    );

  ADDER6: entity work.fa_1bit(wakerly) port map (
    A => x(6),
    B => y(6),
    CIN => cout5,
    SUM => s(6),
    COUT => cout6
    );  

  ADDER7: entity work.fa_1bit(wakerly) port map (
    A => x(7),
    B => y(7),
    CIN => cout6,
    SUM => s(7),
    COUT => cout7
    );

  x <= A;
  y <= B;
  cin0 <= CIN;
  SUM <= s;
  COUT <= cout7;
  
end architecture ripple;


-------------------------------------------------------
--! @brief zero value detector
-------------------------------------------------------
 
entity zero_detector is
  port (
    A    : in  bit_vector(3 downto 0);
    zero : out bit
    );
end entity;

architecture dataflow of zero_detector is
-- solution using a NOR gate
begin

  ZERO <= not(A(0) or A(1) or A(2) or A(3));
  
end architecture;

architecture when_else_arch of zero_detector is
-- solution using when else command
begin

  ZERO <= '1' when A = "0000" else
          '0';

end architecture;
  
architecture with_select_arch of zero_detector is
-- solution using with select command
begin

  with A select ZERO <=
    '1' when "0000",
    '0' when others;

end architecture;


-------------------------------------------------------
--! @brief synchronous multiplier
-------------------------------------------------------

--library ieee;
--use ieee.numeric_bit.rising_edge;

entity multiplicador_fd is
  port (
    clock:    in  bit;
    signed_mult: in bit;
    Va,Vb:    in  bit_vector(3 downto 0);
    RSTa,CEa: in  bit;
    RSTb,CEb: in  bit;
    RSTr,CEr: in  bit;
    DCb:      in  bit;
    Zrb:      out bit;
    Vresult:  out bit_vector(7 downto 0)
  );
end entity;

architecture structural of multiplicador_fd is

  component reg4
    port (
      clock, reset, enable: in bit;
      D: in  bit_vector(3 downto 0);
      Q: out bit_vector(3 downto 0)
    );
  end component;

  component reg8
    port (
      clock, reset, enable: in bit;
      D: in  bit_vector(7 downto 0);
      Q: out bit_vector(7 downto 0)
    );
  end component;

  component mux4_2to1
    port (
      SEL : in bit;    
      A :   in bit_vector  (3 downto 0);
      B :   in bit_vector  (3 downto 0);
      Y :   out bit_vector (3 downto 0)
    );
  end component;

  component fa_4bit
    port (
      A,B  : in  bit_vector(3 downto 0);
      CIN  : in  bit;
      SUM  : out bit_vector(3 downto 0);
      COUT : out bit
    );
  end component;

  component fa_8bit
    port (
      A,B  : in  bit_vector(7 downto 0);
      CIN  : in  bit;
      SUM  : out bit_vector(7 downto 0);
      COUT : out bit
      );
  end component;

  component zero_detector
    port (
      A    : in bit_vector(3 downto 0);
      zero : out bit
    );
  end component;

  signal s_ra, s_rb:         bit_vector(3 downto 0);
  signal s_bmenos1, s_muxb:  bit_vector(3 downto 0);
  signal s_a8, s_soma, s_rr: bit_vector(7 downto 0);

begin
  
  RA: reg4 port map (
      clock=>  clock, 
      reset=>  RSTa, 
      enable=> CEa,
      D=>      Va,
      Q=>      s_ra
     );
  
  RB: reg4 port map (
      clock=>  clock, 
      reset=>  RSTb, 
      enable=> CEb,
      D=>      s_muxb,
      Q=>      s_rb
     );
  
  RR: reg8 port map (
      clock=>  clock, 
      reset=>  RSTr, 
      enable=> CEr,
      D=>      s_soma,
      Q=>      s_rr
     );  
  
  SOMA: fa_8bit port map (
        A=>   s_a8,
        B=>   s_rr,
        CIN=> '0',
        SUM=> s_soma,
        COUT=> open
        );

  SUB1: fa_4bit port map (
        A=>   s_rb,
        B=>   "1111",  -- (-1)
        CIN=> '0',
        SUM=> s_bmenos1,
        COUT=> open
        );
  
  MUXB: mux4_2to1 port map (
        SEL=> DCb,    
        A=>   Vb,
        B=>   s_bmenos1,
        Y=>   s_muxb
        );

  ZERO: zero_detector port map (
        A=>    s_rb,
        zero=> Zrb
        );

  s_a8 <= "0000" & s_ra;
  Vresult <= s_rr;
  
end architecture;
