library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
use work.functions.all;
entity ALU is
	port (clk         : in  std_logic;
		  rst         : in  std_logic;
		  operandA        : in  std_logic_vector(datapath-1 downto 0);
		  operandB        : in  std_logic_vector(datapath-1 downto 0);
		  ALUFN           : in  std_logic_vector(3 downto 0);
          excALU          : out std_logic;
		  ALU_result      : out std_logic_vector(datapath-1 downto 0));
end ALU;

architecture struct of ALU is
signal opA,opB :integer;
signal result  :integer;
signal result_inter : std_logic_vector(datapath-1 downto 0);

begin
opA <= to_integer(signed(operandA));
opB <= to_integer(signed(operandB));
ALU_result <= std_logic_vector(to_signed(result, datapath));
    process(ALUFN,opA,opB)
    begin
      excALU <= '0';
        case ALUFN is
            when ALU_ADD =>
                if result > (2**31) -1 or result < -(2**31) then --signed representation would work with the use of integers nevertheless ;)
                  excALU <= '1';
                else
                  result<= opA + opB;
                end if;
            when ALU_SUB=>
                if result> (2**31) -1 or result < -(2**31)  then 
                  excALU<='1';
                else
                  result<= opA - opB;
                end if;
            when ALU_MUL=>
              if result> (2**31) -1 then
                excALU<='1';
              else
                result<=opA * opB;
              end if;
            when ALU_DIV=>
                if opB=0 then--well we cant let it divide by 0
                  excALU<='1';
                else
                  result<=opA / opB;
                end if;
            when ALU_CMPEQ=>
                if opA=opB then result<=1; else result<=0;
                end if;
            when ALU_CMPLT=>
                if opA<opB then result<=1; else result<=0;
                end if;
            when ALU_CMPLE=>
                if opA<=opB then result<=1; else result<=0;
                end if;
            when ALU_AND_OP=>
                result<=to_integer(signed(operandA and operandB));
            when ALU_OR_OP=>
                result<=to_integer(signed(operandA or operandB));
            when ALU_XOR_OP=>
                result<=to_integer(signed(operandA xor operandB));
            when ALU_XNOR_OP=>
                result<=to_integer(signed(operandA xnor operandB));
            when ALU_SHL=>
                result<=to_integer(signed(sh_left(operandA,natural(to_integer(unsigned(operandB(4 downto 0))))))) ;
            when ALU_SHR=>
                result<=to_integer(signed(sh_right(operandA,natural(to_integer(unsigned(operandB(4 downto 0)))))));
            when ALU_SRA_OP=>
                result_inter<=sra_funct(operandA,natural(to_integer(unsigned(operandB(4 downto 0)))),operandB(datapath -1));
                result<=to_integer(signed(result_inter));
            when others=>
                result<=opA;
        end case;
    end process;
end struct;
