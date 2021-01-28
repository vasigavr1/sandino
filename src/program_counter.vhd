library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;  
entity program_counter is
	port (clk         : in  std_logic;
		  rst         : in  std_logic;
		  branch_addr : in  std_logic_vector(31 downto 0);
		  jmp_addr    : in  std_logic_vector(31 downto 0);
		  illop_addr  : in  std_logic_vector(31 downto 0);
		  except_addr : in  std_logic_vector(31 downto 0);
          pred_addr   : in  std_logic_vector(31 downto 0);
          roll_b_addr : in  std_logic_vector(31 downto 0);
		  PCSEL       : in  PC_choices;
          RF_stall    : in std_logic;
		  next_addr   : out std_logic_vector(31 downto 0);
          save_addr   : out std_logic_vector(31 downto 0));
end  program_counter;

architecture struct of program_counter is
signal current_addr : std_logic_vector(31 downto 0);
begin
--drive the output
next_addr <= current_addr;
save_addr   <= std_logic_vector(unsigned(current_addr) + 4);
--make the address selection and save the result in the PC register that contains the next addr
sel:process(clk)
begin
    if rst = '1' then
      current_addr <= (others => '0');--lets assume for the moment that the code in every virtual memory starts at the top and we ll come ack to that
    elsif rising_edge(clk) then
        if RF_stall = '0' then
            case PCSEL is
                when current_sel => current_addr  <= std_logic_vector(unsigned(current_addr) + 4);
                when branch_sel  => current_addr  <= branch_addr;
                when jmp_sel     => current_addr  <= jmp_addr;
                when illop_sel   => current_addr  <= illop_addr;
                when except_sel  => current_addr  <= except_addr;
                when predict_sel => current_addr  <= pred_addr ;
                when mispredict_sel => current_addr  <= roll_b_addr;
                when others => current_addr <= except_addr;
            end case;
        end if;
    end if;
end process;
end struct;