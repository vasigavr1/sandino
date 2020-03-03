library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;

entity cache is
port (clk          : in  std_logic;
      rst          : in  std_logic;
      MWR          : in  std_logic;
      MOE          : in  std_logic;
      write_data   : in  std_logic_vector(datapath-1 downto 0);
      read_data    : out std_logic_vector(datapath-1 downto 0);
      data_offset  : in  std_logic_vector(page_offset-1 downto 0);
      data_PP      : in  std_logic_vector(phys_page_size-1 downto 0);
      valid_data_PP: in  std_logic;
      data_miss    : out std_logic;
      ram_data     : in  arr_NxD(0 to bus_words - 1);
      ram_addr     : in  std_logic_vector(datapath - 1 downto 0);
      ram_valid    : in  std_logic;
      write_back   : out std_logic_vector(datapath-1 downto 0);
      wb_address   : out std_logic_vector(datapath-1 downto 0);
      wb_valid     : out std_logic;
      dirty_update : out std_logic;
      dirty_PP     : out std_logic_vector(phys_page_size-1 downto 0));---------
end  cache;
--3 way associative cache of  total size--block size
-- LRU replacement policy , A hybrid policy between LRU and MRU could be a possible future goal
-- need to handle the write backs perhaps a fifo ..
-- when a word is dirty we should let the tlb know that...
architecture struct of cache is

--------------------MEMORY SIGNALS------------------
signal memory    : arr_NxNxNxD(0 to associativity - 1); --cache can't return anything less than a whole word so the granularity is set on the 32 bits
signal valid,dirty  : arr_NxS(0 to associativity - 1);
signal dec_set_rw_addr, dec_block_rw_addr, dec_set_ram, dec_block_ram : natural;
signal tags     : arr_NxNxT(0 to associativity - 1);  
signal LRU      : arr_NxNxINT(0 to set - 1);
signal miss_sig : std_logic;
signal data_physical_tag,ram_physical_tag :std_logic_vector(tag_size - 1 downto 0);
signal data_miss_sig : std_logic;
signal overall_addr : std_logic_vector(overall_size -1 downto 0);
-- we don't protect the code and other parts in cache, the protection for cache is guaranteed by the 3-way associativity
-- one for  each of code-stack-heap respectively.
begin
data_miss <= data_miss_sig;

overall_addr <= data_PP & data_offset;
dec_set_rw_addr   <= to_integer(unsigned(overall_addr(set_size + block_size - 1 downto block_size)));

--dec_block_rw_addr <= to_integer(unsigned(data_offset(block_size -1 downto word_size)));
dec_block_rw_addr <= to_integer(unsigned(overall_addr(block_size -1 downto word_size))); 

--data_physical_tag <= data_PP & data_offset(page_offset-1 downto set_size+block_size);
data_physical_tag <= overall_addr(overall_size-1 downto set_size + block_size);

dec_set_ram      <= to_integer(unsigned(ram_addr(set_size + block_size - 1 downto block_size)));
dec_block_ram    <= to_integer(unsigned(ram_addr(block_size -1 downto word_size))); 
ram_physical_tag <= ram_addr(main_mem_size-1 downto set_size+block_size);

------------------------------------------------------
------------------WRITE THE CACHE---------------------
------------------------------------------------------
writing:process(clk,rst)
variable saved : std_logic;
variable collumn: natural range 0 to associativity-1;
begin
    if rst = '1' then
       wb_valid <= '0';
       for i in 0 to associativity - 1 loop    
           for j in 0 to set - 1 loop 
               valid(i)(j) <= '0';
               dirty(i)(j) <= '0';
           end loop;
       end loop;
    elsif rising_edge(clk) then
       -- writes from stores
       wb_valid <= '0';
       dirty_update <= '0';
       if MWR='1' then
           saved:='0';
           --look up to 3 places since we have a 3-way associative
           for i in 0 to associativity-1 loop
               if valid(i)(dec_set_rw_addr) = '0' and saved = '0' then
                   collumn := i;
                   saved := '1';
               end if;
               if saved = '0' and i = associativity-1 then
                   collumn := LRU(dec_set_rw_addr)(0);
               end if;
           end loop;
           valid(collumn)(dec_set_rw_addr) <= '1';
           dirty(collumn)(dec_set_rw_addr) <= '1';
           memory(collumn)(dec_set_rw_addr)(dec_block_rw_addr) <= write_data;---
           tags(collumn)(dec_set_rw_addr) <= data_physical_tag;
           dirty_update <= '0';
           dirty_PP <= data_PP;
           if dirty(collumn)(dec_set_rw_addr)='1' then-----------
               wb_valid <= '1';
               write_back <= memory(collumn)(dec_set_rw_addr)(dec_block_rw_addr);
           end if;
       end if;
       
       -- writes from ram
       if ram_valid='1' then
           saved:='0';
           for i in 0 to associativity-1 loop
               if valid(i)(dec_set_ram )='0' and saved='0' then
                   collumn:=i;
                   valid(i)(dec_set_ram )<='1';
                   saved:='1';
               end if;
               if saved='0' and i= associativity-1 then
                   collumn:=LRU(dec_set_ram )(0);
               end if;
           end loop;
           for i in 0 to bus_words -1 loop
               memory(collumn)(dec_set_ram )(dec_block_ram+i) <= ram_data(i);
           end loop;
           tags(collumn)(dec_set_ram ) <= data_physical_tag;
           if dirty(collumn)(dec_set_ram )='1' then-------------
               wb_valid <= '1';
               write_back <= memory(collumn)(dec_set_ram)(dec_block_ram);
           end if;
       end if;
    end if;
end process;

------------------------------------------------------
------------------READ THE CACHE----------------------
------------------------------------------------------

data_read:process(clk,rst)
variable miss_var : std_logic:='1';
begin
    if rst='1' then
       data_miss_sig<='0';
       for i in 0 to set -1 loop
           for j in 0 to associativity-1 loop
               LRU(i)(j)<=j;
           end loop;
       end loop;
    elsif rising_edge(clk) then
       if MOE = '1'  then
           miss_var:='1';
           for i in 0 to associativity -1 loop
               if valid(i)(dec_set_rw_addr)='1' and miss_var='1' then
                   if tags(i)(dec_set_rw_addr) = data_physical_tag then --check the tag
                       read_data <= memory(i)(dec_set_rw_addr)(dec_block_rw_addr);
                       sort_LRU_Nway(LRU,i,dec_set_rw_addr);
                       miss_var:='0';
                   end if;
               end if;
           end loop;
       end if;
       data_miss_sig<=MOE and miss_var;
    end if;
end process;

end struct;