library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util_pkg.all;

entity tb is
end tb;

architecture test of tb is
    signal  clk, rst: std_logic;
begin
    beta_processor:beta
    port map(clk,rst);
    --create a testbench clock
    clock: process
    begin
        clk <= '0';
        wait for 2 ns;
        clk <= '1';
        wait for 2 ns;
    end process;
    --create a testbench reset
    reset: process
    begin
        rst <= '0';
        wait for 1 ns;
        rst <= '1';
        wait for 6.5 ns;
        rst <= '0';
        wait;
    end process;

end test;  



