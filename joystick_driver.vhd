library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity joystick_controller is
    Port (
        clk       : in  STD_LOGIC;
        miso      : in  STD_LOGIC;
        mosi      : out STD_LOGIC;
        cs        : out STD_LOGIC;
        sclk      : out STD_LOGIC;
        jstk_y    : out STD_LOGIC_VECTOR(9 downto 0);
        jstk_tick : out STD_LOGIC
    );
end joystick_controller;

architecture Behavioral of joystick_controller is

    -- Fix 1: 125 MHz / 12 = ~10.4 MHz sclk_en -> ~5.2 MHz SCLK (within JSTK2's 1-66 MHz range)
    signal clk_div    : integer range 0 to 11 := 0;
    signal sclk_en    : std_logic := '0';

    -- Poll every 10 ms: 125 MHz * 0.01 = 1,250,000 cycles
    signal poll_timer : integer range 0 to 1249999 := 0;
    signal start_read : std_logic := '0';

    type state_type is (IDLE, DELAY_15US, SHIFT_BYTE, DELAY_10US, CS_HIGH_WAIT);
    signal state : state_type := IDLE;

    signal shift_reg  : std_logic_vector(39 downto 0) := (others => '0');
    signal bit_count  : integer range 0 to 7 := 0;
    signal byte_count : integer range 0 to 4 := 0;

    -- Fix 3: delay_cnt needs wider range for 15us/10us at 10.4 MHz sclk_en rate
    -- 15 us * 10.4 MHz = ~156 ticks; 10 us * 10.4 MHz = ~104 ticks
    signal delay_cnt  : integer range 0 to 200 := 0;
    signal sclk_reg   : std_logic := '0';

    signal jstk_y_reg   : std_logic_vector(9 downto 0) := (others => '0');
    signal startup_done : std_logic := '0';
    signal startup_cnt  : integer range 0 to 62500000 := 0;

begin

    mosi   <= '0';
    sclk   <= sclk_reg;
    jstk_y <= jstk_y_reg;

    -- ~10.4 MHz timing tick; SCLK toggles on each tick -> ~5.2 MHz SPI clock
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_div = 11 then
                clk_div <= 0;
                sclk_en <= '1';
            else
                clk_div <= clk_div + 1;
                sclk_en <= '0';
            end if;
        end if;
    end process;

    -- Fix 2: start_read driven by ONE process only (single-cycle pulse via default '0')
    -- 500 ms startup delay, then assert start_read for exactly one clock every 10 ms
    process(clk)
    begin
        if rising_edge(clk) then
            start_read <= '0';          -- default: de-assert every cycle

            if startup_done = '0' then
                if startup_cnt = 62500000 then
                    startup_done <= '1';
                    startup_cnt  <= 0;
                else
                    startup_cnt <= startup_cnt + 1;
                end if;
            else
                if poll_timer = 1249999 then
                    poll_timer <= 0;
                    start_read <= '1';  -- single-cycle pulse, overrides default above
                else
                    poll_timer <= poll_timer + 1;
                end if;
            end if;
        end if;
    end process;

    -- SPI FSM
    process(clk)
    begin
        if rising_edge(clk) then
            jstk_tick <= '0';

            case state is

                when IDLE =>
                    cs       <= '1';
                    sclk_reg <= '0';
                    -- Fix 2: start_read is read-only here; never written by FSM
                    if start_read = '1' then
                        cs         <= '0';
                        delay_cnt  <= 0;
                        bit_count  <= 0;
                        byte_count <= 0;
                        state      <= DELAY_15US;
                    end if;

                -- 15 us CS-to-SCLK setup delay: 156 ticks at 10.4 MHz ~ 15 us
                when DELAY_15US =>
                    if sclk_en = '1' then
                        if delay_cnt = 155 then
                            delay_cnt  <= 0;
                            bit_count  <= 0;
                            byte_count <= 0;
                            state      <= SHIFT_BYTE;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;
                    end if;

                when SHIFT_BYTE =>
                    if sclk_en = '1' then
                        if sclk_reg = '0' then
                            -- Rising edge: sample MISO (SPI Mode 0)
                            sclk_reg  <= '1';
                            shift_reg <= shift_reg(38 downto 0) & miso;
                        else
                            -- Falling edge: advance bit/byte counters
                            sclk_reg <= '0';
                            if bit_count = 7 then
                                -- Fix 3: reset bit_count here on byte boundary
                                bit_count <= 0;
                                if byte_count = 4 then
                                    delay_cnt <= 0;
                                    state     <= CS_HIGH_WAIT;
                                else
                                    byte_count <= byte_count + 1;
                                    delay_cnt  <= 0;
                                    state      <= DELAY_10US;
                                end if;
                            else
                                bit_count <= bit_count + 1;
                            end if;
                        end if;
                    end if;

                -- 10 us inter-byte gap: 104 ticks at 10.4 MHz ~ 10 us
                when DELAY_10US =>
                    if sclk_en = '1' then
                        if delay_cnt = 103 then
                            delay_cnt <= 0;
                            state     <= SHIFT_BYTE;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;
                    end if;

                when CS_HIGH_WAIT =>
                    cs <= '1';
                    if sclk_en = '1' then
                        -- Fix 4: correct 10-bit Y extraction from JSTK2 5-byte protocol:
                        -- Byte0=shift_reg[39:32] X_lo, Byte1=shift_reg[31:24] X_hi,
                        -- Byte2=shift_reg[23:16] Y_lo, Byte3=shift_reg[15:8]  Y_hi,
                        -- Byte4=shift_reg[7:0]   buttons
                        -- Y[9:8] = Y_hi[1:0] = shift_reg[9:8]
                        -- Y[7:0] = Y_lo[7:0] = shift_reg[23:16]
                        jstk_y_reg <= shift_reg(9 downto 8) & shift_reg(23 downto 16);
                        jstk_tick  <= '1';
                        state      <= IDLE;
                    end if;

            end case;
        end if;
    end process;

end Behavioral;