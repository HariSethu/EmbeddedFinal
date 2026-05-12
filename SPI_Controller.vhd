library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SPI_Controller is
  Port (clk        : in  std_logic;
        sclk       : out std_logic;
        reset      : in  std_logic;
        read_en    : in  std_logic;
        data_in_1  : in  std_logic;
        data_in_2  : in  std_logic;
        chip_sel   : out std_logic;
        --next_sample : out std_logic;
        --SPI_data_acq : out std_logic;
        data_out_1 : out std_logic_vector(11 downto 0);
        data_out_2 : out std_logic_vector(11 downto 0));
end SPI_Controller;

architecture Behavioral of SPI_Controller is
    type State is (idle, setup, transmitting, load);
    signal control_state  : State := idle;
    signal bit_count      : integer range 0 to 15 := 0;
    signal channel_1_reg, channel_2_reg : std_logic_vector(15 downto 0) := (others => '0');
    signal sclk_prev      : std_logic := '0';
    signal data_en        : std_logic;
    signal sclk_tick      : std_logic := '1';  -- idles high, first edge is falling
    signal counter        : integer range 0 to 20 := 0;
    signal setup_counter  : integer range 0 to 4 := 0;
    signal chip_sel_reg   : std_logic := '1';
    signal sclk_en        : std_logic := '0';
begin
    data_en <= sclk_tick and (not sclk_prev);

    -- SCLK generator - only runs when enabled, idles high
    process(clk) begin
        if falling_edge(clk) then
            if sclk_en = '1' then
                if counter = 20 then
                    counter   <= 0;
                    sclk_tick <= not sclk_tick;
                else
                    counter <= counter + 1;
                end if;
            else
                counter   <= 0;
                sclk_tick <= '1';  -- hold high until enabled
            end if;
        end if;
    end process;

    -- Main state machine
    process(clk) begin
        if falling_edge(clk) then
            if reset = '1' then
                channel_1_reg <= (others => '0');
                channel_2_reg <= (others => '0');
                control_state <= idle;
                bit_count     <= 0;
                chip_sel_reg  <= '1';
                sclk_prev     <= '0';
                data_out_1    <= (others => '0');
                data_out_2    <= (others => '0');
                setup_counter <= 0;
                sclk_en       <= '0';
--                next_sample <= '1';
--                SPI_data_acq <= '0';
            else
                sclk_prev <= sclk_tick;
--                SPI_data_acq <= '0';
                case control_state is

                    when idle =>
                        chip_sel_reg <= '1';
                        sclk_en      <= '0';
--                        next_sample <= '1';
                        if read_en = '1' then
                            chip_sel_reg  <= '0';
                            bit_count     <= 0;
                            setup_counter <= 0;
                            control_state <= setup;
--                            next_sample <= '0';
                        end if;

                    when setup =>
                        -- CS held low, SCLK still gated off
                        -- 4 falling edge cycles ~ 320ns, satisfies AD1 10ns minimum
                        if setup_counter = 4 then
                            setup_counter <= 0;
                            sclk_en       <= '1';
                            control_state <= transmitting;
                        else
                            setup_counter <= setup_counter + 1;
                        end if;

                    when transmitting =>
                        if data_en = '1' then
                            channel_1_reg <= channel_1_reg(14 downto 0) & data_in_1;
                            channel_2_reg <= channel_2_reg(14 downto 0) & data_in_2;
                            if bit_count = 15 then
                                bit_count     <= 0;
                                sclk_en       <= '0';
                                control_state <= load;
                            else
                                bit_count <= bit_count + 1;
                            end if;
                        end if;

                    when load =>
--                        SPI_data_acq <= '1';
                        data_out_1    <= channel_1_reg(12 downto 1);
                        data_out_2    <= channel_2_reg(12 downto 1);
                        chip_sel_reg  <= '1';
                        control_state <= idle;

                end case;
            end if;
        end if;
    end process;

    chip_sel <= chip_sel_reg;
    sclk     <= sclk_tick when chip_sel_reg = '0' else '1';

end Behavioral;