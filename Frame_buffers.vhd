----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/16/2026 07:27:40 PM
-- Design Name: 
-- Module Name: Frame_buffers - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity Frame_buffers is
  Port (clk, pix_tick, fb_reset : in std_logic;
--        sys_tick : in std_logic;
        addr_1,addr_2 : in std_logic_vector(11 downto 0); -- port 2 is vga, port 1 is system
        wr_en1 : in std_logic;
        din1 : in std_logic_vector(11 downto 0);
        dout1, dout2 : out std_logic_vector(11 downto 0));
end Frame_buffers;

architecture Behavioral of Frame_buffers is
    type Mem_type is array (0 to 639) of std_logic_vector(11 downto 0);
    signal memory : Mem_type;
    signal reset_tick : std_logic;
    signal reset_counter : integer range 0 to 639;
begin
    synch_proc : process(clk) begin
        if(rising_edge(clk)) then
            if(fb_reset = '1') then
                reset_tick <= '1';
                reset_counter <= 0;
            else
                if(reset_tick = '1') then
                    memory(reset_counter) <= (others => '0');
                    reset_counter <= reset_counter + 1;
                    if(reset_counter = 639) then
                        reset_counter <= 0;
                        reset_tick <= '0';
                    end if;
                else
                    if(wr_en1 = '1') then
                        memory(to_integer(unsigned(addr_1))) <= din1;
                    end if;
                    dout1 <= memory(to_integer(unsigned(addr_1)));
                    
                    if(pix_tick = '1') then
                        dout2 <= memory(to_integer(unsigned(addr_2)));
                    end if;
                end if;
            end if;
        end if;
    end process synch_proc;
     
end Behavioral; 
