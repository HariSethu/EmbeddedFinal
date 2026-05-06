
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity clk_div_vga is
Port ( clk : in std_logic;
div_vga: out std_logic);
end clk_div_vga;

architecture Behavioral of clk_div_vga is
   signal count: integer range 0 to 4:= 0;

begin
   process(clk)
   begin
    if rising_edge(clk) then
        if count = 4 then
                count <= 0;
                div_vga <='1';
        else 
                count <= count +1;
                div_vga <= '0';
        end if;
    end if;
    end process;
            
            
   
end Behavioral; 