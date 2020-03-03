library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;
 
  entity register_file is
    port (clk         : in  std_logic;
          rst         : in  std_logic;
          regA_addr   : in  std_logic_vector(RF_code-1 downto 0);
          regB_addr   : in  std_logic_vector(RF_code-1 downto 0);
          regC_addr   : in  std_logic_vector(RF_code-1 downto 0);
          regC        : in  std_logic_vector(datapath-1 downto 0);
          regA        : out std_logic_vector(datapath-1 downto 0);
          regB        : out std_logic_vector(datapath-1 downto 0);
          WERF        : in std_logic);
   end  register_file;
   
   architecture struct of register_file is
   type RF is array  (natural range <>) of std_logic_vector(datapath-1 downto 0);
   signal RegisterFile : RF(RF_size-1 downto 0);
   begin
   regA<=RegisterFile(to_integer(unsigned(regA_addr)));
   regB<=RegisterFile(to_integer(unsigned(regB_addr)));
   write_rf:process(clk,rst)
       begin
           if rising_edge(clk) then 
               if WERF ='1' then
                    RegisterFile(to_integer(unsigned(regC_addr)))<=regC;
               end if;
               RegisterFile(RF_size-1)<=(others=>'0');
           end if;
   end process;
   end struct;