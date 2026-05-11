----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2026 10:45:50 PM
-- Design Name: 
-- Module Name: keypad_controller - Behavioral
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

entity keypad_controller is
 Port (clk: in std_logic;
 
        --PMOD Pins
        rows: in std_logic_vector(3 downto 0);
        cols: out std_logic_vector(3 downto 0);
        
        --signals to pass to pixel pusher
        key_valid: out std_logic;
        key_data: out std_logic_vector(3 downto 0)
 
  );
end keypad_controller;

architecture Behavioral of keypad_controller is

    --Clock Divider 1  ms or 1kHz signal
    signal scan_timer: integer range 0 to 125000 := 0;
    signal scan_tick: std_logic := '0';
    
    type state_type is (SCAN_C1, SCAN_C2, SCAN_C3, SCAN_C4, WAIT_RELEASE);
    signal current_state : state_type := SCAN_C1;
    
    signal current_col : std_logic_vector(3 downto 0) := "0111";
    signal key_pressed : std_logic := '0';
    signal decoded_key : std_logic_vector(3 downto 0) := (others => '0');
begin
    -- Continuously drive the physical column pins with our internal shifting state
    cols <= current_col;
    
    --1kHz Timing Tick Generation
    process(clk)
    begin
        if rising_edge(clk) then
            if scan_timer = 125000 then
                scan_timer <= 0;
                scan_tick <= '1';
            else
                scan_timer <= scan_timer + 1;
                scan_tick <= '0';
            end if;
        end if;
    end process;    
    
    --Matrix Scanning States
    process(clk)
    begin
        if rising_edge(clk) then
            key_valid <= '0'; --default pulse to 0 for only one cycle when we find a key
            
            --advance when state machine every 1 ms
            if scan_tick = '1' then
                case current_state is
                    
                    when SCAN_C1 =>
                        current_col <= "0111";
                        
                        if rows = "0111" then decoded_key <= x"1"; key_pressed <= '1';
                        elsif rows = "1011" then decoded_key <= x"4"; key_pressed <= '1';
                        elsif rows = "1101" then decoded_key <= x"7"; key_pressed <= '1';
                        elsif rows = "1110" then decoded_key <= x"0"; key_pressed <= '1';
                        else key_pressed <= '0'; 
                        end if;
                        
                        if key_pressed = '1' then
                            key_data <= decoded_key; key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C2; 
                        end if;
                        
                        when SCAN_C2 =>
                        current_col <= "1011"; 
                        if rows = "0111" then decoded_key <= x"2"; key_pressed <= '1';
                        elsif rows = "1011" then decoded_key <= x"5"; key_pressed <= '1';
                        elsif rows = "1101" then decoded_key <= x"8"; key_pressed <= '1';
                        elsif rows = "1110" then decoded_key <= x"F"; key_pressed <= '1';
                        else key_pressed <= '0'; end if;
                        
                        if key_pressed = '1' then
                            key_data <= decoded_key; key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C3; end if;

                    when SCAN_C3 =>
                        current_col <= "1101"; 
                        if rows = "0111" then decoded_key <= x"3"; key_pressed <= '1';
                        elsif rows = "1011" then decoded_key <= x"6"; key_pressed <= '1';
                        elsif rows = "1101" then decoded_key <= x"9"; key_pressed <= '1';
                        elsif rows = "1110" then decoded_key <= x"E"; key_pressed <= '1';
                        else key_pressed <= '0'; end if;
                        
                        if key_pressed = '1' then
                            key_data <= decoded_key; key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C4; end if;

                    when SCAN_C4 =>
                        current_col <= "1110"; 
                        if rows = "0111" then decoded_key <= x"A"; key_pressed <= '1';
                        elsif rows = "1011" then decoded_key <= x"B"; key_pressed <= '1';
                        elsif rows = "1101" then decoded_key <= x"C"; key_pressed <= '1';
                        elsif rows = "1110" then decoded_key <= x"D"; key_pressed <= '1';
                        else key_pressed <= '0'; end if;
                        
                        if key_pressed = '1' then
                            key_data <= decoded_key; key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C1; end if;

                    when WAIT_RELEASE =>
                    --stay in this state until all buttons are released
                    --prevents single press from sending multiple commands
                        if rows = "1111" then current_state <= SCAN_C1; --restart scan cycle
                        end if;
                        
                end case;
            end if;
        end if;
    end process;
end Behavioral;
