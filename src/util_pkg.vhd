library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.functions.all;

package util_pkg is


constant RF_size          : natural:= 32;
constant datapath         : natural:= 32;
constant instruction_size : natural:= datapath;
constant RF_code          : natural:= log2c(RF_size);
constant datapath_code    : natural:= log2c(datapath);
constant instruction_code : natural:= 6;
 ------------reserved registers-----------
 constant BPreg_Addr   : std_logic_vector(4 downto 0):="11100";-- r27 = BP Base pointer, points into stack to the local variables of callee
 constant LPreg_Addr   : std_logic_vector(4 downto 0):="11100";-- r28 = LP Linkage pointer, return address to caller
 constant SPreg_Addr   : std_logic_vector(4 downto 0):="11100";-- r29 = SP Stack pointer, points to 1st unused word 
 constant XPreg_Addr   : std_logic_vector(4 downto 0):="11100";-- r30 = XP Exception pointer, points to the next instruction when branching to the exception handling address
 constant ZEROreg_Addr : std_logic_vector(4 downto 0):="11111";-- r31 = zero register
 -------------rest of the registers--------
 constant r0   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(0,5));
 constant r1   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(1,5));
 constant r2   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(2,5));
 constant r3   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(3,5));
 constant r4   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(4,5));
 constant r5   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(5,5));
 constant r6   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(6,5));
 constant r7   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(7,5));
 constant r8   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(8,5));
 constant r9   : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(9,5));
 constant r10  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(10,5));
 constant r11  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(11,5));
 constant r12  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(12,5));
 constant r13  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(13,5));
 constant r14  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(14,5));
 constant r15  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(15,5));
 constant r16  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(16,5));
 constant r17  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(17,5));
 constant r18  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(18,5));
 constant r19  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(19,5));
 constant r20  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(20,5));
 constant r21  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(21,5));
 constant r22  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(22,5));
 constant r23  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(23,5));
 constant r24  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(24,5));
 constant r25  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(25,5));
 constant r26  : std_logic_vector(4 downto 0):=std_logic_vector(to_unsigned(26,5));
 
 --ALU Instruction with and w/o constant
 constant OP     : std_logic_vector(1 downto 0):="10";
 constant OPC    : std_logic_vector(1 downto 0):="11";
 --instructions without ALU
 constant OP_NO_ALU : std_logic_vector(1 downto 0):="01";
 
 -----------instructions with no obvious ALU use-------------
 constant LD     : std_logic_vector(7 downto 0) := x"18";--add op
 constant ST     : std_logic_vector(7 downto 0) := x"19";--add op
 constant JMP    : std_logic_vector(7 downto 0) := x"1B";--no ALU
 constant BEQ    : std_logic_vector(7 downto 0) := x"1C";--no ALU
 constant BNE    : std_logic_vector(7 downto 0) := x"1D";--no ALU
 constant LDR    : std_logic_vector(7 downto 0) := x"1F";--alu result=regA
 -----------ALU instructions without constant---------
 constant ADD    : std_logic_vector(7 downto 0) := x"20";
 constant SUB    : std_logic_vector(7 downto 0) := x"21";
 constant MUL    : std_logic_vector(7 downto 0) := x"22";
 constant DIV    : std_logic_vector(7 downto 0) := x"23";
 constant CMPEQ  : std_logic_vector(7 downto 0) := x"24";--EQUAL
 constant CMPLT  : std_logic_vector(7 downto 0) := x"25";--LESS
 constant CMPLE  : std_logic_vector(7 downto 0) := x"26";--LESS-EQUAL
 
 constant AND_OP : std_logic_vector(7 downto 0) := x"28";
 constant OR_OP  : std_logic_vector(7 downto 0) := x"29";
 constant XOR_OP : std_logic_vector(7 downto 0) := x"2A";
 constant XNOR_OP: std_logic_vector(7 downto 0) := x"2B";
 constant SHL    : std_logic_vector(7 downto 0) := x"2C";
 constant SHR    : std_logic_vector(7 downto 0) := x"2D";
 constant SRA_OP : std_logic_vector(7 downto 0) := x"2E";
 -----------ALU instructions with constant-------------
 constant ADDC   : std_logic_vector(7 downto 0) := x"30";
 constant SUBC   : std_logic_vector(7 downto 0) := x"31";
 constant MULC   : std_logic_vector(7 downto 0) := x"32";
 constant DIVC   : std_logic_vector(7 downto 0) := x"33";
 constant CMPEQC : std_logic_vector(7 downto 0) := x"34";
 constant CMPLTC : std_logic_vector(7 downto 0) := x"35";
 constant CMPLEC : std_logic_vector(7 downto 0) := x"36";
 
 constant ANDC   : std_logic_vector(7 downto 0) := x"38";
 constant ORC    : std_logic_vector(7 downto 0) := x"39";
 constant XORC   : std_logic_vector(7 downto 0) := x"3A";
 constant XNORC  : std_logic_vector(7 downto 0) := x"3B";
 constant SHLC   : std_logic_vector(7 downto 0) := x"3C";
 constant SHRC   : std_logic_vector(7 downto 0) := x"3D";
 constant SRAC   : std_logic_vector(7 downto 0) := x"3E";
  ----------------ALU operations ----------------
 constant ALU_ADD    : std_logic_vector(3 downto 0) := x"0";
 constant ALU_SUB    : std_logic_vector(3 downto 0) := x"1";
 constant ALU_MUL    : std_logic_vector(3 downto 0) := x"2";
 constant ALU_DIV    : std_logic_vector(3 downto 0) := x"3";
 constant ALU_CMPEQ  : std_logic_vector(3 downto 0) := x"4";--EQUAL
 constant ALU_CMPLT  : std_logic_vector(3 downto 0) := x"5";--LESS
 constant ALU_CMPLE  : std_logic_vector(3 downto 0) := x"6";--LESS-EQUAL
 constant ALU_IDLE   : std_logic_vector(3 downto 0) := x"7";
 constant ALU_AND_OP : std_logic_vector(3 downto 0) := x"8";
 constant ALU_OR_OP  : std_logic_vector(3 downto 0) := x"9";
 constant ALU_XOR_OP : std_logic_vector(3 downto 0) := x"A";
 constant ALU_XNOR_OP: std_logic_vector(3 downto 0) := x"B";
 constant ALU_SHL    : std_logic_vector(3 downto 0) := x"C";
 constant ALU_SHR    : std_logic_vector(3 downto 0) := x"D";
 constant ALU_SRA_OP : std_logic_vector(3 downto 0) := x"E";
 
 --------------- Exception Instructions --------------------
 constant zeroes     : std_logic_vector(31 downto 0) :=( others=>'0');
 constant not_in_mem : std_logic_vector(instruction_size-1 downto 0) := (others=>'0');
 constant wrong_addr : std_logic_vector(instruction_size-1 downto 0) := "00" & x"1" & (25 downto 0=>'0');
 constant NO_OP      : std_logic_vector(instruction_size-1 downto 0) := ADD(5 downto 0) & ZEROreg_Addr & ZEROreg_Addr  & ZEROreg_Addr & (10 downto 0 => '0');
 constant XP_branch  : std_logic_vector(instruction_size-1 downto 0) := BNE(5 downto 0) & XPreg_Addr   & ZEROreg_Addr  & (15 downto 0 => '0');
 
 ------------------ cache properties -------------------------------------------
 constant set            : natural := 512;--lines, meaning 512 different tags in each of the N parts
 constant set_size       : natural := log2c(set); --representing bits
 constant associativity  : natural := 3;
 constant word_block     : natural := 16;    -- in bytes
 constant block_size     : natural := log2c(word_block);  --4 bits for representation of the whole block in bytes 
 constant word           : natural := 4;    -- in bytes
 constant word_size      : natural := log2c(word); -- representing bits
 constant mem_size       : natural := set*block_size;
 constant words_in_block : natural := word_block/word;
 constant bus_words      : natural := words_in_block; --how many words can  traverse the  bus in parallel 
 
 
 ------------------ main memory -------------------------------------------
 constant main_mem_lines  : natural := 2**14;--therefore  16k lines 
 constant main_mem_size   : natural := log2c(main_mem_lines) + block_size;--18k bytes =256kB since block size refers to bytes
 constant page_offset     : natural := 12;  -- therefore page size is 4 KB
 constant TLB_size        : natural := 64;  --64 entries more than needed since there are only 48 physical pages
 constant VP_size         : natural := datapath - page_offset;-- need 20 bits to represent
 constant reserved_ram    : natural := 2**12;--lets go ahead and reserve (12+4=16)-->64 kB
 constant active_ram      : natural := main_mem_lines-reserved_ram;--16k-4k=12k--that leaves us with just 192 Kb
 constant phys_pages      : natural := (active_ram*word_block)/(2**page_offset);--48 phys pages
 constant phys_page_size  : natural := log2c(phys_pages);--nearest to 48 is 64=2^6 so we need 6 bits to represent the physical page
 constant pp_blocks_size  : natural := page_offset-block_size; --8 bits meaning that every physical page consists of 256 blocks
 constant blocks_in_pp    : natural := 2**pp_blocks_size;--256 blocks in one pp
 constant contexts        : natural := 2; --lets support 2 different processes to run in the beta, worry about the tdm later
 constant context_size    : natural := log2c(contexts);--1 bit required for context representation
 constant active_VP_size  : natural := 10;--lets restrict ourselves to a smaller va in order to keep tha mappin to a minimuma virtual address consist of 22 bits therefore..
 constant TLB_tag_size    : natural := active_VP_size+context_size; --reserve 11 bits for the tag
 constant tag_size        : natural := phys_page_size+page_offset-block_size-set_size;--we need the phys_page bits plus those from the offset that go into the tag
 constant map_entries     : natural := (2**active_VP_size)/words_in_block;--every context's map consists of 1k entries that needs 1k words -->256 lines
 constant total_map_lines : natural := (contexts*(2**active_VP_size))/words_in_block;--we need 2k words for all 2 contexts since in every line there are 4 words we need 512 lines
 constant page_pointer    : natural := main_mem_lines-total_map_lines;--15,5k --we assume the maps are at the bottom of the ram  just to make our life easier
 constant clk_speed_down  : natural := 10;--for ram
 constant overall_size    : natural := tag_size + set_size + block_size; -- overall index into both L1 caches 
 ----------------------Branch Prediction------------------------------
 type PC_choices is (current_sel, branch_sel, jmp_sel,
                     illop_sel, except_sel, predict_sel,
                     mispredict_sel);
 type tourn_prediction is (local, global);
 type tourn_sat_counter is (SG, MG, ML, SL);
 constant addr_mem_lines : natural := 64;
 constant addr_mem_size  : natural := log2c(addr_mem_lines);
 constant addr_size : natural := active_VP_size + page_offset; -- how many bit we need to store an address
 constant loc_hist_width  : natural := 10; --keep 10 bits of local history
 constant loc_hist_lines  : natural := 64; -- 64 entries of 10 bit local history
 constant loc_hist_size   : natural := log2c(loc_hist_lines); --6 bits need to address the 64-entries mem
 constant glob_hist_width : natural := 10; -- results of the last ten branches
 constant sat_counter_lines : natural := 1024; -- 1k entries
 constant sat_counter_size  : natural := log2c(sat_counter_lines); --10 bits to address
 constant sat_counter_width : natural := 2; --  2-bit counter
 
 
 ----------------------Types------------------------------
 type arr_NxB       is array (natural range <>) of std_logic_vector(7 downto 0);
 type arr_NxS       is array (natural range <>) of std_logic_vector(set - 1 downto 0);
 type arr_NxD       is array (natural range <>) of std_logic_vector((word * 8) - 1 downto 0);
 type arr_NxPP      is array (natural range <>) of std_logic_vector(phys_page_size - 1 downto 0);
 type arr_NxNxD     is array (natural range <>) of arr_NxD(0 to words_in_block - 1);
 type arr_NxNxNxD   is array (natural range <>) of arr_NxNxD(0 to set - 1);
 type arr_NxT       is array (natural range <>) of std_logic_vector(tag_size - 1 downto 0);--tag
 type arr_NxTLB_T   is array (natural range <>) of std_logic_vector(TLB_tag_size - 1 downto 0);--tag
 type arr_NxNxT     is array (natural range <>) of arr_NxT(0 to set - 1);--tag
 type arr_NxINT     is array (natural range <>) of natural range 0 to associativity - 1;
 type arr_NxINT_TLB is array (natural range <>) of natural range 0 to TLB_size - 1;
 type arr_NxNxINT   is array (natural range <>) of arr_NxINT(0 to associativity - 1); 
 type mem_NxD       is array (natural range <>) of std_logic_vector(addr_size - 1 downto 0);
 type arr_NxLRU     is array (natural range <>) of natural range 0 to addr_mem_lines - 1;
 type mem_NxLH      is array (natural range <>) of std_logic_vector(loc_hist_width - 1 downto 0);
 type mem_NxSC      is array (natural range <>) of std_logic_vector(sat_counter_width - 1 downto 0);
 type mem_NxSC_TRN  is array (natural range <>) of tourn_sat_counter;
 ----------------------FUNCTIONS-------------------------------
 
 procedure sort_LRU_Nway(signal LRU:inout arr_NxNxINT; position: in natural; addr :in natural);
 procedure sort_LRU_Fully(signal LRU:inout arr_NxINT_TLB; position: in natural);
 ----------------------CODE------------------------------------
 constant test_PP  : std_logic_vector(phys_page_size - 1 downto 0) := "000101";
 constant test_VP  : std_logic_vector(active_VP_size + context_size - 1 downto 0) := (others => '0');
 constant code_lines : natural := 30;
 constant code: arr_NxD(0 to code_lines-1) :=
 (ADDC(5 downto 0) & r0  & ZEROreg_Addr & std_logic_vector(to_signed(1,16)),    --1
  ADDC(5 downto 0) & r1  & ZEROreg_Addr & std_logic_vector(to_signed(2,16)),    --2
  ADDC(5 downto 0) & r2  & ZEROreg_Addr & std_logic_vector(to_signed(3,16)),    --3
  ADDC(5 downto 0) & r3  & ZEROreg_Addr & std_logic_vector(to_signed(4,16)),    --4
  ADDC(5 downto 0) & r4  & ZEROreg_Addr & std_logic_vector(to_signed(5,16)),    --5
  ADDC(5 downto 0) & r5  & ZEROreg_Addr & std_logic_vector(to_signed(6,16)),    --6
  ADDC(5 downto 0) & r6  & ZEROreg_Addr & std_logic_vector(to_signed(7,16)),    --7
  ADDC(5 downto 0) & r7  & ZEROreg_Addr & std_logic_vector(to_signed(8,16)),    --8
  ADDC(5 downto 0) & r8  & ZEROreg_Addr & std_logic_vector(to_signed(9,16)),    --9
  ADDC(5 downto 0) & r9  & ZEROreg_Addr & std_logic_vector(to_signed(10,16)),   --10
  ADD (5 downto 0) & r10 &   r7  &  r8  &  (10 downto 0 => '0'),                --11
  ST  (5 downto 0) & r10 & ZEROreg_Addr & std_logic_vector(to_signed(255,16)),  --12
  LD  (5 downto 0) & r11 & ZEROreg_Addr & std_logic_vector(to_signed(255,16)),   --13
  ADDC(5 downto 0) & r1  & r11   & std_logic_vector(to_signed(12,16)),          --14
  ADDC(5 downto 0) & r2  & ZEROreg_Addr & std_logic_vector(to_signed(13,16)),    --15
  ADDC(5 downto 0) & r3  & ZEROreg_Addr & std_logic_vector(to_signed(14,16)),    --16
  ADDC(5 downto 0) & r4  & ZEROreg_Addr & std_logic_vector(to_signed(15,16)),    --17  
  LD  (5 downto 0) & r12 & ZEROreg_Addr & std_logic_vector(to_signed(255,16)),  --18
  SUBC(5 downto 0) & r4  &   r4  &   std_logic_vector(to_signed(1,16)),         --19
  BNE (5 downto 0) & r26 &   r4  &   std_logic_vector(to_signed(-2,16)),         --20
  MUL (5 downto 0) & r12 &   r8  &   r7  &  (10 downto 0 => '0'),               --21
  SHLC(5 downto 0) & r13 &   r12 &   std_logic_vector(to_signed(1,16)),         --22
  SHRC(5 downto 0) & r14 &   r13 &   std_logic_vector(to_signed(1,16)),         --23  
  SHRC(5 downto 0) & r14 &   r14 &   std_logic_vector(to_signed(1,16)),         --24
  BNE (5 downto 0) & r26 &   r14 &   std_logic_vector(to_signed(-2,16)),         --25
  BEQ (5 downto 0) & r26 &   ZEROreg_Addr &   std_logic_vector(to_signed(-10,16)), --26
  "000111" & r14 &   r8  &   (15 downto 0 => '0'),                            --27 ERROR
  ADDC(5 downto 0) & r1  & r11   & std_logic_vector(to_signed(12,16)),          --28
  ADDC(5 downto 0) & r2  & ZEROreg_Addr & std_logic_vector(to_signed(13,16)),    --29
  ADDC(5 downto 0) & r3  & ZEROreg_Addr & std_logic_vector(to_signed(14,16)));    --30
 ------------------------------------------------------------
 --------------------|COMPONENTS|----------------------------
 ------------------------------------------------------------
 component beta is
    port(clk:in std_logic;
         rst:in std_logic);
    end component beta;
 component beta_controller is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          Z           : in  std_logic;
          IRQ         : in  std_logic;
          IR_RF       : in  std_logic_vector(instruction_size-1 downto 0);
          IR_ALU,IR_MEM,IR_WB : in  std_logic_vector(10 downto 0);
          valid_pred  : in  std_logic;
          branch_taken: in  std_logic;
          inst_op_code: in  std_logic_vector(instruction_code - 1 downto 0);    
          ALUFN       : out std_logic_vector(3 downto 0);
          ASEL        : out std_logic;
          BSEL        : out std_logic;
          MOE         : out std_logic;
          MWR         : out std_logic;
          PCSEL       : out PC_choices;
          RA2SEL      : out std_logic;
          WASEL       : out std_logic;
          WDSEL       : out std_logic_vector(1 downto 0);
          WERF        : out std_logic;
          bypass_sel_A  : out std_logic_vector(2 downto 0);
          bypass_sel_B  : out std_logic_vector(2 downto 0);
          excRF       : out std_logic;
          branch_stall: out std_logic;
          RF_stall    : out std_logic;
          valid_br_res : out std_logic;
          br_result    : out std_logic);
   end component beta_controller;
 component program_counter is
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
   end component program_counter;
 component ALU is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          operandA        : in  std_logic_vector(31 downto 0);
          operandB        : in  std_logic_vector(31 downto 0);
          ALUFN           : in  std_logic_vector( 3 downto 0);
          excALU          : out std_logic;
          ALU_result      : out std_logic_vector(31 downto 0));
   end component ALU;
 component register_file is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          regA_addr   : in  std_logic_vector(4 downto 0);
          regB_addr   : in  std_logic_vector(4 downto 0);
          regC_addr   : in  std_logic_vector(4 downto 0);
          regC        : in  std_logic_vector(31 downto 0);
          regA        : out std_logic_vector(31 downto 0);
          regB        : out std_logic_vector(31 downto 0);
          WERF        : in std_logic);
   end component register_file;
 component pipeline_stages  is
    port (clk          : in  std_logic;
          rst          : in  std_logic;
          excIF        : in  std_logic;
          excRF        : in  std_logic;
          excALU       : in  std_logic;
          excMEM       : in  std_logic;
          instruction  : in  std_logic_vector(instruction_size-1 downto 0);
          operandA     : in  std_logic_vector(datapath-1 downto 0);
          operandB     : in  std_logic_vector(datapath-1 downto 0);
          bypassed_reg_B : in  std_logic_vector(datapath-1 downto 0);
          save_addr    : in  std_logic_vector(datapath-1 downto 0);
          ALU_result   : in  std_logic_vector(datapath-1 downto 0);
          PC_RF        : out  std_logic_vector(instruction_size-1 downto 0);  
          PC_ALU  : out  std_logic_vector(instruction_size-1 downto 0);
          PC_MEM  : out  std_logic_vector(instruction_size-1 downto 0);
          PC_WB   : out  std_logic_vector(instruction_size-1 downto 0);
          IR_RF   : out  std_logic_vector(datapath-1 downto 0);
          IR_ALU  : out  std_logic_vector (10 downto 0);
          IR_MEM  : out  std_logic_vector (10 downto 0);
          IR_WB   : out  std_logic_vector (10 downto 0);
          ALU_A_pipe : out  std_logic_vector(datapath-1 downto 0);
          ALU_B_pipe : out  std_logic_vector(datapath-1 downto 0);
          D_ALU      : out  std_logic_vector(datapath-1 downto 0);
          D_MEM      : out  std_logic_vector(datapath-1 downto 0);
          Y_MEM      : out  std_logic_vector(datapath-1 downto 0);
          Y_WB       : out  std_logic_vector(datapath-1 downto 0);
          branch_stall : in std_logic;
          RF_stall     : in std_logic);
   end component pipeline_stages ;
 component beta_memory is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          context     : in  std_logic_vector(context_size-1 downto 0);
          IF_addr     : in  std_logic_vector(datapath-1 downto 0);
          instruction : out std_logic_vector(instruction_size-1 downto 0);
          MWR         : in  std_logic;
          MOE         : in  std_logic;
          excIF       : out std_logic;
          excMEM      : out std_logic;
          write_data  : in  std_logic_vector(datapath-1 downto 0);
          read_data   : out std_logic_vector(datapath-1 downto 0);
          rw_addr     : in  std_logic_vector(instruction_size-1 downto 0);
          hit         : out std_logic);
   end component beta_memory;
 component cache is
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
      ram_data     : in  arr_NxD(0 to bus_words-1);
      ram_addr     : in  std_logic_vector(datapath - 1 downto 0);
      ram_valid    : in  std_logic;
      write_back   : out std_logic_vector(datapath-1 downto 0);
      wb_address   : out std_logic_vector(datapath-1 downto 0);
      wb_valid     : out std_logic;
      dirty_update : out std_logic;
      dirty_PP     : out std_logic_vector(phys_page_size-1 downto 0));
 end component cache;
 component IF_cache is
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
 end component  IF_cache;
 component main_memory is
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
 end component main_memory;   
 component MMU is
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
 end component MMU;
 component branch_predictor is
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
end component branch_predictor; 
 component local_predictor is
	port (clk          : in  std_logic;
		  rst          : in  std_logic;
		  op_code      : in  std_logic_vector(instruction_code - 1 downto 0);
          curr_addr    : in  std_logic_vector(sat_counter_size - 1 downto 0);
          valid_res    : in  std_logic;
          result       : in  std_logic;
          source_addr  : in  std_logic_vector(sat_counter_size - 1 downto 0);
          valid_pred   : out std_logic;
          branch_taken : out std_logic);
 end component local_predictor;
 component global_predictor is
	port (clk          : in  std_logic;
		  rst          : in  std_logic;
		  op_code      : in  std_logic_vector(instruction_code - 1 downto 0);
          curr_addr    : in  std_logic_vector(sat_counter_size - 1 downto 0);
          valid_res    : in  std_logic;
          result       : in  std_logic;
          source_addr  : in  std_logic_vector(sat_counter_size - 1 downto 0);
          valid_pred   : out std_logic;
          branch_taken : out std_logic);
 end component global_predictor;
 component tournament_predictor is
	port (clk          : in  std_logic;
		  rst          : in  std_logic;
		  op_code      : in  std_logic_vector(instruction_code - 1 downto 0);
          curr_addr    : in  std_logic_vector(addr_mem_size - 1 downto 0);
          valid_res    : in  std_logic;
          success      : in  std_logic;
          source_addr  : in  std_logic_vector(addr_mem_size - 1 downto 0);
          
          prediction   : out tourn_prediction);
end component tournament_predictor; 
 end util_pkg;


package body util_pkg is


    procedure sort_LRU_Nway(signal LRU:inout arr_NxNxINT; position: in natural; addr :in natural) is
    variable tmp: natural;
    begin
        for i in 0 to associativity - 1 loop
            if LRU(addr)(i) = position  then
                for j in i to associativity - 2 loop
                    LRU(addr)(j) <= LRU(addr)(j + 1);
                end loop;
                LRU(addr)(associativity - 1) <= LRU(addr)(i);
            end if;
        end loop;
    end procedure;
    
    -- this brings the nth element into the  0 spot
    procedure sort_LRU_Fully(signal LRU:inout arr_NxINT_TLB; position: in natural) is
    begin
        for i in 0 to LRU'high loop
            if LRU(i) = position  then
                for j in i to LRU'high - 1 loop
                    LRU(j) <= LRU(j + 1);
                end loop;
                LRU(LRU'high) <= LRU(i);
            end if;
        end loop;
    end procedure;

    
end util_pkg;