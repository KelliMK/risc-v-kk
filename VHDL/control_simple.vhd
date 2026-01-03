library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library work; --! I know using work is a bad idea, but I don't care right now
use work.my_constants.all;

entity control_simple is
	PORT (
		I_clk : in std_logic; --! clock
		I_reset : in std_logic; --! reset signal
		I_aluop : in std_logic_vector(5 downto 0); --! constants
		O_state : out std_logic_vector(8 downto 0) --! 9 bit state value
	);
end control_simple;

architecture SYNTH_control of control_simple is
	signal s_state: std_logic_vector(8 downto 0) := "000000001";
begin
	process(I_clk)
	begin
		if rising_edge(I_clk) then
			if I_reset = '1' then
				s_state <= "000000001";
			else
				case s_state is 
					when "000000001" => --! instruction load state
						s_state <= "000000010";

          when "000000010" => --! fetch state
           	s_state <= "000000100";

					when "000000100" => --! decoder state
						s_state <= "000001000";

					when "000001000" => --! register read state
						s_state <= "000010000";

					when "000010000" => --! ALU state
						--! if it's not a memory function, go to writeback
						if ((I_aluop = OP_SW) OR (I_aluop = OP_LW) OR (I_aluop = OP_LBU) OR (I_aluop = OP_SB)) then
							s_state <= "000100000";
						else
							s_state <= "100000000";
						end if;

					when "000100000" => --! L1 cache state
						s_state <= "001000000";

					when "001000000" => --! L2 cache state
						s_state <= "010000000";

					when "010000000" => --! memory state
						s_state <= "100000000";

					when "100000000" => --! writeback state
						s_state <= "000000010"; 

					when others => --! shouldn't be reachable, but still
						s_state <= "000000001";
				end case;
			end if;
		end if;
	end process;
	O_state <= s_state;
	
end architecture SYNTH_control;