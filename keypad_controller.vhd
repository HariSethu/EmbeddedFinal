library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keypad_controller is
    Port (
        clk       : in  std_logic;
        rows      : in  std_logic_vector(3 downto 0);
        cols      : out std_logic_vector(3 downto 0);
        key_valid : out std_logic;
        key_data  : out std_logic_vector(3 downto 0)
    );
end keypad_controller;

architecture Behavioral of keypad_controller is

    signal scan_timer : integer range 0 to 125000 := 0;
    signal scan_tick  : std_logic := '0';

    type state_type is (SCAN_C1, SCAN_C2, SCAN_C3, SCAN_C4, WAIT_RELEASE);
    signal current_state : state_type := SCAN_C1;

    signal key_data_reg : std_logic_vector(3 downto 0) := (others => '0');

begin

    key_data <= key_data_reg;

    -- --------------------------------------------------------
    -- FIX 2: Drive cols COMBINATORIALLY - no register delay
    -- --------------------------------------------------------
    process(current_state)
    begin
        case current_state is
            when SCAN_C1      => cols <= "1110";
            when SCAN_C2      => cols <= "1101";
            when SCAN_C3      => cols <= "1011";
            when SCAN_C4      => cols <= "0111";
            when WAIT_RELEASE => cols <= "0000"; -- all cols low: any held key keeps a row low
        end case;
    end process;

    -- Scan timer (~1 ms tick at 125 MHz)
    process(clk)
    begin
        if rising_edge(clk) then
            if scan_timer = 125000 then
                scan_timer <= 0;
                scan_tick  <= '1';
            else
                scan_timer <= scan_timer + 1;
                scan_tick  <= '0';
            end if;
        end if;
    end process;

    -- --------------------------------------------------------
    -- FIX 1: Use a VARIABLE for the key-pressed flag so the
    --         check in the same tick sees the value just set
    -- --------------------------------------------------------
    process(clk)
        variable kp : std_logic;
    begin
        if rising_edge(clk) then
            key_valid <= '0';
            if scan_tick = '1' then
                kp := '0';  -- reset each tick
                case current_state is

                    when SCAN_C1 =>
                        if    rows = "1110" then key_data_reg <= x"1"; kp := '1';
                        elsif rows = "1101" then key_data_reg <= x"4"; kp := '1';
                        elsif rows = "1011" then key_data_reg <= x"7"; kp := '1';
                        elsif rows = "0111" then key_data_reg <= x"0"; kp := '1'; -- * key
                        end if;
                        if kp = '1' then key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C2; end if;

                    when SCAN_C2 =>
                        if    rows = "1110" then key_data_reg <= x"2"; kp := '1';
                        elsif rows = "1101" then key_data_reg <= x"5"; kp := '1';
                        elsif rows = "1011" then key_data_reg <= x"8"; kp := '1';
                        elsif rows = "0111" then key_data_reg <= x"F"; kp := '1'; -- FIX 3: was x"F"
                        end if;
                        if kp = '1' then key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C3; end if;

                    when SCAN_C3 =>
                        if    rows = "1110" then key_data_reg <= x"3"; kp := '1';
                        elsif rows = "1101" then key_data_reg <= x"6"; kp := '1';
                        elsif rows = "1011" then key_data_reg <= x"9"; kp := '1';
                        elsif rows = "0111" then key_data_reg <= x"E"; kp := '1'; -- # key
                        end if;
                        if kp = '1' then key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C4; end if;

                    when SCAN_C4 =>
                        if    rows = "1110" then key_data_reg <= x"A"; kp := '1';
                        elsif rows = "1101" then key_data_reg <= x"B"; kp := '1';
                        elsif rows = "1011" then key_data_reg <= x"C"; kp := '1';
                        elsif rows = "0111" then key_data_reg <= x"D"; kp := '1';
                        end if;
                        if kp = '1' then key_valid <= '1'; current_state <= WAIT_RELEASE;
                        else current_state <= SCAN_C1; end if;

                    when WAIT_RELEASE =>
                        -- cols="0000" so all rows pulled low if ANY key is still held
                        if rows = "1111" then current_state <= SCAN_C1; end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;