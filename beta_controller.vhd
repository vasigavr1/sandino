library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
entity beta_controller is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          Z           : in  std_logic;
          IRQ         : in  std_logic;--notifies that an exception has been thrown
          IR_RF       : in  std_logic_vector(instruction_size-1 downto 0);
          IR_ALU, IR_MEM, IR_WB : in  std_logic_vector(10 downto 0);
          valid_pred  : in  std_logic;
          branch_taken: in  std_logic;
          inst_op_code: in  std_logic_vector(instruction_code - 1 downto 0);
          ALUFN       : out std_logic_vector(3 downto 0);--selects which operation alu should perform definitely not one bit...
          ASEL        : out std_logic;--selects the first ALU source
          BSEL        : out std_logic;--selects the second ALU source
          MOE         : out std_logic;--selects Out Enable(1 when  loading)
          MWR         : out std_logic;--selects Write Read (1 when storing)
          PCSEL       : out PC_choices;--selects where the address of the next instruction will come from
          RA2SEL      : out std_logic;--selects the second register to read
          WASEL       : out std_logic;--selects where the address for an rf write comes from
          WDSEL       : out std_logic_vector(1 downto 0);--selects where the data to write in rf comes from
          WERF        : out std_logic;
          bypass_sel_A  : out std_logic_vector(2 downto 0);
          bypass_sel_B  : out std_logic_vector(2 downto 0);
          excRF        : out std_logic;
          branch_stall : out std_logic;
          RF_stall     : out std_logic;
          valid_br_res : out std_logic;
          br_result    : out std_logic);
   end beta_controller;



--6  last bits of the next instruction control the beta.
--two kinds of instruction for ALU operation
--1) without literal OPCODE   Ra    Rb     Rc   unused
--                 | 31-26 |25-21|20-16|15-11|  10-0  |
--2) with literal    OPCODE   Ra    Rb     literal twos complement
--                 | 31-26 |25-21|20-16 |      15-0              |          
--the controller recieves an instruction and drives all of the control signals
architecture struct of beta_controller is
signal IR_RF_sig,IR_ALU_sig,IR_MEM_sig,IR_WB_sig, inst_op_code_sig : std_logic_vector(7 downto 0);
signal last_prediction : std_logic;

begin
IR_RF_sig  <= "00" & IR_RF (instruction_size-1 downto instruction_size-instruction_code);
IR_ALU_sig <= "00" & IR_ALU(10 downto 5);
IR_MEM_sig <= "00" & IR_MEM(10 downto 5);
IR_WB_sig  <= "00" & IR_WB (10 downto 5);
inst_op_code_sig <= "00" & inst_op_code;
--PCSEL<="000";
-------------------------------------------
-------------BY PASS CONTROLLER------------
-------------------------------------------
by_p: process(IR_RF,IR_ALU,IR_MEM,IR_WB,IR_RF_sig,IR_ALU_sig,IR_MEM_sig,rst)
variable store:integer;
begin
if rst='1' then
  RF_stall<='1';
  bypass_sel_A<="000";
  bypass_sel_B<="000";
else
  bypass_sel_A<="000";
  bypass_sel_B<="000";
  RF_stall<='0';
--------------------bypass register A------------------------------
  if IR_RF(20 downto 16) /= ZEROreg_Addr then
      if IR_RF(20 downto 16) = IR_ALU(4 downto 0) then
         if IR_ALU_sig = LD  then
            RF_stall <= '1';
         elsif IR_ALU_sig >= JMP and IR_ALU_sig <= BNE then
            bypass_sel_A <= "100";
         else 
            bypass_sel_A <= "001";
         end if;
      elsif IR_RF(20 downto 16) = IR_MEM(4 downto 0) then       
         if IR_MEM_sig = LD  then
            RF_stall <= '1';
         elsif IR_MEM_sig >= JMP and IR_MEM_sig <= BNE then
            bypass_sel_A <= "101";
         else 
            bypass_sel_A <= "010";
         end if;
      elsif IR_RF(20 downto 16)=IR_WB(4 downto 0) then
         bypass_sel_A<="011";
      end if;
  end if;
 -----------------bypass register B--------------------------  
 --The store will need to check a different part of the instructions 
 --to be accurate so we make it a different if statement
 
  if IR_RF_sig = ST then store:= 25;
  else store:=15;
  end if;
  if IR_RF(store downto store-4) /= ZEROreg_Addr then
       if IR_RF(store downto store-4) = IR_ALU(4 downto 0) then
           if IR_ALU_sig = LD  then
              RF_stall <= '1';
           elsif IR_ALU_sig >= JMP and IR_ALU_sig <= BNE then
              bypass_sel_B <= "100";
           else 
              bypass_sel_B <= "001";
           end if;
       elsif IR_RF(store downto store-4) = IR_MEM(4 downto 0) then
           if IR_MEM_sig=LD  then
              RF_stall<='1';
           elsif IR_MEM_sig >= JMP and IR_MEM_sig <= BNE then
              bypass_sel_B <= "101";
           else 
              bypass_sel_B <= "010";
           end if;
       elsif IR_RF(store downto store-4)=IR_WB(4 downto 0) then
           bypass_sel_B <= "011";
       end if;
    end if;
 end if;
end process;   
-------------------------------------------
-------------RF CONTROLLER-----------------
-------------------------------------------
rf_ctrl:process(IR_RF_sig,rst)
begin
  if rst='1' then
    excRF<='0';
  else
      excRF<='0';
      --handle the basic control signals
      case IR_RF_sig(instruction_code-1 downto instruction_code-2) is
         when OP =>--operations in ALU without constant
             ASEL   <='0';   BSEL  <='0'; 
             RA2SEL <='0'; 
             if IR_RF_sig(2 downto 0)="111" then
            --    excRF<='1';
             end if;
         when OPC =>--operations in ALU with constant
             ASEL   <='0';   BSEL  <='1'; 
             RA2SEL <='0';
             if IR_RF_sig(2 downto 0)="111" then
                excRF<='1';
             end if;
         when OP_NO_ALU =>
             case IR_RF_sig is
                when LD =>
                     ASEL   <='0';   BSEL  <='1'; 
                     RA2SEL <='0';
                when LDR =>
                     ASEL   <='1';   BSEL  <='0'; 
                     RA2SEL <='0'; 
                when ST => 
                     ASEL   <='0';   BSEL  <='1'; 
                     RA2SEL <='1';
                when JMP | BEQ | BNE =>--all kinds of  branches
                     ASEL   <='0';   BSEL  <='0'; 
                     RA2SEL <='0';   excRF <='0';
                when others =>--ILLOP 
                     ASEL   <='0';   BSEL  <='0'; 
                     RA2SEL <='0';
                     excRF<='1';
             end case;
        when others=>  --ILLOP
                     ASEL   <='0';   BSEL  <='0'; 
                     RA2SEL <='0'; 
                     excRF<='1';                 
        end case;
    end if;
end process;
-------------------------------------------
-------------ALU CONTROLLER----------------
-------------------------------------------
process(IR_ALU_sig)
begin
    --Drive the ALUFN signal that will select the operation performed by the ALU if an operation is needed.
    if (IR_ALU_sig(5 downto 4) = OP or IR_ALU_sig(5 downto 4)=OPC) and IR_ALU_sig(2 downto 0)/="111" then
        ALUFN <= IR_ALU_sig(3 downto 0);
    elsif (IR_ALU_sig = LD or IR_ALU_sig=ST) then
        ALUFN <= ALU_ADD; 
    else
        ALUFN <= ALU_IDLE;
    end if;
end process;
-------------------------------------------
-------------MEM CONTROLLER----------------
-------------------------------------------
process(IR_MEM_sig)
begin
  --handle the basic control signals
         case IR_MEM_sig is
            when LD | LDR=>
                 MWR    <='0';  
                 MOE    <='1';
            when ST =>
                 MWR    <='1';   
                 MOE    <='0';
            when others =>--ILLOP
                 MWR    <='0'; 
                 MOE    <='0';
         end case;
end process;
-------------------------------------------
-------------WB CONTROLLER-----------------
-------------------------------------------
process(IR_WB_sig)
begin
  --handle the basic control signals
  case IR_WB_sig(instruction_code-1 downto instruction_code-2) is
     when OP | OPC=>--operations in ALU without constant
         WASEL <='0'; 
         WDSEL  <="01";  WERF  <='1'; 
     when OP_NO_ALU =>
         case IR_WB_sig is
            when LD | LDR =>
                 WASEL <='0';  
                 WDSEL  <="10";  WERF  <='1';
            when ST =>
                 WASEL <='0';  
                 WDSEL  <="00";  WERF  <='0';
            when JMP | BEQ | BNE =>
                 WASEL <='0';  
                 WDSEL  <="00";  WERF  <='1';
            when others =>--ILLOP
                 WASEL <='1';  
                 WDSEL  <="00";  WERF  <='1';
         end case;
    when others=>  --ILLOP
                 WASEL <='1';  
                 WDSEL  <="00";  WERF  <='1';
    end case;
end process;
------------------------------------------------------------
---------------SELECT NEXT BRANCH INSTR ADRESS--------------
------------------------------------------------------------
process(IR_RF_sig, IRQ, Z, rst, valid_pred, branch_taken)
begin
  if rst = '1' then
    branch_stall <= '0';
  else
        branch_stall<='0';
        br_result <= '0';
        if IRQ = '1' then
            PCSEL <= except_sel;
        elsif IR_RF_sig = JMP then 
            PCSEL <= jmp_sel;
            branch_stall <= '1';
        elsif ((IR_RF_sig = BEQ and z = '1') or -- mistakefully not-taken Branch
              (IR_RF_sig = BNE and z = '0')) and -- branch need to be taken
              (last_prediction /= '1') then    
            PCSEL <= branch_sel;
            branch_stall <= '1';
        elsif ((IR_RF_sig = BEQ and z = '0') or  -- mistakefully taken Branch
              (IR_RF_sig = BNE and z = '1')) and -- branch should not be taken
              (last_prediction = '1')  then 
            PCSEL <= mispredict_sel;
            branch_stall <= '1';
            br_result <= '0';
        elsif valid_pred = '1' and branch_taken = '1' then
            PCSEL <= predict_sel;
        else
            PCSEL <= current_sel;
        end if; 
        -- write whether there is a valid result for branch pred memory
        if IR_RF_sig >= JMP and IR_RF_sig <= BNE then
            valid_br_res <= '1';
            if ((IR_RF_sig = BEQ and z = '1') or   -- if there is a taken Branch then let the predictor now
                (IR_RF_sig = BNE and z = '0')) then -- the default value for bt_result is 0 so not-taken branches are understood by just the valid_br_res
                br_result <= '1';  
            end if;
        else 
            valid_br_res <= '0';
        end if;

  end if;
end process;

--Remember what was the last prediction made
-- we can clock this because we only care about it in the RF stage
process(clk, rst)
begin
    if rst = '1' then
        last_prediction <= '0';
    elsif rising_edge(clk) then
    -- for unvisited brances that we dont know the target PC, we dont make a prediction at all
    -- however the last_prediction signal needs to go down in such cases
        if inst_op_code_sig >= JMP and  inst_op_code_sig <= BNE then 
                if valid_pred = '1' then
                    last_prediction <= branch_taken;
                else
                    last_prediction <= '0';
                end if;
        end if;
    end if;
end process;

end  struct;        
      