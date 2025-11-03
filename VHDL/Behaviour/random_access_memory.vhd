-- Random Access Memory with 1 read/write port

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- RAM entity
ENTITY ram32 IS
  PORT(
    I_clk : in std_logic;
    I_we : in std_logic;
    I_en : in std_logic;
    I_addr : in std_logic_vector(31 downto 0);
    I_data : in std_logic_vector(31 downto 0);
    O_data : out std_logic_vector(31 downto 0)
  );
end ram32;

architecture SYNTH_ram32 of ram32 is 
  type store_t is array (0 to 31) of std_logic_vector(31 downto 0);
  signal ram_32: store_t := (others => X"00000000");
begin
  process(I_clk)
  begin
    if (rising_edge(I_clk) AND (I_en = '1')) then
      if (I_we = '1') then
        ram_32(to_integer(unsigned(I_addr(10 downto 0)))) <= I_data;
      else
        O_data <= ram_32(to_integer(unsigned(I_addr(10 downto 0))));
      end if;
    end if;
  end process;
end SYNTH_ram32;