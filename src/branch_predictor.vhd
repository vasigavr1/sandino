library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;  
entity branch_predictor is
	port (clk          : in  std_logic;
		  rst          : in  std_logic;
		  op_code      : in  std_logic_vector(instruction_code - 1 downto 0);
          curr_addr    : in  std_logic_vector(addr_size - 1 downto 0);
          valid_res    : in  std_logic;
          result       : in  std_logic;
          success      : in  std_logic;
          result_addr  : in  std_logic_vector(addr_size - 1 downto 0);
          source_addr  : in  std_logic_vector(addr_size - 1 downto 0);
          valid_pred   : out std_logic;
          branch_taken : out std_logic;
          pred_addr    : out std_logic_vector(datapath - 1 downto 0));
end branch_predictor;

-- read asynchronously
-- write sychronously
-- fully associative mem of 64 entries with branch addresses and an lru for them
-- tags will be the addresses branching from (a direct mapped cache is also be viable, literature proposes
-- not having tags which will introduce aliasing which will lead to potentially branching to wrong addresses)
architecture struct of branch_predictor is
signal mem_addr, tags : mem_NxD(0 to addr_mem_lines - 1);
signal valid_addr     : std_logic_vector(0 to addr_mem_lines - 1 );
signal LRU   : arr_NxINT_TLB(0 to addr_mem_lines - 1);
signal pred_addr_sig  : std_logic_vector(addr_size - 1 downto 0);
signal op_code_sig    : std_logic_vector(7 downto 0);
signal loc_taken, glob_taken : std_logic;
signal loc_valid, glob_valid : std_logic;
signal tourn_pred : tourn_prediction;
constant zeroes : std_logic_vector(VP_size - active_VP_size - 1 downto 0) 
                := (others => '0');
                

-- There is a local predictor that predicts based on each branches hiosty
-- A global predictor that predicts based on the global history
-- and there is a tournament predictor that chooses on of the two predictions in a case-by-case basis
begin
    pred_addr <= zeroes & pred_addr_sig;
    op_code_sig <= "00" & op_code;
     
    
    branch_taken <= loc_taken when tourn_pred = local else
                    glob_taken ; -- or glob_taken
    
    LP: local_predictor -- last 2 bits of the addresses are always 0, carrying no information
    port map(clk, rst, op_code, curr_addr(sat_counter_size + 1 downto 2), valid_res, result,
             source_addr(sat_counter_size + 1 downto 2), loc_valid, loc_taken);
    
    GP: global_predictor 
    port map(clk, rst, op_code, curr_addr(sat_counter_size + 1 downto 2), valid_res, result,
             source_addr(sat_counter_size + 1 downto 2), glob_valid, glob_taken);
             
    TP: tournament_predictor 
    port map(clk, rst, op_code, curr_addr(addr_mem_size + 1 downto 2), valid_res, success,
             source_addr(addr_mem_size + 1 downto 2), tourn_pred);
             
    -- write the actual result of the memory that comes from rf stage
    process(clk, rst)
    variable saved : std_logic;
    variable write_cell : natural;
    begin
        if rst = '1' then
        elsif rising_edge(clk) then
            if valid_res = '1' and result = '1' then
                saved := '0'; 
                for i in 0 to addr_mem_lines - 1 loop
                    if tags(i) = source_addr then
                        saved := '1';
                    end if;   
                end loop;
                write_cell := LRU(0);
                if saved = '0' then -- if there is no entry in mem for source_addr then create one
                   mem_addr(write_cell)   <= result_addr;
                   valid_addr(write_cell) <= '1';
                   tags(write_cell)  <= source_addr;
                   --sort_LRU_Fully(LRU, LRU(0)); --maybe need to generate some sort of flag if we want to sort here
                end if;
            end if;
        end if;
    end process;

   -- read the mem to see if there is a prediction to be made
   -- save the the address that contains the branch so that the 
   -- the actual result can be written later
    process(rst, op_code_sig)
    begin
        if rst = '1' then
            for i in 0 to addr_mem_lines - 1 loop
                   LRU(i) <= i;
            end loop;
        else 
            valid_pred <= '0';
            if op_code_sig >= JMP and op_code_sig <= BNE then
                for i in 0 to addr_mem_lines - 1 loop
                   if valid_addr(i) = '1' and tags(i) = curr_addr then
                       pred_addr_sig <= mem_addr(i);
                       sort_LRU_Fully(LRU, i);
                       valid_pred <= '1';
                   end if;
               end loop;
           end if;
       end if;
    end process;
    

end struct;
