library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;  
entity local_predictor is
	port (clk          : in  std_logic;
		  rst          : in  std_logic;
		  op_code      : in  std_logic_vector(instruction_code - 1 downto 0);
          curr_addr    : in  std_logic_vector(sat_counter_size - 1 downto 0);
          valid_res    : in  std_logic;
          result       : in  std_logic;
          source_addr  : in  std_logic_vector(sat_counter_size - 1 downto 0);
          
          valid_pred   : out std_logic;
          branch_taken : out std_logic);
end local_predictor;

-- a mem with local history of 64 10-bit entries so that
-- we map 64 branches to their histories
-- the histories map to a table of 1k entries where each entry
-- is a 2-bit saturated counter that denotes as such
-- 00 = strongly NT, 01 = mildly NT, 10 = mildly T, 11 = strongly T
architecture struct of local_predictor is
signal loc_hist_mem : mem_NxLH(0 to loc_hist_lines - 1);
signal valid_hist   : std_logic_vector(0 to loc_hist_lines - 1);
signal dec_branch_r, dec_branch_w   : natural range 0 to loc_hist_lines - 1;
signal dec_counter_r, dec_counter_w   : natural range 0 to sat_counter_lines - 1;
signal sat_counter_mem : mem_NxSC(0 to sat_counter_lines - 1);
signal op_code_sig : std_logic_vector(7 downto 0);
begin

    op_code_sig <= "00" & op_code;
    
    dec_branch_w   <= to_integer(unsigned(source_addr(loc_hist_size - 1 downto 0)));
    dec_counter_w  <= to_integer(unsigned(source_addr xor loc_hist_mem(dec_branch_w)));
    
    process(op_code_sig)
    begin
        if op_code_sig >= JMP and op_code_sig <= BNE then
            dec_branch_r   <= to_integer(unsigned(curr_addr(loc_hist_size - 1 downto 0)));
            dec_counter_r  <= to_integer(unsigned(curr_addr xor loc_hist_mem(dec_branch_r)));
        end if;
    end process;
    -- the branch will be taken if the MSB of the according saturated counter is asserted
    -- if there is no valid history yet the safest choice is to take the branch
    branch_taken   <= sat_counter_mem(dec_counter_r)(1) when valid_hist(dec_branch_r) = '1'
                      else '1'; 
    
    valid_pred <= valid_hist(dec_branch_r);
    
    -- write the 10-bit local history
    -- and the according 2 bit saturated counter
    process(clk, rst)
    begin
        if rst = '1' then
            for i in 0 to sat_counter_lines - 1 loop
                sat_counter_mem(i) <= "10";
            end loop;
            for i in 0 to loc_hist_lines - 1 loop
                loc_hist_mem(i) <= (others => 'U');
                valid_hist(i) <= '0';
            end loop;
        elsif rising_edge(clk) then
            if valid_res = '1' then
                loc_hist_mem(dec_branch_w)(loc_hist_width - 1 downto 1) <= loc_hist_mem(dec_branch_w)(loc_hist_width - 2 downto 0);
                loc_hist_mem(dec_branch_w)(0) <= result;
                if valid_hist(dec_branch_w) = '0' and loc_hist_mem(dec_branch_w)(loc_hist_width - 2) /= 'U' then -- if all history is completed for this entry
                    valid_hist(dec_branch_w) <= '1';
                end if;
                if valid_hist(dec_branch_w) = '1' then
                    if result = '1' then -- increment the counter
                        if sat_counter_mem(dec_counter_w) /= "11" then
                            sat_counter_mem(dec_counter_w) <= std_logic_vector(unsigned(sat_counter_mem(dec_counter_w)) + 1);
                        end if; 
                    else  -- decrement the counter
                        if sat_counter_mem(dec_counter_w) /= "00" then
                            sat_counter_mem(dec_counter_w) <= std_logic_vector(unsigned(sat_counter_mem(dec_counter_w)) - 1);
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    
end struct;