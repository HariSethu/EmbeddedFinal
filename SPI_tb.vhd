----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/07/2026 01:08:29 PM
-- Design Name: 
-- Module Name: SPI_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_tb is
end SPI_tb;

architecture Behavioral of SPI_tb is
    component SPI_Controller port(
        clk : in std_logic; -- main clock
        sclk : out std_logic; -- serial clock or sampling rate
        reset : in std_logic; -- reset button
        read_en : in std_logic; -- signal from main controller that it is ready to read a new word
        data_in_1 : in std_logic; -- data incoming from channel 1
        data_in_2 : in std_logic; -- data incoming from channel 2
        data_ready : out std_logic;
        next_sample : out std_logic;
        chip_sel : out std_logic; -- signal to tell ADC to start sending a new word
        data_out_1 : out std_logic_vector(11 downto 0); -- channel 1 output word
        data_out_2 : out std_logic_vector(11 downto 0) -- channel 2 output word
    ); end component;
    
    
    signal clk, clk_tick : std_logic := '0';
    signal reset, read_en : std_logic := '0';
    signal chip_sel : std_logic := '1';
    signal data_in_2, data_in_1 : std_logic := '0';
    signal data_out_1, data_out_2 : std_logic_vector(11 downto 0) := (others => '0'); 
    signal test_word_1 : std_logic_vector(11 downto 0) := x"A5A"; -- 101001011010
    signal test_word_2 : std_logic_vector(11 downto 0) := x"3C3"; -- 001111000011
    signal data_ready,next_sample : std_logic;
    
begin

    SPI : SPI_Controller port map(
        clk => clk,
        sclk => clk_tick,
        reset => reset,
        read_en => read_en,
        data_in_1 => data_in_1,
        data_in_2 => data_in_2,
        chip_sel => chip_sel,
        data_ready => data_ready,
        next_sample => next_sample,
        data_out_1 => data_out_1,
        data_out_2 => data_out_2
    );

    clk_proc : process begin 
        clk <= '0';
        wait for 4 ns;
        clk <= '1';
        wait for 4 ns;
    end process clk_proc;
    
    process begin
        reset <= '1';
        wait for 8 ns;
        reset <= '0';
        
        wait for 2000 ns;
        read_en <= '1';
        wait for 8 ns;
        read_en <= '0';
        
        
        
        for index in 0 to 15 loop
            wait until clk_tick = '0';
            if(index < 4) then
                data_in_1 <= '0'; -- zero padding bits
                data_in_2 <= '0'; -- zero padding bits
            else
                data_in_1 <= test_word_1(15 - index);
                data_in_2 <= test_word_2(15 - index);
            end if;
        end loop;
        wait;
    end process;
    
    



    
end Behavioral;

    
    



    
end Behavioral;
