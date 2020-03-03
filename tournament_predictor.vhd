library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;  
entity tournament_predictor is
	port (clk          : in  std_logic;
		  rst          : in  std_logic;
		  op_code      : in  std_logic_vector(instruction_code - 1 downto 0);
          curr_addr    : in  std_logic_vector(addr_mem_size - 1 downto 0);
          valid_res    : in  std_logic;
          success      : in  std_logic;
          source_addr  : in  std_logic_vector(addr_mem_size - 1 downto 0);
          
          prediction   : out tourn_prediction);
end tournament_predictor;


-- we map 64 branches PCs to their target PC address in the branch predictor modue
-- the addresses map to a table of 64 entries where each entry
-- is a 2-bit saturated counter that denotes as such
-- strongly G, mildly G, mildly L, strongly L  (G = global, L = local)
architecture struct of tournament_predictor is
signal dec_counter_r, dec_counter_w   : natural range 0 to addr_mem_lines - 1;
signal sat_counter_mem : mem_NxSC_TRN(0 to addr_mem_lines - 1);
signal op_code_sig : std_logic_vector(7 downto 0);
begin

    op_code_sig <= "00" & op_code;
    

    dec_counter_w  <= to_integer(unsigned(source_addr));
    
    process(op_code_sig)
    begin
        if op_code_sig >= JMP and op_code_sig <= BNE then
            dec_counter_r  <= to_integer(unsigned(curr_addr));
        end if;
    end process;
   
    prediction <= local when sat_counter_mem(dec_counter_r) = SL or
                             sat_counter_mem(dec_counter_r) = ML
                  else global; 
    
    -- write the bimodal saturated counter that remembers 
    process(clk, rst)
    begin
        if rst = '1' then
            for i in 0 to addr_mem_lines - 1 loop
                sat_counter_mem(i) <= ML; -- we favour the local predictor slightly 
            end loop;
        elsif rising_edge(clk) then
            if valid_res = '1' then
                if success = '1' then -- go to a strong prediction 
                    case sat_counter_mem(dec_counter_w) is
                        when SG => sat_counter_mem(dec_counter_w) <= SG;
                        when MG => sat_counter_mem(dec_counter_w) <= SG;
                        when others => sat_counter_mem(dec_counter_w) <= SL;
                    end case;
                elsif success = '0' then -- go to a  mild prediction
                    case sat_counter_mem(dec_counter_w) is
                        when SG => sat_counter_mem(dec_counter_w) <= MG;
                        when MG => sat_counter_mem(dec_counter_w) <= ML;
                        when ML => sat_counter_mem(dec_counter_w) <= MG;
                        when others => sat_counter_mem(dec_counter_w) <= ML;
                    end case;
                end if;
            end if;
        end if;
    end process;    
    
end struct;