LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.my_constants.all;

entity alu is 
port(
	I_clk : in std_logic;	--! clock bit
	I_PC : in std_logic_vector(31 downto 0); --! Program counter
	I_en : in std_logic; --! enable bit
	I_dataRS1 : in std_logic_vector(31 downto 0); --! rs1 data
	I_dataRS2 : in std_logic_vector(31 downto 0); --! rs2 data
	I_dataDwe : in std_logic; --! rd write enable bit
	I_dataIMM : in std_logic_vector(31 downto 0); --! immediate/offset
	I_aluop : in std_logic_vector(5 downto 0); --! alu op code
	O_byte_mode : out std_logic; --! patch for SB and LBU
	O_ram_addr : out std_logic_vector(31 downto 0); --! RAM address for store and load operations
	O_ram_we : out std_logic; -- mainly used by store instructions, for writing to RAM
	O_newBranch : out std_logic_vector(31 downto 0); --! new branch instruction
	O_dataResult : out std_logic_vector(31 downto 0); --! result of ALU calculation
	O_dataWriteToReg : out std_logic; --! we writing to a fookin register?
  O_use_ram : out std_logic; --! ram out to register file
	O_takeBranch : out std_logic --! tells PC to increment when 0, or to branch when 1
);
end alu;

architecture SYNTH_alu of alu is
	--! add an extra bit for overflow operations, I guess
	signal s_result: std_logic_vector(31 downto 0) := (others => '0');
	signal s_aux: std_logic_vector(31 downto 0) := (others => '0');
	signal s_aux2: std_logic_vector(31 downto 0) := (others => '0');
	signal s_newBranch: std_logic_vector(31 downto 0) := (others => '0');
	signal s_takeBranch: std_logic := '0';
	signal s_use_ram: std_logic := '0';
	signal s_byte_mode: std_logic := '0';

begin
	process(I_clk, I_en)
	begin
		if rising_edge(I_clk) and (I_en = '1') then
			s_aux <= "00000000000000000000000000000000";
			s_aux2 <= "00000000000000000000000000000000";
			s_use_ram <= '0';
			O_dataWriteToReg <= I_dataDwe;
			O_ram_we <= '0'; --! default to no writing to RAM
			O_ram_addr <= "00000000000000000000000000000000"; --! default to RAM address 0x00000000
			s_byte_mode <= '0';
			case I_aluop(5 downto 0) is 
				--! I know I should have started at 0 but RV32I only has 52 
				--! instructions in its expanded instruction set, so it'll fit 

				when OP_LUI => --! LUI
					s_result(31 downto 0) <= I_dataIMM;
					s_takeBranch <= '0';
				when OP_AUIPC => --! AUIPC
					s_result <= std_logic_vector(unsigned(I_dataIMM) + unsigned(I_PC));
					s_takeBranch <= '0';
				when OP_JAL => --! JAL
					s_aux <= I_dataIMM;
					s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
					s_newBranch <= std_logic_vector(unsigned(I_PC) + unsigned(s_aux2));
					s_result <= std_logic_vector(unsigned(I_PC) + "00000000000000000000000000100000");
					s_takeBranch <= '1';
				when OP_BEQ => --! BEQ
					if (signed(I_dataRS1) = signed(I_dataRS2)) then
						s_aux <= I_dataIMM;
						s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
						s_newBranch <= std_logic_vector(unsigned(I_PC) + unsigned(s_aux2));
						s_takeBranch <= '1';
					else
						s_takeBranch <= '0';
					end if;
				when OP_BNE => --! BNE
					if (signed(I_dataRS1) /= signed(I_dataRS2)) then
						s_aux <= I_dataIMM;
						s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
						s_newBranch <= std_logic_vector(unsigned(I_PC) + unsigned(s_aux2));
						s_takeBranch <= '1';
					else
						s_takeBranch <= '0';
					end if;
				when OP_BLT => --! BLT
					if (signed(I_dataRS1) < signed(I_dataRS2)) then
						s_aux <= I_dataIMM;
						s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
						s_newBranch <= std_logic_vector(unsigned(I_PC) + unsigned(s_aux2));
						s_takeBranch <= '1';
					else
						s_takeBranch <= '0';
					end if;
				when OP_BGE => --! BGE
					if (signed(I_dataRS1) >= signed(I_dataRS2)) then
						s_aux <= I_dataIMM;
						s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
						s_newBranch <= std_logic_vector(unsigned(I_PC) + unsigned(s_aux2));
						s_takeBranch <= '1';
					else
						s_takeBranch <= '0';
					end if;
				when OP_JALR => --! JALR
					s_aux <= I_dataIMM;
					s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
					s_newBranch <= std_logic_vector(unsigned(I_PC) + unsigned(s_aux2));
					s_result <= std_logic_vector(unsigned(I_PC) + "00000000000000000000000000100000");
					s_takeBranch <= '1';
				when OP_LW => --! LW
					s_aux <= I_dataIMM;
					s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
					O_ram_addr <= std_logic_vector(unsigned(I_dataRS1) + unsigned(s_aux2));
					s_takeBranch <= '0';
					s_use_ram <= '1';
				when OP_LBU => --! LBU
					s_aux <= I_dataIMM;
					s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
					O_ram_addr <= std_logic_vector(unsigned(I_dataRS1) + unsigned(s_aux2));
					s_takeBranch <= '0';
					s_use_ram <= '1';
					s_byte_mode <= '1';
				when OP_ADDI => --! ADDI
					s_result <= std_logic_vector(signed(I_dataIMM) + signed(I_dataRS1));
					s_takeBranch <= '0';
				when OP_SLTI => --! SLTI
					if (signed(I_dataRS1) < signed(I_dataIMM)) then
						s_result <= "00000000000000000000000000000001";
					else
						s_result <= "00000000000000000000000000000000";
					end if;
					s_takeBranch <= '0';
				when OP_XORI => --! XORI
					s_result(31 downto 0) <= I_dataRS1 XOR I_dataIMM;
					s_takeBranch <= '0';
				when OP_ORI => --! ORI
					s_result(31 downto 0) <= I_dataRS1 OR I_dataIMM;
					s_takeBranch <= '0';
				when OP_ANDI => --! ANDI
					s_result(31 downto 0) <= I_dataRS1 AND I_dataIMM;
					s_takeBranch <= '0';
				when OP_SB => --! SB
					s_aux <= I_dataIMM;
					s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
					O_ram_addr <= std_logic_vector(unsigned(I_dataRS1) + unsigned(s_aux2));
					O_ram_we <= '1';
					s_result(31 downto 8) <= "000000000000000000000000";
					s_result(7 downto 0) <= I_dataRS2(7 downto 0);
					s_takeBranch <= '0';
					s_byte_mode <= '1';
				when OP_SH => --! SH
					s_aux <= I_dataIMM;
					s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
					O_ram_addr <= std_logic_vector(unsigned(I_dataRS1) + unsigned(s_aux2));
					O_ram_we <= '1';
					s_result(31 downto 16) <= "0000000000000000";
					s_result(15 downto 0) <= I_dataRS2(15 downto 0);
					s_takeBranch <= '0';
					s_use_ram <= '1';
				when OP_SW => --! SW
					s_aux <= I_dataIMM;
					s_aux2(31 downto 0) <= (s_aux(28 downto 0) & "000");
					O_ram_addr <= std_logic_vector(unsigned(I_dataRS1) + unsigned(s_aux2));
					O_ram_we <= '1';
					s_result <= I_dataRS2;
					s_takeBranch <= '0';
					s_use_ram <= '1';
				when OP_SLLI => --! SLLI
					s_takeBranch <= '0';
					s_result <= std_logic_vector(SHIFT_LEFT(unsigned(I_dataRS1), to_integer(unsigned(I_dataIMM))));
				when OP_ADD => --! ADD 
					s_result(31 downto 0) <= std_logic_vector(unsigned(I_dataRS1) + unsigned(I_dataRS2));
					s_takeBranch <= '0';
				when OP_SUB => --! SUB
					s_result(31 downto 0) <= std_logic_vector(signed(I_dataRS1) - signed(I_dataRS2));
					s_takeBranch <= '0';
				when OP_SLL => --! SLL
					s_result(31 downto 0) <= std_logic_vector(SHIFT_LEFT(unsigned(I_dataRS1), to_integer(unsigned(I_dataRS2(4 downto 0))))); 
					s_takeBranch <= '0';
				when OP_SLT => --! SLT
					if (signed(I_dataRS1) < signed(I_dataRS2)) then
						s_result <= "00000000000000000000000000000001";
					else
						s_result <= "00000000000000000000000000000000";
					end if;
					s_takeBranch <= '0';
				when OP_SLTU => --! SLTU
					if (unsigned(I_dataRS1) < unsigned(I_dataRS2)) then
						s_result <= "00000000000000000000000000000001";
					else
						s_result <= "00000000000000000000000000000000";
					end if;
					s_takeBranch <= '0';
				when OP_XOR => --! XOR
					s_result(31 downto 0) <= I_dataRS1 XOR I_dataRS2;
					s_takeBranch <= '0';
				when OP_SRL => --! SRL
					s_result <= std_logic_vector((signed(I_dataRS1) SRL to_integer(unsigned(I_dataRS2(4 downto 0)))));
					s_takeBranch <= '0';
				when OP_SRA => --! SRA
					s_result <= std_logic_vector(shift_right(unsigned(I_dataRS1), to_integer(unsigned(I_dataRS2(4 downto 0)))));
					s_takeBranch <= '0';
				when OP_OR => --! OR
					s_result(31 downto 0) <= I_dataRS1 OR I_dataRS2; 
					s_takeBranch <= '0';
				when OP_AND => --! AND
					s_result(31 downto 0) <= I_dataRS1 AND I_dataRS2;
					s_takeBranch <= '0';
				when OP_ECALL => --! ECALL
					s_takeBranch <= '0';
					s_result(31 downto 0) <= X"00000003";
				when others =>
					s_result(31 downto 0) <= X"FFFFFFFC";
			end case;
		end if;

	O_byte_mode <= s_byte_mode;
	O_dataResult <= s_result(31 downto 0);
	O_newBranch <= s_newBranch;
	O_takeBranch <= s_takeBranch;
	O_use_ram <= s_use_ram;

	end process;
end SYNTH_alu;