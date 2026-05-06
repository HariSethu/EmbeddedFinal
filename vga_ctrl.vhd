----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/06/2026 01:01:25 PM
-- Design Name: 
-- Module Name: vga_ctrl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity vga_ctrl is
Port (clk, en: in std_logic;
      vcount, hcount: out std_logic_vector(9 downto 0);
      vid, hs, vs: out std_logic );
end vga_ctrl;

architecture Behavioral of vga_ctrl is
--initialize hcount vcount to 0 to make sure same startup procedure all the time
signal h_cnt: unsigned (9 downto 0) := (others => '0');
signal v_cnt: unsigned (9 downto 0) := (others => '0');

begin
    --Sequential Logic
    process(clk)
    begin
        if rising_edge(clk) then
            --Only count when enable is high
            if en = '1' then
                
                --horizontal counter
                if h_cnt = 799 then
                    h_cnt <= (others => '0'); -- Reset horizontal at end of line
                    
                    --Vertical Counter Logic
                    if v_cnt = 524 then
                        v_cnt <= (others => '0'); --Reset Vertical at the bottom of the screen
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
            else 
                h_cnt <= h_cnt + 1;
            end if;
       end if;
    end if;
  end process;
  
  --Combinational Logic for Output
  
  --Cast internal unsigned counters back to our hcount and vcount vectors for output
  hcount <= std_logic_vector(h_cnt);
  vcount <= std_logic_vector(v_cnt);
  
  --Video enable: set to high during the visible pixel area
  vid <= '1' when (h_cnt < 640 and v_cnt < 480) else '0';
  
  
  --Horizontal sync: Active Low
  hs <= '0' when (h_cnt >= 656 and h_cnt <= 751) else '1';
  
  --Vertical Sync: Active Low
  vs <= '0' when (v_cnt >= 490 and v_cnt <= 491) else '1';
end Behavioral;
