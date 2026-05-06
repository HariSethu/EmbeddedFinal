----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/06/2026 01:01:25 PM
-- Design Name: 
-- Module Name: pixel_pusher - Behavioral
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


entity pixel_pusher is
Port (
      clk, en, vs, vid: in std_logic;
      pixel: in std_logic_vector(7 downto 0);
      hcount: in std_logic_vector(9 downto 0);
      vcount: in std_logic_vector(9 downto 0);
      bram_data: in std_logic_vector(23 downto 0);
      
      R: out std_logic_vector(4 downto 0);
      G: out std_logic_vector (5 downto 0);
      B: out std_logic_vector (4 downto 0);
      read_addr: out std_logic_vector(9 downto 0)
);
end pixel_pusher;

architecture Behavioral of pixel_pusher is
-- Signals to hold the separated ADC values
    signal ch1_adc_val, ch2_adc_val : unsigned(11 downto 0);
    signal ch1_y_pos, ch2_y_pos     : unsigned(9 downto 0);
    
    -- Screen coordinates cast to unsigned for math
    signal x_pos, y_pos : unsigned(9 downto 0);
    
begin

    x_pos <= unsigned(hcount);
    y_pos <= unsigned(vcount);
    
    --update memory address to always be current x coordinate on screen
    read_addr <= std_logic_vector(x_pos);
    
    --Split BRAM data into two bit channels
    ch1_adc_val <= unsigned(bram_data(11 downto 0));
    ch2_adc_val <= unsigned(bram_data(23 downto 12));

    ch1_y_pos <= to_unsigned(480, 10) - resize(ch1_adc_val srl 3, 10) when(ch1_adc_val srl 3) < 480 else to_unsigned(0,10);
    ch2_y_pos <= to_unsigned(480, 10) - resize(ch2_adc_val srl 3, 10) when(ch2_adc_val srl 3) < 480 else to_unsigned(0,10);
    process(clk)
    begin   
        if rising_edge(clk) then
            if en = '1' then
                --check if video is active and within 640 x 480 screen
                if vid = '1' and x_pos < 640 and y_pos <480 then
                    
                    if (y_pos = ch1_y_pos) or (y_pos = ch1_y_pos + 1) or (y_pos + 1 = ch1_y_pos) then
                        R <= "11111"; G <= "111111"; B <= "00000";    
                    
                    -- Draw Channel 2 Waveform (Cyan) - 3 Pixels Thick
                    elsif (y_pos = ch2_y_pos) or (y_pos = ch2_y_pos + 1) or (y_pos + 1 = ch2_y_pos) then
                        R <= "00000"; G <= "111111"; B <= "11111";                        
                    --Draw Background Grid every 64 pixels
                    elsif (x_pos mod 64 = 0) or (y_pos mod 64 =0) then
                        R <= "00000"; G <= "010000"; B <= "00000"; -- Dark Green
                    
                    --Default Black Background when not in any of the ranges    
                    else
                        R <= (others => '0');
                        G <= (others => '0');
                        B <= (others => '0');
                    end if;
                    
               else
                    --If outside visible area set to 0 for blinking intervals
                    R <= (others => '0');
                    G <= (others => '0');
                    B <= (others => '0');
               end if;
          end if;
       end if;                     
    end process;
end Behavioral;
