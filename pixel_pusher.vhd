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
use IEEE.NUMERIC_STD.ALL;

entity pixel_pusher is
    Port (
        clk          : in  std_logic;
        en           : in  std_logic;
        vs           : in  std_logic;
        vid          : in  std_logic;
        hcount       : in  std_logic_vector(9 downto 0);
        vcount       : in  std_logic_vector(9 downto 0);
        
        -- Separate Memory Inputs from  Frame Buffers
        bram_data_1  : in  std_logic_vector(11 downto 0);
        bram_data_2  : in  std_logic_vector(11 downto 0);
        
        -- Inputs from Keypad Controller
        key_valid    : in  std_logic;
        key_data     : in  std_logic_vector(3 downto 0);
        
        -- NEW: Inputs from Joystick Controller
        jstk_y       : in  std_logic_vector(9 downto 0);
        jstk_tick    : in  std_logic;
        
        -- Outputs
        R            : out std_logic_vector(4 downto 0);
        G            : out std_logic_vector(5 downto 0);
        B            : out std_logic_vector(4 downto 0);
        read_addr    : out std_logic_vector(11 downto 0) -- Scaled to 12 bits for RAM
    );
end pixel_pusher;

architecture Behavioral of pixel_pusher is
    
    -- Screen Coordinates
    signal x_pos, y_pos : unsigned(9 downto 0);
    
    -- FSM State Registers
    signal active_channel : std_logic := '0'; -- '0' = Ch1, '1' = Ch2
    signal current_scale  : integer range 0 to 7 := 3; -- Amplitude Zoom
    
    -- MUX and Math Signals
    signal active_adc_val : unsigned(11 downto 0);
    signal scaled_adc_val : unsigned(11 downto 0);
    signal wave_y_pos     : unsigned(9 downto 0);

begin

    x_pos <= unsigned(hcount);
    y_pos <= unsigned(vcount);
    
    -- Output the X coordinate as the memory address for Frame Buffers
    read_addr <= std_logic_vector(resize(x_pos, 12));
    
    -- THE MULTIPLEXER (Based on Active Channel)
    active_adc_val <= unsigned(bram_data_1) when active_channel = '0' else unsigned(bram_data_2);

    -- Amplitude Scaling based on Joystick
    scaled_adc_val <= shift_right(active_adc_val, current_scale);

    -- Convert Voltage to Y-Coordinate on screen
    wave_y_pos <= to_unsigned(480, 10) - resize(scaled_adc_val, 10) when scaled_adc_val < 480 else to_unsigned(0, 10);

    -- PROCESS 1: UI State Management
    process(clk)
        variable joy_y_val : integer;
    begin
        if rising_edge(clk) then
            if en = '1' then
                
                -- Keypad Controls
                if key_valid = '1' then
                    case key_data is
                        when x"1" => active_channel <= '0'; -- View Ch1
                        when x"2" => active_channel <= '1'; -- View Ch2
                        when x"3" => 
                            active_channel <= '0';
                            current_scale  <= 3;            -- Reset Scale
                        when others => null;
                    end case;
                end if;

                -- Joystick Controls (Amplitude)
                if jstk_tick = '1' then
                    joy_y_val := to_integer(unsigned(jstk_y));
                    
                    if joy_y_val > 800 and current_scale > 0 then 
                        current_scale <= current_scale - 1; -- Zoom In (Taller)
                    elsif joy_y_val < 200 and current_scale < 7 then
                        current_scale <= current_scale + 1; -- Zoom Out (Shorter)
                    end if;
                end if;
                
            end if;
        end if;
    end process;

    --VGA Drawing Logic
    process(clk)
    begin   
        if rising_edge(clk) then
            if en = '1' then
                if vid = '1' and x_pos < 640 and y_pos < 480 then
                    
                    -- Draw Active Waveform (Yellow for Ch1, Cyan for Ch2)
                    if abs(to_integer(y_pos) - to_integer(wave_y_pos)) <= 1 then
                        if active_channel = '0' then
                            R <= "11111"; G <= "111111"; B <= "00000"; -- Yellow
                        else
                            R <= "00000"; G <= "111111"; B <= "11111"; -- Cyan
                        end if;
                        
                    -- Draw Background Grid
                    elsif (x_pos mod 64 = 0) or (y_pos mod 64 = 0) then
                        R <= "00000"; G <= "010000"; B <= "00000"; -- Dark Green
                    
                    else
                        R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
                    end if;
                else
                    R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
                end if;
            end if;
        end if;                      
    end process;

end Behavioral;
