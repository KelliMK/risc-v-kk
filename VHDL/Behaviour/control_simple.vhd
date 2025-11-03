library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity control_simple is
	PORT (
		I_clk : in std_logic;
		I_reset : in std_logic;
		I_aluop : in std_logic_vector(5 downto 0);
		O_state : out std_logic_vector(5 downto 0)
	);
end control_simple;

architecture SYNTH_control of control_simple is
	signal s_state: std_logic_vector(5 downto 0) := "000001";
begin
	process(I_clk)
	begin
		if rising_edge(I_clk) then
			if I_reset = '1' then
				s_state <= "000001";
			else
				case s_state is 
          when "000001" =>
           	s_state <= "000010";
					when "000010" =>
						s_state <= "000100";
					when "000100" =>
						s_state <= "001000";
					when "001000" =>
						--! memory/writeback
						--! if it's not a memory function, go to writeback
						if ((I_aluop = "001101") OR (I_aluop = "011000")) then
							s_state <= "010000";	--! memory state
						else
							s_state <= "100000";	--! writeback state
						end if;
					when "010000" =>
						s_state <= "100000";
					when "100000" =>
						s_state <= "000001"; --! fetch state
					when others =>
						s_state <= "000001";
				end case;
			end if;
		end if;
	end process;
	O_state <= s_state;
	
end architecture SYNTH_control;