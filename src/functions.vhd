library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


package functions is
                    --functions--
     --nors the bits of a signal
     function nor_reduce (sig :in std_logic_vector)return std_logic;
     --return the necessary bits for representing a number
     function log2c      (n : integer)  return integer;
     --rotate left
     function rot_left(vec:std_logic_vector;slots:natural) return std_logic_vector;
     --rotate right
     function rot_right(vec:std_logic_vector;slots:natural) return std_logic_vector;
     -- shift left
     function sh_left(vec:std_logic_vector;slots:natural) return std_logic_vector;
     --shift right
     function sh_right(vec:std_logic_vector;slots:natural) return std_logic_vector;
     --shift right sra
     function sra_funct(vec:std_logic_vector;slots:natural;sign :std_logic) return std_logic_vector;
end functions;



package body functions is

    function nor_reduce(sig: in std_logic_vector) return std_logic is
        variable result:std_logic;
    begin
        result:='0';
        for i in sig'range loop
            result:=result or sig(i);
        end loop;
        return not result;
    end function;

	function log2c(n: integer) return integer is
		variable m, p: integer;
	begin
        if n = 1 then
            m := 1;
        else
            m := 0;
            p := 1;
            while p < n loop
                m := m + 1;
                p := p * 2;
            end loop;
        end if;
        return m;
	end log2c;
    
function sh_left(vec:std_logic_vector;slots:natural) return std_logic_vector is
 constant depth:natural:= vec'high;
 variable result:std_logic_vector(depth downto 0):=vec;
 begin
   for i in 0 to slots-1 loop
     if depth>0 then
	   result(depth downto 1) := result(depth-1 downto 0);
       result(0) := '0';
     end if;
   end loop;
 return result; 
 end function;
 
 function sh_right(vec:std_logic_vector;slots:natural) return std_logic_vector is
 constant depth:natural:= vec'high;
 variable result:std_logic_vector(depth downto 0):=vec;
 begin
   for i in 0 to slots-1 loop
     if depth>0 then
	   result(depth-1 downto 0) := result(depth downto 1);
       result(depth) := '0';
     end if;
   end loop;
 return result; 
 end function;
 
function rot_left(vec:std_logic_vector;slots:natural) return std_logic_vector is
 constant depth:natural:= vec'high;
 variable result:std_logic_vector(depth downto 0):=vec;
 variable tmp:std_logic;
 begin
   for i in 0 to slots-1 loop
     if depth>0 then
	   tmp:=result(depth);
	   result(depth downto 1) := result(depth-1 downto 0);
       result(0) := tmp;
     end if;
   end loop;
 return result; 
 end function;
 
 function rot_right(vec:std_logic_vector;slots:natural) return std_logic_vector is
 constant depth:natural:= vec'high;
 variable result:std_logic_vector(depth downto 0):=vec;
 variable tmp:std_logic;
 begin
   for i in 0 to slots-1 loop
     if depth>0 then
	   tmp:=result(0);
	   result(depth-1 downto 0) := result(depth downto 1);
     result(depth) := tmp;
     end if;
   end loop;
 return result; 
 end function;
 
 function sra_funct(vec:std_logic_vector;slots:natural;sign :std_logic) return std_logic_vector is
 constant depth:natural:= vec'high;
 variable result:std_logic_vector(depth downto 0):=vec;
 begin
   for i in 0 to slots-1 loop
     if depth>0 then
	   result(depth-1 downto 0) := result(depth downto 1);
       result(depth) := sign;
     end if;
   end loop;
 return result; 
 end function;
    
  end functions;