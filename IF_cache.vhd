library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
 
  entity IF_cache is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          IF_offset   : in  std_logic_vector(page_offset-1 downto 0);
          IF_PP       : in  std_logic_vector(phys_page_size-1 downto 0);
          valid_IF_PP : in  std_logic;
          instruction : out std_logic_vector(instruction_size-1 downto 0);
          excIF       : out std_logic;
          write_data  : in  arr_NxD(0 to bus_words-1);
          write_addr  : in  std_logic_vector(datapath - 1 downto 0);
          write_valid : in  std_logic;
          IF_miss     : out std_logic);
   end  IF_cache;
   -- direct_mapped cache of  total size--block size
   -- LRU replacement policy , A hybrid policy between LRU and MRU could be a possible future goal(pseudo LRU)
   -- this cache is for instructions only, cpu cant store data here only read the next instruction 
   -- ram writes data when misses occur, when the cache is full then LRU will be used w/o the write-backs
   -- as there can not be any dirty words in the code.
   -- cache could be n-way to n contexts that way
architecture struct of IF_cache is

--------------------MEMORY SIGNALS------------------
signal memory    : arr_NxNxD(0 to set-1); --cache can't return anything less than a whole word so the granularity is set on the 32 bits
signal valid     : std_logic_vector(set-1 downto 0);
signal dec_set_IF_addr,dec_set_write_addr  : natural range 0 to set -1;
signal tags     : arr_NxT(0 to set-1);  
signal miss_sig : std_logic;
signal write_physical_tag,IF_physical_tag :std_logic_vector(tag_size-1 downto 0);
signal IF_miss_sig : std_logic;
signal dec_block_IF_addr,dec_block_write : integer;
signal overall_addr : std_logic_vector(overall_size -1 downto 0);
begin
IF_miss   <= IF_miss_sig;

overall_addr <= IF_PP & IF_offset;
dec_set_IF_addr    <= to_integer(unsigned(overall_addr(set_size + block_size -1 downto block_size)));

--dec_block_IF_addr  <= to_integer(unsigned(IF_offset(block_size -1 downto word_size)));
dec_block_IF_addr  <= to_integer(unsigned(IF_offset(block_size -1 downto word_size)));

-- IF_physical_tag    <= IF_PP   & IF_offset(page_offset-1 downto set_size + block_size);
IF_physical_tag    <= overall_addr(overall_size-1 downto set_size + block_size);

dec_set_write_addr <= to_integer(unsigned(write_addr(set_size+block_size -1 downto block_size)));
dec_block_write    <= to_integer(unsigned(write_addr(block_size -1 downto word_size)));
write_physical_tag <= write_addr(tag_size+set_size+block_size-1 downto set_size+block_size);

------------------------------------------------------
------------------READ THE CACHE----------------------
------------------------------------------------------
IF_Read:process(dec_set_IF_addr, dec_block_IF_addr, rst)
variable miss_var: std_logic;
begin
    if rst='1' then 
        IF_miss_sig <= '0';
    else
        If valid_IF_PP = '1' then
            miss_var := '1';
            --direct mapped will directly check just the one valid bit and tag
            if valid(dec_set_IF_addr) = '1' and tags(dec_set_IF_addr) = IF_physical_tag then
                instruction <= memory(dec_set_IF_addr)(dec_block_IF_addr);
                miss_var := '0';
            end if;
            IF_miss_sig <= miss_var;
        else
            IF_miss_sig <= '1';-- if a valid PP doesnt come this way stall the processor
        end if;
    end if;
end process;
------------------------------------------------------
------------------WRITE THE CACHE---------------------
------------------------------------------------------
writing:process(clk,rst)
variable saved : std_logic;
variable dec_initial_set : natural  ;
begin
   if rst = '1' then
       for i in 0 to set - 1 loop    
           valid(i)<= '0';
       end loop;
       dec_initial_set := 0;
       for i in 0 to phys_page_size - tag_size -1 loop
           if test_PP(i) = '1' then
               dec_initial_set := dec_initial_set + 2**(page_offset + i - block_size);
           end if;
       end loop;
       for i  in 0 to code_lines - 1 loop --load the code in the start of the first cache
            memory(dec_initial_set + (i / words_in_block))(i mod words_in_block) <= code(i);
         if (i mod words_in_block) = 0 then
            tags(dec_initial_set + (i / words_in_block)) <= test_PP(phys_page_size-1 downto phys_page_size - tag_size);
            valid(dec_initial_set + (i / words_in_block)) <= '1';
         end if;
       end loop;
   elsif rising_edge(clk) then
       if write_valid='1' then
           for k in 0 to bus_words -1 loop
               memory(dec_set_write_addr)(dec_block_write+k)<= write_data(k);
           end loop;
           valid(dec_set_write_addr) <= '1';
           tags(dec_set_write_addr)   <= write_physical_tag;
       end if;
   end if;
end process;

end struct;