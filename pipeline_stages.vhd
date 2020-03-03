library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
entity pipeline_stages  is
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
          PC_RF   : out  std_logic_vector(instruction_size-1 downto 0);  
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
   end pipeline_stages ;
   
architecture struct of pipeline_stages is
signal IRSrcRF,IRSrcALU,IRSrcMEM,IRSrcWB  :std_logic_vector(1 downto 0);
signal IR_RF_sig,PC_RF_sig : std_logic_vector (datapath-1 downto 0);                                  --RF
signal PC_ALU_sig,ALU_A_pipe_sig,ALU_B_pipe_sig,D_ALU_sig : std_logic_vector (datapath-1 downto 0);    --ALU
signal PC_MEM_sig,Y_MEM_sig,D_MEM_sig : std_logic_vector (datapath-1 downto 0);                    --MEMORY
signal PC_WB_sig,Y_WB_sig : std_logic_vector (datapath-1 downto 0);                             --WRITE BACK
signal IR_ALU_sig,IR_MEM_sig,IR_WB_sig : std_logic_vector (10 downto 0);
begin
PC_RF   <= PC_RF_sig;
PC_ALU  <= PC_ALU_sig;
PC_MEM  <= PC_MEM_sig;
PC_WB   <= PC_WB_sig;
IR_RF   <= IR_RF_sig;
IR_ALU  <= IR_ALU_sig;
IR_MEM  <= IR_MEM_sig;
IR_WB   <= IR_WB_sig;
ALU_A_pipe <= ALU_A_pipe_sig;
ALU_B_pipe <= ALU_B_pipe_sig;
D_ALU      <= D_ALU_sig;
D_MEM      <= D_MEM_sig;
Y_MEM      <= Y_MEM_sig;
Y_WB       <= Y_WB_sig;

IRSrcRF  <= "10" when excIF='1' and ((excRF and excALU and excMEM)='0') else
            "01" when ((excRF or excALU or excMEM)='1') or branch_stall='1' else
            "00";
IRSrcALU <= "10" when excRF='1' and (( excALU and excMEM)='0') else
            "01" when ((excALU or excMEM)='1')  else
            "00";
IRSrcMEM <= "10" when excALU='1' and excMEM='0' else
            "01" when excMEM='1'  else
            "00";
IRSrcWB  <= "10" when excMEM='1' and (( excALU and excMEM)='0') else
            "00";
     
 pipelines:process(clk,rst)
begin
    if rst='1' then
      IR_RF_sig<=NO_OP;
    elsif rising_edge(clk) then
        PC_ALU_sig <= PC_RF_sig; 
        PC_MEM_sig <= PC_ALU_sig; 
        PC_WB_sig  <= PC_MEM_sig;
        ALU_A_pipe_sig <= operandA; 
        ALU_B_pipe_sig <= operandB;
        D_ALU_sig <= bypassed_reg_B; 
        D_MEM_sig <= D_ALU_sig;
        Y_MEM_sig <= ALU_result; 
        Y_WB_sig  <= Y_MEM_sig;
        case IRSrcMEM is
            when "00"=>   IR_MEM_sig <= IR_ALU_sig;
            when "01"=>   IR_MEM_sig <= NO_OP(31 downto 21);
            when others=> IR_MEM_sig <= XP_branch(31 downto 21);
        end case;          
        case IRSrcWB is
            when "00"=>   IR_WB_sig <= IR_MEM_sig;
            when "01"=>   IR_WB_sig <= NO_OP(31 downto 21);
            when others=> IR_WB_sig <= XP_branch(31 downto 21);
        end case;
        if RF_stall='0' then 
          case IRSrcALU is
              when "00"=> IR_ALU_sig <= IR_RF_sig(31 downto 21);
              when "01"=> IR_ALU_sig <= NO_OP(31 downto 21);
              when others=> IR_ALU_sig <= XP_branch(31 downto 21);
          end case;
          case IRSrcRF is
              when "00"=>   IR_RF_sig <= instruction;
              when "01"=>   IR_RF_sig <= NO_OP ;
              when others=> IR_RF_sig <= XP_branch ;
          end case;
          PC_RF_sig <= save_addr;
        else 
          IR_ALU_sig <= NO_OP(31 downto 21); 
        end if;      
    end if;
end process;
end struct;