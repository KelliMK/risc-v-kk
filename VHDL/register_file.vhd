--! REGISTER FILE

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg32_32 is 
port (
	I_clk : in std_logic; --! clock bit
	I_en : in std_logic; --! enable component bit
	I_data_alu : in std_logic_vector(31 downto 0); --! register data from the ALU
	I_data_ram : in std_logic_vector(31 downto 0); --! register data from caches/RAM
	I_ram_en : in std_logic; --! enable ram data bit, indicates use of ram output
	I_sel1 : in std_logic_vector(4 downto 0); --! selects rs1
	I_sel2 : in std_logic_vector(4 downto 0); --! selects rs2
	I_selD : in std_logic_vector(4 downto 0); --! selects rd
	I_we : in std_logic; --! write-enable bit
	O_dataRS1 : out std_logic_vector(31 downto 0); --! outbound data from rs1
	O_dataRS2 : out std_logic_vector(31 downto 0) --! outbound data from rs2
);
end reg32_32;

architecture SYNTH_reg32 of reg32_32 is
	type store_t is array (0 to 31) of std_logic_vector(31 downto 0);
	signal regs: store_t := (others => "00000000000000000000000000000000");
begin
	process(I_clk)
	begin
		if rising_edge(I_clk) and (I_en='1') then
			O_dataRS1 <= regs(to_integer(unsigned(I_sel1)));
			O_dataRS2 <= regs(to_integer(unsigned(I_sel2)));
			if (I_we='1') then
				if (I_ram_en = '1') then
					regs(to_integer(unsigned(I_selD))) <= I_data_ram;
				else
					regs(to_integer(unsigned(I_selD))) <= I_data_alu;
				end if;
			end if;
		end if;
	end process;
end SYNTH_reg32;