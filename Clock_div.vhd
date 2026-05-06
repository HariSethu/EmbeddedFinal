----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/12/2026 05:52:13 PM
-- Design Name: 
-- Module Name: Clock_div - Behavioral
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
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Clock_div is
  Port (clk_in : in std_logic;
        clk_out : out std_logic);
end Clock_div;

architecture Behavioral of Clock_div is
    signal counter : std_logic_vector(26 downto 0) := (others => '0');
begin
    synch_logic : process (clk_in) begin
        if(rising_edge(clk_in)) then
            if(unsigned(counter) < 16) then -- 8 MHz
                clk_out <= '0';
                counter <= std_logic_vector(unsigned(counter) + 1);
            else
                counter <= (others => '0');
                clk_out <= '1';
            end if;
        end if;
    end process synch_logic;
end Behavioral;
