----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/20/2026 12:28:15 PM
-- Design Name: 
-- Module Name: debouncer - Behavioral
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
use IEEE.numeric_std.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debouncer is
  Port (clk, btn : in std_logic;
        db_signal : out std_logic);
end debouncer;

architecture Behavioral of debouncer is
    signal counter : std_logic_vector(22 downto 0); -- 22 bits -> 2500000
begin

    synch_proc : process(clk) begin
        if(rising_edge(clk)) then
            if(btn = '1') then
                if(unsigned(counter) < 2499999)then
                    counter <= std_logic_vector(unsigned(counter) + 1);
                end if;
            else
                counter <= (others => '0');
            end if;
        end if;
    end process synch_proc;
    
    db_signal <= '1' when (unsigned(counter) = 2499999) else '0'; -- 2499999


end Behavioral;