library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
 entity MMU is
     port (clk          : in  std_logic;
          rst           : in  std_logic;
          IF_VP         : in  std_logic_vector(active_VP_size-1 downto 0);
          IF_PP         : out std_logic_vector(phys_page_size -1 downto 0);
          MOE           : in  std_logic;
          MWR           : in  std_logic;
          data_VP       : in  std_logic_vector(active_VP_size-1 downto 0);
          data_PP       : out std_logic_vector(phys_page_size -1 downto 0);
          context       : in  std_logic_vector(context_size-1 downto 0);
          ram_IF_PP     : in  std_logic_vector(phys_page_size-1 downto 0);
          IF_miss       : out std_logic;
          data_miss     : out std_logic;
          dirty_update  : in  std_logic;
          dirty_PP      : in  std_logic_vector(phys_page_size-1 downto 0));
 end MMU;
 -- make use of a Translation Look-aside Buffer (TLB) 
 -- a fully associative cache of 64 entries
 -- tag of tlb is context bits & virtual page #
 -- we need to know which pages are dirty to replace 
 -- them in the hard disc when the must be kicked out of ram

 architecture struct of MMU is
 
 signal TLB : arr_NxPP(0 to TLB_size-1);
 signal valid : std_logic_vector(TLB_size-1 downto 0);
 signal resident,dirty : std_logic_vector(main_mem_lines -1 downto 0);
 signal dec_virt_page  : natural;
 signal TLB_tags : arr_NxTLB_T(0 to TLB_size-1);
 signal LRU      : arr_NxINT_TLB(0 to TLB_size-1);
 signal IF_miss_sig,data_miss_sig :std_logic;
 
 --an entry in tlb gets dirty when data in the page changes and the ram needs to write the 
 --changed page back to the ard disk as TLB is a cache for ram. Need to address this matter too..
 begin
 IF_miss   <= IF_miss_sig;
 data_miss <= data_miss_sig;
 dec_virt_page <= to_integer(unsigned(data_VP));
 --ram writes the tlb when there is a miss in the cache....
 --tlb should write the ram too when a page became dirty
  ------------------------------------------------------
 ------------------WRITE THE TLB------------------------
 -------------------------------------------------------
   writing:process(clk,rst)
   variable saved : std_logic;
   variable write_line: natural range 0 to TLB_size-1;
   begin
   if rst='1' then
       for i in 0 to TLB_size - 1 loop    
          valid(i) <= '0';
       end loop;
       TLB(0) <= test_PP;
       TLB_tags(0) <= test_VP;
       valid(0) <= '1';
   elsif rising_edge(clk) then
       if MWR = '1' then
           saved:= '0';
           for i in 0 to TLB_size-1 loop
               if valid(i) = '0' and saved = '0' then
                   write_line := i;
                   valid(i) <= '1';
                   saved := '1';
               end if;
               if saved = '0' and i = TLB_size-1 then
                   write_line := LRU(0);
               end if;
           end loop;
           TLB(write_line) <= ram_IF_PP;
           --TLB_tags(write_line)<=rw_addr(datapath-1 downto datapath-TLB_tag_size);
       end if;
   end if;
   end process;
 
  ------------------------------------------------------
 ------------------READ THE CACHE---------------------
 ------------------------------------------------------
    
   reading:process(IF_VP,MOE,rst,dirty_update)
   variable IF_miss_var,data_miss_var : std_logic;
   begin
       if rst = '1' then
           IF_miss_sig<='0';
           data_miss_sig<='0';
           for i in 0 to TLB_size -1 loop
               LRU(i) <= i;
               dirty(i) <= '0'; 
           end loop;
       else
       --- read the physical page for the instruction fetch
           IF_miss_var:='1';
           for i in 0 to TLB_size -1 loop
               if valid(i) = '1' and TLB_tags(i) = context & IF_VP then
                   IF_PP <= TLB(i);
                   sort_LRU_Fully(LRU,i);
                   IF_miss_var:='0';
               end if;
           end loop;
           IF_miss_sig<= IF_miss_var;
       --read the physical page for a load or store op
           if MOE = '1'  then
               data_miss_var := '1';
               for i in 0 to TLB_size -1 loop
                   if valid(i) = '1' and TLB_tags(i)=context & data_VP then
                       data_PP <= TLB(i);
                       sort_LRU_Fully(LRU,i);
                       data_miss_var:='0';
                   end if;
               end loop;
           end if;
           data_miss_sig <= MOE and data_miss_var;
           --cache let us know if any page has been dirtied
           if dirty_update ='1' then
               for i in 0 to TLB_size -1 loop
                   if TLB(i)= dirty_PP then dirty(i)<='1';
                   end if;
               end loop;
           end if;
       end if;
   end process;
 
 
 
 end struct;
 