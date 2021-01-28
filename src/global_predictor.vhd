library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;  
entity global_predictor is
	port (clk          : in  std_logic;
		  rst          : in  std_logic;
		  op_code      : in  std_logic_vector(instruction_code - 1 downto 0);
          curr_addr    : in  std_logic_vector(sat_counter_size - 1 downto 0);
          valid_res    : in  std_logic;
          result       : in  std_logic;
          source_addr  : in  std_logic_vector(sat_counter_size - 1 downto 0);
          valid_pred   : out std_logic;
          branch_taken : out std_logic);
end global_predictor;

-- a mem with global history of the last 10 branches
-- the history along with the branch PCs map to a table of 1k entries where each entry
-- is a 2-bit saturated counter that denotes as such
-- 00 = strongly NT, 01 = mildly NT, 10 = mildly T, 11 = strongly T
architecture struct of global_predictor is
signal glob_hist : std_logic_vector(glob_hist_width - 1 downto 0);
signal valid_hist   : std_logic;
signal dec_counter_r, dec_counter_w   : natural range 0 to sat_counter_lines - 1;
signal sat_counter_mem : mem_NxSC(0 to sat_counter_lines - 1);
signal op_code_sig : std_logic_vector(7 downto 0);
begin

    -- the branch will be taken if the MSB of the according saturated counter is asserted
    -- if there is no valid history yet the safest choice is to take the branch
    branch_taken   <= sat_counter_mem(dec_counter_r)(1) when valid_hist = '1'
                      else '1'; 
    valid_pred   <= valid_hist;

    dec_counter_w  <= to_integer(unsigned(source_addr xor glob_hist));
    op_code_sig <= "00" & op_code;
    
    process(op_code_sig)
    begin
        if op_code_sig >= JMP and op_code_sig <= BNE then
            dec_counter_r  <= to_integer(unsigned(curr_addr xor glob_hist));
        end if;
    end process;
    
    

    -- write the 10-bit global history
    -- and the according 2 bit saturated counter
    process(clk, rst)
    begin
        if rst = '1' then
            for i in 0 to sat_counter_lines - 1 loop
                sat_counter_mem(i) <= "10";
            end loop;
            glob_hist <= (others => 'U');
            valid_hist <= '0';
        elsif rising_edge(clk) then
            if valid_res = '1' then
                glob_hist(glob_hist_width - 1 downto 1) <= glob_hist(loc_hist_width - 2 downto 0);
                glob_hist(0) <= result;
                if valid_hist = '0' and glob_hist(glob_hist_width - 2) /= 'U' then -- if all history is completed for this entry
                    valid_hist <= '1';
                end if;
                if valid_hist = '1' then
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