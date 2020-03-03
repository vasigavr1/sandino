library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
use work.functions.all;

entity beta is
port(clk:in std_logic;
     rst:in std_logic);
end beta;
-- need to handle three kinds of exceptions 
--1)traps     --> that call the os
--2)faults    --> that are coding mistakes
--3)interrupts--> that come from inputs or timers
architecture behavior of beta is
------------------instructions----------------------------------------------------------
signal instruction:std_logic_vector (instruction_size-1 downto 0);
------------------address-----------------------------------------------------------------
signal branch_addr,jmp_addr,illop_addr,except_addr,next_addr:std_logic_vector (31 downto 0);
------------------registers--
signal regA,regB,regC : std_logic_vector (datapath-1 downto 0);
signal regA_addr,regB_addr,regC_addr : std_logic_vector(RF_code-1 downto 0);
------------------control signals--------------------------------------------------
signal ASEL,BSEL,MOE, MWR, RA2SEL,WASEL,WERF,Z,IRQ : std_logic;
signal ALUFN : std_logic_vector(3 downto 0);
signal PCSEL : PC_choices;
signal WDSEL : std_logic_vector(1 downto 0);
-----------ALU operands-------------------------------------------------------------
signal operandA,operandB,literal_const : std_logic_vector (datapath-1 downto 0);
------------------WB DATA------------------------------------------------------------
signal ALU_result,save_addr : std_logic_vector (datapath-1 downto 0);
-----------------Memory------------------------------------------------------------
signal mem_read_data,mem_write_data : std_logic_vector (datapath-1 downto 0);
signal branch_jump_times4 : integer;-- std_logic_vector (2 * datapath - 1 downto 0);
signal branch_jump_literal : std_logic_vector (datapath - 1 downto 0);
signal hit       : std_logic;
-------------Pipeline Stages-------------------------------------------------------------------
signal IR_RF,PC_RF : std_logic_vector (datapath-1 downto 0);                                  --RF
signal PC_ALU,ALU_A_pipe,ALU_B_pipe,D_ALU : std_logic_vector (datapath-1 downto 0);    --ALU
signal PC_MEM,Y_MEM,D_MEM : std_logic_vector (datapath-1 downto 0);                    --MEMORY
signal PC_WB,Y_WB : std_logic_vector (datapath-1 downto 0);                             --WRITE BACK
signal IR_ALU,IR_MEM,IR_WB : std_logic_vector (10 downto 0); 
--------------------------------BYPASS------------------------------------------------
signal bypassed_reg_A,bypassed_reg_B: std_logic_vector (datapath-1 downto 0); 
signal bypass_sel_A,bypass_sel_B: std_logic_vector (2 downto 0);
-----------------------BRANCHES-EXCEPTIONS--------------------------------------------
signal RF_stall,branch_stall,excIF,excRF,excALU,excMEM :std_logic;
----------------------TDM-----------------------------------------------
signal context :std_logic_vector(context_size-1 downto 0);
---------------------BRANCH PREDICTION-----------------------------------
signal valid_br_result, br_result, br_success :std_logic;
signal branch_taken, valid_pred : std_logic;
signal curr_addr_sig, br_result_addr, br_source_addr : std_logic_vector(addr_size - 1 downto 0);
signal op_code_sig   : std_logic_vector(instruction_code - 1 downto 0);
signal pred_addr     : std_logic_vector(datapath - 1 downto 0);

--supervisor calls should be placed along with the implementation of a tiny OS
--the tiny OS can leave the context in a register for the beta processor to know
begin
context <=(others => '0');
--drive the addresses and the operands
jmp_addr  <= regA and x"FFFFFFFC";
regA_addr <= IR_RF(20 downto 16);
regB_addr <= IR_RF(15 downto 11)when RA2SEL = '0' else 
             IR_RF(25 downto 21);
regC_addr <= IR_WB(4 downto 0) when WASEL = '0' else
             XPreg_Addr ;
literal_const <= std_logic_vector(resize(signed(IR_RF(15 downto 0)), datapath));              
Z        <= nor_reduce(bypassed_reg_A);--raised if regA = 0
regC     <= Y_WB          when WDSEL = "01" else
            mem_read_data when WDSEL = "10" else
            PC_WB;
            
bypassed_reg_A <= regA        when bypass_sel_A = "000" else
                  ALU_result  when bypass_sel_A = "001" else
                  Y_MEM       when bypass_sel_A = "010" else
                  regC        when bypass_sel_A = "011" else
                  PC_ALU      when bypass_sel_A = "100" else
                  PC_MEM;
bypassed_reg_B <= regB        when bypass_sel_B = "000" else
                  ALU_result  when bypass_sel_B = "001" else
                  Y_MEM       when bypass_sel_B = "010" else
                  regC        when bypass_sel_B = "011" else
                  PC_ALU      when bypass_sel_B = "100" else
                  PC_MEM;
operandA <= bypassed_reg_A when ASEL = '0' else
            branch_addr;
operandB <= literal_const  when BSEL = '1' else
            bypassed_reg_B;

--branch_jump_literal <= to_integer(signed(literal_const));            
branch_jump_times4 <= 4 * to_integer(signed(literal_const));
branch_addr  <= std_logic_vector(signed(signed(PC_RF) + branch_jump_times4));   --4 replaced by 1 fix when memory is replaced  
illop_addr   <= (others=>'0');--kernel calls in the next episode
except_addr  <= (others=>'0');

-----raise exceptions to select the right next instruction address
IRQ  <= excIF or excRF or excALU or excMEM;

----- handle the inputs to the branch predictor-------------
op_code_sig <= instruction(instruction_size - 1 downto instruction_size - instruction_code);
curr_addr_sig <= next_addr(addr_size - 1 downto 0);
br_result_addr <= branch_addr(addr_size - 1 downto 0);
br_source_addr <= std_logic_vector(unsigned(PC_RF(addr_size - 1 downto 0)) - 4);
br_success  <= (not(branch_stall)) and valid_br_result ;

-----------------------------------------------------------
--------------------PIPELINES------------------------------
-----------------------------------------------------------
pipelining:pipeline_stages
port map(clk, rst, excIF, excRF,  excALU, excMEM, instruction, 
         operandA, operandB, bypassed_reg_B, save_addr, ALU_result, 
         PC_RF, PC_ALU, PC_MEM, PC_WB, IR_RF, IR_ALU, IR_MEM, IR_WB, 
         ALU_A_pipe, ALU_B_pipe, D_ALU, D_MEM, Y_MEM, Y_WB, branch_stall, 
         RF_stall);     
-----------------------------------------------------------
------------------BETA CONTROLLER--------------------------
-----------------------------------------------------------    
ctrl_lgc:beta_controller
port map(clk, rst, Z, IRQ, IR_RF, IR_ALU, IR_MEM, IR_WB, valid_pred, branch_taken,
         op_code_sig, ALUFN, ASEL, BSEL,  MOE,  MWR,  PCSEL,  RA2SEL, WASEL , 
         WDSEL, WERF, bypass_sel_A, bypass_sel_B, excRF, branch_stall, RF_stall,
         valid_br_result, br_result);
-----------------------------------------------------------
----------------------IF STAGE-----------------------------
-----------------------------------------------------------
IF_stage: program_counter
port map(clk, rst, branch_addr, jmp_addr, illop_addr, except_addr, 
         pred_addr, PC_RF, PCSEL, RF_stall, next_addr, save_addr);
         

BP : branch_predictor
port map(clk, rst, op_code_sig, curr_addr_sig, valid_br_result, br_result,
         br_success, br_result_addr, br_source_addr, valid_pred,
         branch_taken, pred_addr); 
         
-----------------------------------------------------------
---------------------REGISTER FILE-------------------------
-----------------------------------------------------------
RF_stage :register_file
port map (clk, rst, regA_addr, regB_addr, regC_addr, regC, regA, regB, WERF);
-----------------------------------------------------------
----------------------ALU----------------------------------
-----------------------------------------------------------
EXECUTION_stage:ALU
port map(clk, rst, ALU_A_pipe, ALU_B_pipe, ALUFN, excALU, ALU_result);
-----------------------------------------------------------
------------------MEMORY-----------------------------------
-----------------------------------------------------------
mem: beta_memory
port map(clk, rst, context, next_addr, instruction, MWR, MOE,
         excIF, excMEM, D_MEM, mem_read_data, Y_MEM, hit); --y mem is the adress  and D_mem writed data according to mit specs 



end behavior;