library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
 entity main_memory is
     port (clk           : in  std_logic;
           rst           : in  std_logic;
           context       : in std_logic_vector(context_size-1 downto 0);
           --instruction needs
           IF_offset     : in  std_logic_vector(page_offset-1 downto 0);
           IF_VP         : in  std_logic_vector(active_VP_size-1 downto 0);
           IF_PP         : out std_logic_vector(phys_page_size-1 downto 0);
           valid_IF_PP   : out std_logic;
           valid_instr   : out std_logic;
           TLB_IF_PP     : in  std_logic_vector(phys_page_size-1 downto 0);--case of if miss in cache but hit in tlb
           instr_block   : out arr_NxD(0 to words_in_block-1 );
           instr_address : out std_logic_vector(datapath-1 downto 0);
           TLB_IF_miss   : in  std_logic;
           IF_miss       : in  std_logic;
           --data needs
           data_offset   : in  std_logic_vector(page_offset-1 downto 0);  
           data_VP       : in  std_logic_vector(active_VP_size-1 downto 0); 
           data_PP       : out std_logic_vector(phys_page_size-1 downto 0);           
           valid_data_PP : out std_logic;
           valid_data    : out std_logic;
           TLB_data_PP   : in  std_logic_vector(phys_page_size-1 downto 0);
           data_block    : out arr_NxD(0 to words_in_block-1 );
           data_address  : out std_logic_vector(datapath-1 downto 0);
           TLB_data_miss : in  std_logic;
           data_miss     : in  std_logic);
 end main_memory;
 --fetch pages # and data
 --4 misses means ram needs to be able to accept 4 different addresses for reads
 --and return everything in parallel
 -- every miss means 2 ram access one to access the page and one to access the actual data
 --beacuase if we did not find the page mapped in tlb its highly unlikely we 'll find the data in cache
 --its physical page contains 4kb-->1k words-->256 lines
 architecture struct of main_memory is
 signal ram : arr_NxNxD(0 to main_mem_lines-1);
 signal valid, dirty : std_logic_vector(main_mem_lines -1 downto 0);
 signal IF_VP_pointer : integer;
 signal IF_VP_block_pointer,IF_VP_word_pointer,data_VP_block_pointer,data_VP_word_pointer : integer;
 signal second_IF,second_data :std_logic;
 signal ram_data_PP,ram_IF_PP: std_logic_vector(phys_page_size-1 downto 0);
 ---------------sync signals--------------
 -- signal ram_clk    : std_logic;
 -- signal clk_counter: natural range 0 to clk_speed_down;
 -- signal ram_IF_offset,ram_data_offset: offset_array;
 -- signal ram_IF_VP,ram_data_VP
 -- signal ram_TLB_IF_miss,ram_IF_miss,ram_TLB_data_miss,ram_data_miss : std_logic;
 begin
 data_PP <= ram_data_PP;
 IF_PP   <= ram_IF_PP;
 IF_VP_block_pointer    <= page_pointer + to_integer(unsigned(context))*map_entries + (to_integer(unsigned(IF_VP))/words_in_block);--what line to start from
 IF_VP_word_pointer     <= to_integer(unsigned(IF_VP)) mod words_in_block;
 data_VP_block_pointer  <= page_pointer+to_integer(unsigned(context))*map_entries+(to_integer(unsigned(data_VP))/words_in_block);--what line to start from
 data_VP_word_pointer   <= to_integer(unsigned(data_VP)) mod words_in_block;

 --reading is a destructive process in a dram but we ll deal with that later too.
 --perhaps the pages must get an extra bit for dirty. maybe the bit 32 of the word can be that 
 --since there is no way we ll be needing all 32 bits.(currently 6+12=18)
 --and bit 31 can be valid. but for the time being lets suppose there is not a hard drive
 reading:process(clk,rst,TLB_IF_miss)
 begin
     if rst='1' then
        second_IF      <=  '0';
        second_data    <=  '0';
        valid_IF_PP    <=  '0';
        valid_instr    <=  '0';
        valid_data_PP  <=  '0';
        valid_data     <=  '0';
        for i in page_pointer to main_mem_lines - 1 loop
            valid(i)   <=  '0';
        end loop;
     elsif rising_edge(clk) then
         valid_IF_PP    <=  '0';
         valid_instr    <=  '0';
         valid_data_PP  <=  '0';
         valid_data     <=  '0';
         --read the instruction physical page location in ram
         if TLB_IF_miss ='1' then
             if valid(IF_VP_block_pointer)='1' then
                ram_IF_PP <= ram(IF_VP_block_pointer)(IF_VP_word_pointer);
                second_IF   <= '1';
                valid_IF_PP <= '1';
              end if;
         --get the instruction after finding the pages location in the previous cycle
         elsif second_IF='1' then 
            -- instr_block <= ram(to_integer(unsigned(ram_IF_PP))*blocks_in_pp);
            -- instr_address <=  to_integer(unsigned(ram_IF_PP))*blocks_in_pp;
            -- valid_instr       <= '1';
             second_IF         <= '0';
         --get the instruction from a miss in IF cache
         elsif IF_miss='1' then
         --    instr_block <= ram(to_integer(unsigned(TLB_IF_PP))*blocks_in_pp);
         --    instr_address <=  to_integer(unsigned(TLB_IF_PP))*blocks_in_pp;
         --    valid_instr       <= '1';
         end if;
         -- get the data physical page location in ram
         if TLB_data_miss ='1' then
             if valid(data_VP_block_pointer)='1' then
                ram_data_PP   <= ram(data_VP_block_pointer)(data_VP_word_pointer);
                valid_data_PP <= '1';
                second_data   <='1';
              end if;
         --get the data from a miss in IF cache
         elsif second_data='1' then 
          --   data_block   <= ram(to_integer(unsigned(ram_data_PP))*blocks_in_pp);
         --    data_address <= to_integer(unsigned(ram_data_PP))*blocks_in_pp;
             valid_data   <= '1';
             second_data  <= '0';
         --get the data from a miss in data cache
         elsif IF_miss='1' then
         --    data_block <= ram(to_integer(unsigned(TLB_data_PP))*blocks_in_pp);
         --    data_address <= to_integer(unsigned(TLB_data_PP))*blocks_in_pp;
             valid_data <= '1';
         end if;
     end if;
 end process;
 
 
 --------------------------------------------------
 --FUTURE: DIFFERENT RAM CLK THAT REQUIRES SYNC--lets keep it here for a rainy day
 --------------------------------------------------
  -------create the ram clock--------------
 -- ram_clk:process(clk,rst)
 -- begin
     -- if rst='1' then
         -- clk_counter<=0;
         -- ram_clk<='0';
     -- elsif rising_edge(clk) then
         -- clk_counter<=clk_counter +1;
         -- if clk_counter=clk_speed_down -1 then
             -- clk_counter<=0;
             -- ram_clk<=not ram_clk;
         -- end if;
     -- end if;
 -- end process;
 -----save the miss states--------------
 -- sync:process(clk,rst)--all inputs must be saved in registers given we cannot know when exactly they are inbound
      -- if rst='1' then -- using them w/o sampling would be sure to violate the timing constraints
          -- clk_counter<=0;
          -- ram_clk<='0';
      -- elsif rising_edge(clk) then
          -- if ram_clk='1' then
              -- if TLB_IF_miss='1' then 
                 -- ram_TLB_IF_miss <= TLB_IF_miss;
                 -- ram_IF_VP       <= IF_VP;
                 -- ram_context     <= context;                 
              -- end if;
              -- if TLB_data_miss='1' then 
                 -- ram_TLB_data_miss <= TLB_data_miss;
                 -- ram_data_VP       <= data_VP;
                 -- ram_context       <= context; 
              -- end if;
              -- if IF_miss='1' then 
                 -- ram_IF_miss <= IF_miss;
              -- end if;
              -- if TLB_data_miss='1' then 
                 -- ram_TLB_data_miss <= TLB_data_miss;
                 -- ram_data_VP       <= data_VP;
                 -- ram_context       <= context; 
              -- end if;              
          -- end if;
      -- end if;
  -- end process;

  

 

end struct; 