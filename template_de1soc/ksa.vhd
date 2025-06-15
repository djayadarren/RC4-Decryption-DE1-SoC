library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ksa is
  port(
    CLOCK_50            : in  std_logic;  -- Clock pin
    KEY                 : in  std_logic_vector(3 downto 0);  -- push button switches
    SW                 : in  std_logic_vector(9 downto 0);  -- slider switches
    LEDR : out std_logic_vector(9 downto 0);  -- red lights
    HEX0 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0);
    HEX2 : out std_logic_vector(6 downto 0);
    HEX3 : out std_logic_vector(6 downto 0);
    HEX4 : out std_logic_vector(6 downto 0);
    HEX5 : out std_logic_vector(6 downto 0));
end ksa;

architecture rtl of ksa is
   COMPONENT SevenSegmentDisplayDecoder IS
    PORT
    (
        ssOut : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        nIn : IN STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
    END COMPONENT;
   
    -- clock and reset signals  
	signal clk, reset_n : std_logic;

    -- Internal memory for S-array
    type s_array_t is array (0 to 255) of std_logic_vector(7 downto 0);
    signal s           : s_array_t;

    -- Index counter and state flag
    signal i           : unsigned(7 downto 0) := (others => '0');
    signal initializing : std_logic := '1';										

begin
    clk <= CLOCK_50;
    reset_n <= KEY(3); -- Active-high reset

    -- Sequential initialization logic
    process(clk, reset_n)
    begin
        if reset_n = '1' then
        i <= (others => '0');
        initializing <= '1';
        elsif rising_edge(clk) then
        if initializing = '1' then
            s(to_integer(i)) <= std_logic_vector(i);
            if i = x"FF" then
            initializing <= '0';
            else
            i <= i + 1;
            end if;
        end if;
        end if;
    end process;

end rtl;

