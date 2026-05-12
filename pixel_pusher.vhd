library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_pusher is
    Port (
        clk           : in  std_logic;
        en            : in  std_logic;
        vid           : in  std_logic;
        hcount        : in  std_logic_vector(9 downto 0);
        vcount        : in  std_logic_vector(9 downto 0);
        
        bram_data_1   : in  std_logic_vector(11 downto 0);
        bram_data_2   : in  std_logic_vector(11 downto 0);
        
        key_valid     : in  std_logic;
        key_data      : in  std_logic_vector(3 downto 0);
        
        jstk_y        : in  std_logic_vector(9 downto 0);
        jstk_tick     : in  std_logic;
        
        pixel_read_en : in  std_logic;
        frozen_out    : out std_logic;  -- tells Main_Controller to stop writing BRAM
        
        R             : out std_logic_vector(4 downto 0);
        G             : out std_logic_vector(5 downto 0);
        B             : out std_logic_vector(4 downto 0);
        read_addr     : out std_logic_vector(11 downto 0)
    );
end pixel_pusher;

architecture Behavioral of pixel_pusher is
    
    signal x_pos, y_pos    : unsigned(9 downto 0);
    
    signal active_channel  : std_logic := '0';
    signal current_scale   : integer range 0 to 7 := 3;
    signal frozen          : std_logic := '0';
    
    signal active_adc_val  : unsigned(11 downto 0);
    signal scaled_adc_val  : unsigned(9 downto 0);
    signal wave_y_pos      : unsigned(9 downto 0);
    
    -- One cycle pipeline register to compensate for BRAM read latency
    -- BRAM outputs data for x_pos N on cycle N+1, so we delay
    -- wave_y_pos by one cycle to stay aligned with the correct column
    signal wave_y_pos_r    : unsigned(9 downto 0) := to_unsigned(240, 10);

begin

    x_pos <= unsigned(hcount);
    y_pos <= unsigned(vcount);
    
    -- Always drive read address from x_pos so BRAM is pre-fetching
    -- the correct column data ahead of the drawing comparison
    read_addr <= std_logic_vector(resize(x_pos, 12));
    
    -- Export freeze flag so Main_Controller can gate BRAM writes
    frozen_out <= frozen;

    -- Channel select MUX - both channels always available from BRAM,
    -- we pick which one to display
    active_adc_val <= unsigned(bram_data_1) when active_channel = '0'
                      else unsigned(bram_data_2);

    -- Amplitude scale via right shift
    scaled_adc_val <= resize(shift_right(active_adc_val, current_scale), 10);

    -- Y coordinate mapping:
    --   ADC = 0    -> y = 480 (bottom, 0V)
    --   ADC = mid  -> y = 240 (center)
    --   ADC = full -> y = 0   (top, full scale)
    wave_y_pos <= to_unsigned(240, 10) + (to_unsigned(240, 10) - scaled_adc_val)
                  when scaled_adc_val <= 240
                  else to_unsigned(0, 10);

    -- ── PROCESS 1: BRAM Latency Compensation + UI ────────────
    process(clk)
        variable joy_y_val : integer;
    begin
        if rising_edge(clk) then

            -- Pipeline register: delay wave_y_pos by 1 cycle to align
            -- with the BRAM output latency so we draw at the right x column
            wave_y_pos_r <= wave_y_pos;

            -- Keypad controls
            if key_valid = '1' then
                case key_data is
                    when x"A" => active_channel <= '0';    -- CH1
                    when x"B" => active_channel <= '1';    -- CH2
                    when x"C" => frozen <= not frozen;     -- freeze toggle
                    when x"3" => current_scale <= 3;       -- reset zoom
                    when others => null;
                end case;
            end if;

            -- Joystick zoom, disabled when frozen
            if jstk_tick = '1' and frozen = '0' then
                joy_y_val := to_integer(unsigned(jstk_y));
                if joy_y_val > 800 and current_scale > 0 then
                    current_scale <= current_scale - 1;
                elsif joy_y_val < 200 and current_scale < 7 then
                    current_scale <= current_scale + 1;
                end if;
            end if;

        end if;
    end process;

    -- ── PROCESS 2: VGA Drawing ────────────────────────────────
    -- Uses wave_y_pos_r (latency-compensated) for comparison.
    -- This updates every pixel column from live BRAM data,
    -- producing a proper waveform shape instead of a flat line.
    -- When frozen=1, Main_Controller stops writing BRAM so the
    -- same data keeps being read - natural freeze with no latch needed.
    process(clk)
        variable y_diff : integer;
    begin
        if rising_edge(clk) then
            if en = '1' then
                if vid = '1' then

                    y_diff := to_integer(y_pos) - to_integer(wave_y_pos_r);

                    if y_diff >= -1 and y_diff <= 1 then
                        if active_channel = '0' then
                            R <= "11111"; G <= "111111"; B <= "00000"; -- Yellow CH1
                        else
                            R <= "00000"; G <= "111111"; B <= "11111"; -- Cyan   CH2
                        end if;

                    elsif (x_pos mod 64 = 0) or (y_pos mod 64 = 0) then
                        if frozen = '1' then
                            R <= "00000"; G <= "011000"; B <= "00000"; -- Brighter green
                        else
                            R <= "00000"; G <= "010000"; B <= "00000"; -- Dark green
                        end if;

                    else
                        R <= (others => '0');
                        G <= (others => '0');
                        B <= (others => '0');
                    end if;

                else
                    R <= (others => '0');
                    G <= (others => '0');
                    B <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end Behavioral;