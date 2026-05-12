----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/06/2026 06:31:23 PM
-- Design Name: 
-- Module Name: Main_Controller - Behavioral
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

entity Main_Controller is
  Port (
        -- Universal Signals
        clk : in std_logic;
        reset : in std_logic;
        
        -- SPI Controller
        SPI_data_acq : in std_logic;
        next_sample : in std_logic;
        SPI_data_in_1 : in std_logic_vector(11 downto 0);
        SPI_data_in_2 : in std_logic_vector(11 downto 0);
        SPI_read_en : out std_logic;
        
        -- Dual Port Ram 1
        fb_addr_1 : out std_logic_vector(11 downto 0);
        fb_wr_en_1 : out std_logic;
        fb_data_out_1 : out std_logic_vector(11 downto 0);
        
        -- Dual Port Ram 2
        fb_addr_2 : out std_logic_vector(11 downto 0);
        fb_wr_en_2 : out std_logic;
        fb_data_out_2 : out std_logic_vector(11 downto 0);
        
        -- VGA
        vsync : in std_logic;
        pixel_read_en : out std_logic;
        
        -- NEW: freeze signal from pixel_pusher
        -- When high, hold in VGA_disp indefinitely so BRAM
        -- stops receiving new writes and display stays locked
        frozen : in std_logic
   );
end Main_Controller;

architecture Behavioral of Main_Controller is
    type state is(
                        idle,
                        SPI_read,
                        conversion,
                        fb_write,
                        VGA_disp,
                        delay);
    signal control_state : state := idle;
    signal SPI_data_1, SPI_data_2 : std_logic_vector(11 downto 0) := (others => '0');
    signal samp_speed : integer range 0 to 399;
    signal trigger_read : std_logic := '0';
    signal millivolt_conv : std_logic_vector(11 downto 0) := "110011100100";
    signal millivolt_1,millivolt_2 : std_logic_vector(23 downto 0);
    signal mem_counter : integer range 0 to 640;
    signal delay_counter : integer range 0 to 6;
    signal trigger_pending: std_logic := '0';
    
begin

    process(clk) begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                SPI_data_1 <= (others => '0');
                SPI_data_2 <= (others => '0');
                control_state <= idle;
                SPI_read_en <= '0';
                mem_counter <= 0;
                pixel_read_en <= '0';
                fb_wr_en_1 <= '1';
                fb_wr_en_2 <= '0';
                trigger_pending <= '0';
            else
                if trigger_read = '1' then
                    trigger_pending <= '1'; end if;
                SPI_read_en <= '0';
                pixel_read_en <= '0';
                fb_wr_en_1 <= '0';
                fb_wr_en_2 <= '0';
                case(control_state) is
                    when idle =>
                        if((next_sample = '1') and (trigger_pending = '1') and (mem_counter < 640)) then
                            control_state <= SPI_read;
                            SPI_read_en <= '1';
                            trigger_pending <= '0';
                        elsif(mem_counter = 640) then
                            control_state <= VGA_disp;
                            pixel_read_en <= '1';
                            mem_counter <= 0;
                        end if;
                        
                    when SPI_read =>
                        if(SPI_data_acq = '1') then 
                            SPI_data_1 <= SPI_data_in_1;
                            SPI_data_2 <= SPI_data_in_2;
                            control_state <= conversion;
                        end if;                        
                    
                    when conversion =>
                        millivolt_1 <= std_logic_vector(unsigned(millivolt_conv) * unsigned(SPI_data_1));
                        millivolt_2 <= std_logic_vector(unsigned(millivolt_conv) * unsigned(SPI_data_2));
                        control_state <= fb_write;
                        
                    when fb_write =>
                        fb_wr_en_1 <= '1';
                        fb_data_out_1 <= millivolt_1(23 downto 12);
                        fb_addr_1 <= std_logic_vector(to_unsigned(mem_counter,12));
                        
                        fb_wr_en_2 <= '1';
                        fb_data_out_2 <= millivolt_2(23 downto 12);
                        fb_addr_2 <= std_logic_vector(to_unsigned(mem_counter,12));
                        
                        mem_counter <= mem_counter + 1;
                        control_state <= delay;
                        
                    when delay =>
                        if(delay_counter = 6) then
                            delay_counter <= 0;
                            control_state <= idle;
                        else
                            delay_counter <= delay_counter + 1;
                        end if;
                        
                    when VGA_disp =>
                        -- NEW: only exit VGA_disp if vsync fires AND display
                        -- is not frozen. When frozen=1 we stay here indefinitely,
                        -- keeping BRAM writes stopped and the display locked.
                        if(vsync = '0' and frozen = '0') then
                            control_state <= idle;
                        end if;
                    
                end case;
            end if;
        end if;
    end process;
    
    Sample_speed : process(clk) begin
        if(rising_edge(clk)) then
            if(samp_speed = 399) then
                samp_speed <= 0;
                trigger_read <= '1';
            else
                trigger_read <= '0';
                samp_speed <= samp_speed + 1;
            end if;
        end if;
    end process Sample_speed;

end Behavioral;