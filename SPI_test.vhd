----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/05/2026 06:22:31 PM
-- Design Name: 
-- Module Name: SPI_test - Behavioral
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

entity SPI_test is
  Port (clk, reset,read_en : in std_logic;
        data_in : in std_logic;
        chip_sel : out std_logic;
        data_out : out std_logic_vector(11 downto 0));
end SPI_test;

architecture Behavioral of SPI_test is
    component SPI_Controller port(
        clk : in std_logic; -- main clock
        sclk : in std_logic; -- serial clock or sampling rate
        reset : in std_logic; -- reset button
        read_en : in std_logic; -- signal from main controller that it is ready to read a new word
        data_in_1 : in std_logic; -- data incoming from channel 1
        data_in_2 : in std_logic; -- data incoming from channel 2
        chip_sel : out std_logic; -- signal to tell ADC to start sending a new word
        data_out_1 : out std_logic_vector(11 downto 0); -- channel 1 output word
        data_out_2 : out std_logic_vector(11 downto 0) -- channel 2 output word
    ); end component;
    
    component debouncer port(
        clk, btn : in std_logic;
        db_signal : out std_logic
    ); end component;
    
    component Clock_div port(
        clk_in : in std_logic;
        clk_out : out std_logic
    ); end component;
    
    signal reset_db,read_db,clk_tick : std_logic;
    
begin
    
    
    SPI : SPI_Controller port map(
        clk => clk,
        sclk => clk_tick,
        reset => reset_db,
        read_en => read_db,
        data_in_1 => data_in,
        data_in_2 => '0',
        chip_sel => chip_sel,
        data_out_1 => data_out,
        data_out_2 => open
    );
    
    reset_debounce : debouncer port map(
        clk => clk,
        btn => reset,
        db_signal => reset_db
    );
    
    
    read_debounce : debouncer port map(
        clk => clk,
        btn => read_en,
        db_signal => read_db
    );
    
    clk_divider : clock_div port map( -- 8 MHz
        clk_in => clk,
        clk_out => clk_tick
    );
    

end Behavioral;
