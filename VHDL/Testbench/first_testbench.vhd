--! First testbench file
--! for operation please load decoder.vhd, random_access_memory.vhd, 
--!      program_counter.vhd, register_file.vhd, alu.vhd, 
--!      control_simple.vhd, and constants.vhd 
--! onto EDAplayground along with this file, and set d_a_r_cs_tb to
--! your top entity for testing

--! first_test_feed.txt and first_proper_outputs.txt
--!   help illustrate this file

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.my_constants.all;

entity ram_tb is 
	PORT(
		I_clk : in STD_LOGIC;
    I_we : in STD_LOGIC;
    I_en : in STD_LOGIC;
    I_addr : in STD_LOGIC_VECTOR (31 downto 0);
    I_data : in STD_LOGIC_VECTOR (31 downto 0);
    O_data : out STD_LOGIC_VECTOR (31 downto 0)
	);
end ram_tb;

architecture SYNTH_ram_tb of ram_tb is
  type store_t is array (0 to 31) of std_logic_vector(31 downto 0);
  signal ram: store_t := (
  	"00000000000000000001010000110111", --! addr: Hx000 	LUI:   loads value Dx4096 into r8
  	"00000000000000000010010010110111",	--! addr: Hx020 	LUI:   loads value Dx8192 into r9
  	"00000000100101000010100100110011",	--! addr: Hx040 	SLT:   sets r18 to 1 if r8 < r9
  	"00000000100101000000100110110011",	--! addr: Hx060 	ADD:   adds values in r8 and r9 together into r19
  	"01000001001010011000101000110011",	--! addr: Hx080 	SUB:   subtracts r18 from reg 19 and stores in reg 20
  	"00000001010010011100101010110011",	--! addr: Hx0A0 	XOR:   XORs r19 and r20 into r21
  	"00000001010010011110101100110011",	--! addr: Hx0C0 	OR:    ORs r19 and r20 into r22 
  	"00000001011010010111101110110011",	--! addr: Hx0E0 	AND:   ANDs r18 and r22 into r23
  	"01000001001010101101110000110011",	--! addr: Hx100 	SRA:   shifts r21 right by r18 into r24
  	"00000000000000000001110010010111",	--! addr: Hx120 	AUIPC: adds the PC (currently Hx120) and Hx1000 into r25
  	"00000001001011001001110010110011",	--! addr: Hx140 	SLL:   shifts r25 left by r18 into r25
  	"11111111011011001100000011100011",	--! addr: Hx160 	BLT:   branches to previous instruction if r25 < r22
  	"00000101011110010000000001100011",	--! addr: Hx180 	BEQ:   branches two instructions ahead if r18 == r22
  	"00000000000111000000110000010011",	--! addr: Hx1A0 	ADDI:  adds Dx1 to r24 into r24
  	"00000000000000000010000000100011",	--! addr: Hx1C0 	SW:    Does nothing due to lack of FPGA
  	"11111101100001000001000011100011",	--! addr: Hx1E0 	BNE:   branches two insts back if r8 and r24 are not equal
  	"00000000000000000010110100000011",	--! addr: Hx200 	LW:    due to dummy code, loads Hx55555555 into r26
  	"01010101010111010111110110010011",	--! addr: Hx220 	ANDI:  ANDs Hx00000555 and r26 into r27
  	"10101010101011011100111000010011",	--! addr: Hx240 	XORI:  XORs HxFFFFFAAA and r27 into r28
  	"00101010101010011110111010010011",	--! addr: Hx260 	ORI:   ORs Hx000002AA and r19 into r29
  	"00000001110011101011111100110011",	--! addr: Hx280 	SLTU:  if r29 < r28 (unsigned) puts 1 into r30
  	"00000000000011100010111110010011",	--! addr: Hx2A0 	SLTI:  if r28 < 0 puts 1 in r31
  	"00000001001011100101111000110011",	--! addr: Hx2C0 	SRL:   shift r28 to the right by r18, into r28
  	"00001111010011101101000001100011",	--! addr: Hx2E0 	BGE:   if r29 > r20, shift 7 instructions ahead
  	"01010010101010101010010100101011",	--! addr: Hx300 	GARBAGE
  	"10101010101001010101101011010111",	--! addr: Hx320 	GARBAGE
  	"01010101010110101010010100101011",	--! addr: Hx340 	GARBAGE
  	"10101010101001010101101011010111",	--! addr: Hx360 	GARBAGE
  	"01010101010110101010010100101011",	--! addr: Hx380 	GARBAGE
  	"10101010101001010101101011010111",	--! addr: Hx3A0 	GARBAGE
  	"00000000000000000010000000100011",	--! addr: Hx3C0 	SW:    Does nothing due to lack of FPGA
  	"00000000000000000010000000100011"	--! addr: Hx3E0 	SW:    Does nothing due to lack of FPGA
  );
begin

  process (I_clk)
  begin
    if rising_edge(I_clk) then
      if (I_we = '1') then
        ram(to_integer(unsigned(I_addr(4 downto 0)))) <= I_data;
      else
        O_data <= ram(to_integer(unsigned(I_addr(4 downto 0))));
      end if;
    end if;
  end process;

end SYNTH_ram_tb;

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.my_constants.all;

ENTITY d_a_r_cs_tb IS
	-- nothing here
END d_a_r_cs_tb;

ARCHITECTURE SYNTH_d_a_r_cs_tb OF d_a_r_cs_tb IS

	-- Component declarations
	component ram_tb
	Port ( 
		I_clk : in  STD_LOGIC;
    I_we : in  STD_LOGIC;
    I_en : in STD_LOGIC;
    I_addr : in  STD_LOGIC_VECTOR (31 downto 0);
    I_data : in  STD_LOGIC_VECTOR (31 downto 0);
    O_data : out  STD_LOGIC_VECTOR (31 downto 0)
  );
	end component;

	COMPONENT program_counter
	PORT(
    I_clk : IN  std_logic;
    I_nPC : IN  std_logic_vector(31 downto 0);
    I_nPCop : IN  std_logic_vector(1 downto 0);
    O_PC : OUT std_logic_vector(31 downto 0)
  );
	END COMPONENT;

	COMPONENT control_simple
	PORT(
		I_clk : in std_logic;
		I_reset : in std_logic;
		I_aluop : in std_logic_vector(5 downto 0);
		O_state : out std_logic_vector(5 downto 0)
	);
	END COMPONENT;

	COMPONENT decoder
	PORT(
		I_clk : in std_logic; --! clock bit
    I_en : in std_logic; --! enable bit
    I_inst : in std_logic_vector(31 downto 0); --! the current instruction
    O_alu_op : out std_logic_vector(5 downto 0);
    O_imm : out std_logic_vector(31 downto 0);
    O_we : out std_logic; --! write enable bit, USE IF YOU ARE WRITING TO A REGISTER
    O_rs1 : out std_logic_vector(4 downto 0);
    O_rs2 : out std_logic_vector(4 downto 0);
    O_rd : out std_logic_vector(4 downto 0)
	);
	END COMPONENT;

	COMPONENT alu
	PORT(
		I_clk : in std_logic;	--! clock bit
		I_en : in std_logic; --! enable bit
		I_data1 : in std_logic_vector(31 downto 0); --! rs1 data
		I_data2 : in std_logic_vector(31 downto 0); --! rs2 data
		I_dataDwe : in std_logic; --! rd write enable bit
		I_aluop : in std_logic_vector(5 downto 0); --! alu op code
		I_PC : in std_logic_vector(31 downto 0); --! Program counter
		I_dataIMM : in std_logic_vector(31 downto 0); --! immediate
		O_dataResult : out std_logic_vector(31 downto 0); --! result of ALU calculation
		O_dataWriteToReg : out std_logic; --! we writing to a fookin register?
		O_takeBranch : out std_logic --! do I need to explain this one?
	);
	END COMPONENT;

	COMPONENT reg32_32
	PORT(
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
	END COMPONENT;

	-- Signals

	SIGNAL I_clk: std_logic := '0';
	SIGNAL reset : std_logic := '1';
	SIGNAL state : std_logic_vector(5 downto 0) := (others => '0');

	SIGNAL en_fetch : std_logic := '0';
	SIGNAL en_decode : std_logic := '0';
	SIGNAL en_regread : std_logic := '0';
	SIGNAL en_alu : std_logic := '0';
	SIGNAL en_memory : std_logic := '0';
	SIGNAL en_regwrite : std_logic := '0';

	signal ramWE : std_logic := '0';
	signal ramAddr: std_logic_vector(31 downto 0);
	signal ramRData: std_logic_vector(31 downto 0);
	signal ramWData: std_logic_vector(31 downto 0);

	signal nPC: std_logic_vector(31 downto 0);
	signal pcop: std_logic_vector(1 downto 0);
	signal in_pc: std_logic_vector(31 downto 0);

	SIGNAL instruction : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL data1 : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL data2 : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL dataDwe : std_logic := '0';
	SIGNAL aluop : std_logic_vector(5 downto 0) := (others => '0');
	SIGNAL PC : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL imm : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL sel1 : std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL sel2 : std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL selD : std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL dataregWrite: std_logic := '0';
	SIGNAL dataResult : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL dataWriteReg : std_logic := '0';
	SIGNAL takeBranch : std_logic := '0';

	-- Clock period definitions
	CONSTANT I_clk_period : time := 2 ns;

BEGIN

	-- make the Units Under Test

	uut_ram: ram_tb Port map (
  	I_clk => I_clk,
    I_en => en_memory,
  	I_we => ramWE,
  	I_addr => ramAddr,
  	I_data => ramWData,
  	O_data => ramRData
	);

	uut_pcunit: program_counter Port map (
  	I_clk => I_clk,
  	I_nPC => in_pc,
  	I_nPCop => pcop,
  	O_PC => PC
	);

	uut_control: control_simple PORT MAP(
		I_clk => I_clk,
		I_reset => reset,
		O_state => state,
		I_aluop => aluop
	);

	uut_decoder: decoder PORT MAP (
		I_clk => I_clk,
		I_en => en_decode,
		I_inst => instruction,
		O_rs1 => sel1,
		O_rs2 => sel2,
		O_rd => selD,
		O_imm => imm,
		O_we => dataDwe,
		O_alu_op => aluop
	);

	uut_alu: alu PORT MAP (
		I_clk => I_clk,
	  I_en => en_alu,
	  I_data1 => data1,
	  I_data2 => data2,
	  I_dataDwe => dataDwe,
	  I_aluop => aluop,
	  I_PC => PC,
	  I_dataIMM => imm,
	  O_dataResult => dataResult,
	  O_dataWriteToReg => dataWriteReg,
	  O_takeBranch => takeBranch
	);

	uut_reg32 : reg32_32 PORT MAP ( 
		I_clk => I_clk,
	  I_en => en_regread OR en_regwrite,
	  I_dataD => dataResult,
	  O_data1 => data1,
	  O_data2 => data2,
	  I_sel1 => sel1,
	  I_sel2 => sel2,
	  I_selD => selD,
	  I_we => dataWriteReg
	);

	-- Clock process definitions
	I_clk_process :process
	begin
		I_clk <= '0';
		wait for I_clk_period/2;
		I_clk <= '1';
		wait for I_clk_period/2;
	end process;

	-- tie the control_simple state machine to the enable bits
  	en_fetch <= state(0);
	en_decode <= state(1);
	en_regread <= state(2);
	en_alu <= state(3);
	en_memory <= state(4);
	en_regwrite <= state(5);

	pcop <= PC_OP_RESET when reset = '1' else	
	  PC_OP_ASSIGN when takeBranch = '1' and state(5) = '1' else 
	  PC_OP_INC when takeBranch = '0' and state(5) = '1' else 
		PC_OP_NOP;

	in_pc <= dataResult;

	ramAddr <= std_logic_vector(unsigned(PC) / 32);
	ramWData <= X"FFFFFFFC";
	ramWE <= '0';

	instruction <= ramRData;

	-- Stimulus Process
	stim_proc: process
	begin
		reset <= '1'; -- reset control unit
		wait for I_clk_period;
		reset <= '0';

		--! ----BEGIN TESTS----

		--! LUI test 1
		wait until PC = X"00000020"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00002000") report ("Failed LUI (Test 1)") severity note;

		--! SLT test 2
		wait until PC = X"00000040"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00000001") report ("Failed SLT (Test 2)") severity note;

		--! ADD test 3
		wait until PC = X"00000060"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00003000") report ("Failed ADD (Test 3)") severity note;

		--! SUB test 4
		wait until PC = X"00000080"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00002FFF") report ("Failed SUB (Test 4)") severity note;

		--! XOR test 5
		wait until PC = X"000000A0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00001FFF") report ("Failed XOR (Test 5)") severity note;

		--! OR test 6
		wait until PC = X"000000C0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00003FFF") report ("Failed OR (Test 6)") severity note;

		--! AND test 7
		wait until PC = X"000000E0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00000001") report ("Failed AND (Test 7)") severity note;

		--! SRA test 8
		wait until PC = X"00000100"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00000FFF") report ("Failed SRA (Test 8)") severity note;

		--! AUIPC test 9
		wait until PC = X"00000120"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00001120") report ("Failed AUIPC (Test 9)") severity note;

		--! SLL test 10
		wait until PC = X"00000140"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00002240") report ("Failed SLL (Test 10)") severity note;

		--! BLT test 11
		wait until PC = X"00000160"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00000140") report ("Failed BLT (Test 11)") severity note;

		--! BEQ test 12
		wait until PC = X"00000180"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"000001C0") report ("Failed BEQ (Test 12)") severity note;
		
		--! BNE test 13
		wait until PC = X"000001E0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"000001A0") report ("Failed BNE (Test 15)") severity note;

		--! ADDI test 14
		wait until PC = X"000001A0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00001000") report ("Failed ADDI (Test 13)") severity note;

		--! SW test 15 (currently disabled function)
		--wait until PC = X"000001C0"; --! wait until address 
		--wait until en_regwrite = '1'; --! wait until result is written
		--assert (dataResult = X"") report ("Failed SW (Test 14)") severity note;

		--! LW test 16 (currently dummy function)
		wait until PC = X"00000200"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"55555555") report ("Failed LW (Test 16)") severity note;

		--! ANDI test 17
		wait until PC = X"00000220"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00000555") report ("Failed ANDI (Test 17)") severity note;

		--! XORI test 18
		wait until PC = X"00000240"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"FFFFFFFF") report ("Failed XORI (Test 18)") severity note;

		--! ORI test 19
		wait until PC = X"00000260"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"000032AA") report ("Failed ORI (Test 19)") severity note;

		--! SLTU test 20
		wait until PC = X"00000280"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00000001") report ("Failed SLTU (Test 20)") severity note;

		--! SLTI test 21
		wait until PC = X"000002A0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"00000001") report ("Failed SLTI (Test 21)") severity note;

		--! SRL test 22
		wait until PC = X"000002C0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"7FFFFFFF") report ("Failed SRL (Test 22)") severity note;

		--! BGE test 23
		wait until PC = X"000002E0"; --! wait until address 
		wait until en_regwrite = '1'; --! wait until result is written
		assert (dataResult = X"000003C0") report ("Failed BGE (Test 23)") severity note;

		--! ----END TESTS----

		wait until PC = X"00000400"; -- 32 instructions loaded into RAM
		reset <= '1';
		assert false report ("Tests complete") severity note;
		wait;
	end process;
end SYNTH_d_a_r_cs_tb;