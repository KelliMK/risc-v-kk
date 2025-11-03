--! REGISTER FILE

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg32_32 is 
port (
	I_clk : in std_logic; --! clock bit
	I_en : in std_logic; --! enable bit
	I_dataD : in std_logic_vector(31 downto 0);
	O_data1 : out std_logic_vector(31 downto 0);
	O_data2 : out std_logic_vector(31 downto 0);
	I_sel1 : in std_logic_vector(4 downto 0);
	I_sel2 : in std_logic_vector(4 downto 0);
	I_selD : in std_logic_vector(4 downto 0);
	I_we : in std_logic --! write-enable bit
);
end reg32_32;

architecture SYNTH_reg32 of reg32_32 is
	type store_t is array (0 to 31) of std_logic_vector(31 downto 0);
	signal regs: store_t := (others => X"00000000");
begin
	process(I_clk)
	begin
		if rising_edge(I_clk) and (I_en='1') then
			O_data1 <= regs(to_integer(unsigned(I_sel1)));
			O_data2 <= regs(to_integer(unsigned(I_sel2)));
			if (I_we='1') then
				regs(to_integer(unsigned(I_selD))) <= I_dataD;
			end if;
		end if;
	end process;
end SYNTH_reg32;