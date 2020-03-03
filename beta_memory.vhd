library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
 
entity beta_memory is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          context     : in  std_logic_vector(context_size-1 downto 0);
          IF_addr     : in  std_logic_vector(datapath-1 downto 0);
          instruction : out std_logic_vector(instruction_size-1 downto 0);
          MWR         : in  std_logic;
          MOE         : in  std_logic;
          excIF       : out std_logic;--- need to address the issues with those two...
          excMEM      : out std_logic;--  when VP is bigger than the accepted
          write_data  : in  std_logic_vector(datapath-1 downto 0);
          read_data   : out std_logic_vector(datapath-1 downto 0);
          rw_addr     : in  std_logic_vector(instruction_size-1 downto 0);
          hit         : out std_logic);
 end  beta_memory;
 -- MMU  must feed  the cache with the physical page number either from tlb or directly from ram
 -- supporting N contexts with 2^M VP each we need Nx2^M entries for all mapping in ram
 -- if there is a miss in TLB a page must be fetched from ram 
 -- also the cache will be fed the needed physical page number directly from ram
 -- if cache records a miss then data must come from main memory directly to beta
 -- it is possible that two misses can occur simultaneously in both the cache and the TLB
 -- therefore up to 4 misses must be handled in each cycle, cpu must wait for the misses
 -- to be handled using stalls or executing instructions irrelevant to the misses
 -- the tiny OS will take over in main_memory misses where theoretically it would take millinos
 -- of cycles to fetch the right physical page
 -- decide the size of the endian
 -- all syncs between srams and dram will be performed here.
 -- 
architecture struct of beta_memory is
signal TLB_MOE,TLB_MWR :std_logic; 
signal IF_PP,data_PP,TLB_IF_PP,TLB_data_PP,ram_IF_PP,ram_data_PP,dirty_PP : std_logic_vector( phys_page_size-1 downto 0);
signal IF_VP,data_VP : std_logic_vector( active_VP_size-1 downto 0);
signal IF_offset,data_offset : std_logic_vector(page_offset-1 downto 0);
signal cache_wb :std_logic_vector(datapath-1 downto 0);
signal cache_wb_valid,dirty_update : std_logic;
signal cache_instruction : std_logic_vector(instruction_size-1 downto 0);
signal cache_read_data,ram_instr_addr,ram_data_addr,cache_wb_addr : std_logic_vector(datapath - 1 downto 0);
signal ram_data_block,ram_instr_block : arr_NxD(0 to words_in_block-1 );
signal TLB_IF_miss,IF_miss,TLB_data_miss,data_miss : std_logic;
signal ram_TLB_IF_miss,ram_IF_miss,ram_TLB_data_miss,ram_data_miss : std_logic; --the ones that  actually go to ram 
signal ram_IF_PP_valid,ram_data_PP_valid,ram_IF_valid,ram_data_valid,ram_instr_valid : std_logic;
signal valid_IF_PP,valid_data_PP :std_logic;
constant zeroes : std_logic_vector(instruction_size-active_VP_size-page_offset-1 downto 0):=(others=>'0');
begin

excIF        <=  '0' when IF_addr(instruction_size - 1 downto active_VP_size + page_offset) = zeroes else
                 '1';
excMem       <=  '1' when rw_addr(instruction_size - 1 downto active_VP_size + page_offset) /= zeroes and
                 (MOE = '1' or MWR = '1') 
                 else '0';
IF_offset    <=  IF_addr(page_offset-1 downto 0);
IF_VP        <=  IF_addr(page_offset+active_VP_size-1  downto page_offset);

data_offset  <=  rw_addr(page_offset-1 downto 0);
data_VP      <=  rw_addr(page_offset+active_VP_size-1  downto page_offset);

TLB_MOE      <=  MWR or MOE; 
TLB_MWR      <= ram_IF_PP_valid;  

IF_PP        <=  TLB_IF_PP when TLB_IF_miss='0' else
                 ram_IF_PP;
valid_IF_PP  <=  (not(TLB_IF_miss)) or (ram_IF_valid);
data_PP      <=  TLB_data_PP when TLB_data_miss='0' else
                 ram_data_PP;  
valid_data_PP<=  (not(TLB_data_miss)) or not(ram_data_valid);                 
                  
instruction  <= cache_instruction when IF_miss='0' else
                ram_instr_block(to_integer(unsigned(IF_addr(block_size -1 downto word_size))));


-----------------------------------------------------------
------------------ data CACHE------------------------------
-----------------------------------------------------------                
mem: cache --checked  cache should give an address as to the address of the wb
port map(clk,rst,MWR,MOE,write_data,read_data,data_offset,
         data_PP,valid_data_PP,data_miss,ram_data_block,
         ram_data_addr,ram_data_valid,cache_wb,cache_wb_addr,
         cache_wb_valid,dirty_update,dirty_PP);
-----------------------------------------------------------
------------------ IF CACHE--------------------------------
-----------------------------------------------------------          
IF_mem: IF_cache -- checked
port map(clk, rst, IF_offset, IF_PP, valid_IF_PP, cache_instruction,
         excIF, ram_instr_block, ram_instr_addr, ram_instr_valid,
         IF_miss);
-----------------------------------------------------------
------------------MMU--------------------------------------
-----------------------------------------------------------  
VM_handler: MMU--checked
port map(clk,rst,IF_VP,TLB_IF_PP,TLB_MOE,TLB_MWR,data_VP,TLB_data_PP,context,
         ram_IF_PP,TLB_IF_miss,TLB_data_miss,dirty_update,dirty_PP);
-----------------------------------------------------------
------------------RAM--------------------------------------
-----------------------------------------------------------     
ram: main_memory--checked
port map(clk,rst,context,IF_offset,IF_VP,ram_IF_PP,ram_IF_PP_valid,
         ram_instr_valid,TLB_IF_PP,ram_instr_block,ram_instr_addr,
         TLB_IF_miss,IF_miss, data_offset,data_VP,ram_data_PP,ram_data_PP_valid,
         ram_data_valid,TLB_data_PP,ram_data_block,ram_data_addr,TLB_data_miss,
         data_miss);
            
end struct;