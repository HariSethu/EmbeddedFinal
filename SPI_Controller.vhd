----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/05/2026 03:29:54 PM
-- Design Name: 
-- Module Name: SPI_Controller - Behavioral
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

entity SPI_Controller is
  Port (clk : in std_logic; -- main clock
        sclk : in std_logic; -- serial clock or sampling rate
        reset : in std_logic; -- reset button
        read_en : in std_logic; -- signal from main controller that it is ready to read a new word
        data_in_1 : in std_logic; -- data incoming from channel 1
        data_in_2 : in std_logic; -- data incoming from channel 2
        chip_sel : out std_logic; -- signal to tell ADC to start sending a new word
        data_out_1 : out std_logic_vector(11 downto 0); -- channel 1 output word
        data_out_2 : out std_logic_vector(11 downto 0)); -- channel 2 output word
end SPI_Controller;

architecture Behavioral of SPI_Controller is
    type State is  (idle, transmitting, load);
    signal control_state : state := idle;
--    signal padding_count : integer range 0 to 3 := 0;
    signal bit_count : integer range 0 to 15 := 0;
    signal channel_1_reg, channel_2_reg : std_logic_vector(15 downto 0) := (others => '0');
    signal sclk_prev : std_logic;
    signal data_en : std_logic;
begin
    data_en <= sclk and (not sclk_prev);
    process(clk) begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                channel_1_reg <= (others => '0');
                channel_2_reg <= (others => '0');
                control_state <= idle;
                bit_count <= 0;
                chip_sel <= '1';
                sclk_prev <= '0';
            else
                sclk_prev <= sclk;
                case (control_state) is
                    when idle => -- waiting for read to begin
                        chip_sel <= '1';
                        if(read_en = '1') then
                            control_state <= transmitting;
                            chip_sel <= '0';
                            bit_count <= 0;
                        end if;
                    when transmitting => -- shifts values in shift register to store transmitted words
                        if(data_en = '1') then 
                            channel_1_reg <= channel_1_reg(14 downto 0) & data_in_1;
                            channel_2_reg <= channel_2_reg(14 downto 0) & data_in_2;
                            if(bit_count = 15) then
                                bit_count <= 0;
                                control_state <= load;
                            else
                                bit_count <= bit_count + 1;
                            end if;
                        end if;
                    when load => -- loads output registers
                        data_out_1 <= channel_1_reg(11 downto 0);
                        data_out_2 <= channel_2_reg(11 downto 0);
                        chip_sel <= '1';
                        control_state <= idle;
                end case;
            end if;
            
        end if;
    end process;

end Behavioral;
