--! Milestone two testbench file
--! for operation please load decoder.vhd, random_access_memory.vhd, 
--!      program_counter.vhd, register_file.vhd, alu.vhd, 
--!      control_simple.vhd, constants.vhd, and provided binary files 
--! onto EDAplayground along with this file

--! set cache sizes and test file in constants.vhd

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

library work;
use work.my_constants.all;

ENTITY CP319 IS
	--! nothing here
END CP319;

ARCHITECTURE SYNTH_CP319 of CP319 IS
	
	--! Component declarations
	component control_simple
	PORT (
		I_clk : in std_logic; --! clock
		I_reset : in std_logic; --! reset signal
		I_aluop : in std_logic_vector(5 downto 0); --! constants
		O_state : out std_logic_vector(8 downto 0) --! 9 bit state value
	);
	END component;

	component inst_cache_ent
	PORT (
		I_clk : in STD_LOGIC; --! clock
    I_we : in STD_LOGIC; --! enable write to instructions (no)
    I_en : in STD_LOGIC; --! enable this component
    I_addr : in STD_LOGIC_VECTOR (31 downto 0); --! lowest 9 bits determine the next instruction
    I_data : in STD_LOGIC_VECTOR (31 downto 0); --! data for writing to an instruction location (no)
    O_data : out STD_LOGIC_VECTOR (31 downto 0) --! output instruction
	);
	END component;

	component program_counter
	PORT (
		I_clk : in std_logic; --! clock
    I_nPC : in std_logic_vector(31 downto 0); --! input branch location
    --! Lines ___ to ___ in testbench enable below signal properly
    I_nPCop : in std_logic_vector(1 downto 0); --! opcode for PC mode
    O_PC : out std_logic_vector(31 downto 0) --! new instruction location
	);
	END component;

	component decoder
	PORT (
		I_clk : in std_logic; --! clock bit
    I_en : in std_logic; --! enable bit
    I_inst : in std_logic_vector(31 downto 0); --! the current instruction
    O_alu_op : out std_logic_vector(5 downto 0); --! operation number for the ALU
    O_imm : out std_logic_vector(31 downto 0); --! immediate or offset value
    O_we : out std_logic; --! write enable bit
    O_rs1 : out std_logic_vector(4 downto 0); --! rs1 from the 32 registers available
    O_rs2 : out std_logic_vector(4 downto 0); --! rs2 from the 32 registers available
    O_rd : out std_logic_vector(4 downto 0) --! rd from the 32 registers available
	);
	END component;

	component reg32_32
	PORT (
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
	END component;

	component alu
	PORT (
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
	END component;

	component L1_cache
	PORT (
		I_en : in std_logic;	--! enable this component
		I_clk : in std_logic; --! clock signal
		I_we : in std_logic; --! write enable signal
		I_addr : in std_logic_vector(31 downto 0);  --! address 
    I_data : in std_logic_vector(31 downto 0);  --! data 
    I_byte_mode : in std_logic; --! patch for SB and LBU
    I_ram_block : in L1_block_t; --! block from RAM
    O_block : out L1_block_t; --! block to RAM
    O_L1_miss_count : out integer; --! L1 miss count
    O_data : out std_logic_vector(31 downto 0); --! data out 
    O_carry_en : out std_logic --! enables carry for L2 if cache hit
	);
	END component;

	component L2_cache
	PORT (
		I_en : in std_logic;	--! enable this component
		I_clk : in std_logic; --! clock signal
		I_we : in std_logic; --! write enable signal
		I_carry_en : in std_logic; --! carry enable signal
		I_carry_input : in std_logic_vector(31 downto 0); --! carry data
		I_addr : in std_logic_vector(31 downto 0);  --! address 
    I_data : in std_logic_vector(31 downto 0);  --! data 
    I_byte_mode : in std_logic; --! patch for SB and LBU
    I_ram_block : in L2_block_t; --! block from RAM
    O_block : out L2_block_t; --! block to RAM
    O_L2_miss_count : out integer; --! L2 miss count
    O_data : out std_logic_vector(31 downto 0); --! data out 
    O_carry_en : out std_logic --! carry out enable 
	);
	END component;

	component memory
	PORT (
		I_en : in std_logic; --! enables this module
    I_carry_en : in std_logic; --! carry enable signal
    I_carry_input : in std_logic_vector(31 downto 0); --! carry data
    I_clk : in std_logic; --! clock signal
    I_we : in std_logic; --! write enable signal
    I_addr : in std_logic_vector(31 downto 0);  --! address 
    I_data : in std_logic_vector(31 downto 0);  --! data 
    I_byte_mode : in std_logic; --! patch for SB and LBU
    I_L1_block : in L1_block_t; --! LRU block from L1 cache
    O_L1_block : out L1_block_t; --! write to L1 Cache
    I_L2_block : in L2_block_t; --! LRU block from L2 cache
    O_L2_block : out L2_block_t; --! write to L2 Cache
    O_wb_count : out integer; --! write-back operations count
    O_data : out std_logic_vector(31 downto 0) --! data out 
	);
	END component;

	--! Signals
	SIGNAL I_clk: std_logic := '0'; --! clock signal
	SIGNAL reset : std_logic := '1'; --! reset signal
	SIGNAL state : std_logic_vector(8 downto 0) := (others => '0'); --! state signal for the control unit.

	--! enable signals for components (besides constants.vhd)
	SIGNAL en_a_load_insts : std_logic := '0'; --! should only be triggered at start and by resets
	SIGNAL en_b_fetch : std_logic := '0'; --! kinda unused? idk
	SIGNAL en_c_decode : std_logic := '0';
	SIGNAL en_d_regread : std_logic := '0';
	SIGNAL en_e_alu : std_logic := '0';
	SIGNAL en_f_L1 : std_logic := '0';
	SIGNAL en_g_L2 : std_logic := '0';
	SIGNAL en_h_memory : std_logic := '0';
	SIGNAL en_i_regwrite : std_logic := '0';

	--! Instruction signals
	SIGNAL inst_addr : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; --! init to zeroes
	SIGNAL inst_w_data : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; --! init to zeroes
	SIGNAL inst_r_data : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; --! init to zeroes
	SIGNAL inst_we : std_logic := '0'; --! this should never be one, for now at least

	--! program counter signals
	SIGNAL pcop: std_logic_vector(1 downto 0) := "11";
	SIGNAL in_pc: std_logic_vector(31 downto 0) := "00000000000000000000000000000000";

	--! RAM signals
	SIGNAL ramWE : std_logic := '0'; --! only for store operations
	SIGNAL ramAddr : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
	SIGNAL ramRData : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
	SIGNAL ramWData : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
	SIGNAL L1_miss_count : integer := 0;
	SIGNAL L2_miss_count : integer := 0;
	SIGNAL wb_count : integer := 0;
	SIGNAL carry_output_1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; --! output from L1 to L2
	SIGNAL carry_output_2 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"; --! output from L2 to RAM
	SIGNAL carry_en_1 : std_logic := '0';
	SIGNAL carry_en_2 : std_logic := '0';
	SIGNAL patch : std_logic := '0';


	--! block signals
	SIGNAL L1_block_to_RAM : L1_block_t := BLOCK_RESET_L1; --! goes from L1 to the RAM
	SIGNAL RAM_block_to_L1 : L1_block_t := BLOCK_RESET_L1; --! goes from RAM to the L1
	SIGNAL L2_block_to_RAM : L2_block_t := BLOCK_RESET_L2; --! goes from L1 to the RAM
	SIGNAL RAM_block_to_L2 : L2_block_t := BLOCK_RESET_L2; --! goes from RAM to the L1

	--! other
  SIGNAL use_ram : std_logic; --! alu telling register whether or not to use RAM input
	SIGNAL instruction : std_logic_vector(31 downto 0) := (others => '0'); --! current instruction
	SIGNAL dataRS1 : std_logic_vector(31 downto 0) := (others => '0'); --! rs1 data
	SIGNAL dataRS2 : std_logic_vector(31 downto 0) := (others => '0'); --! rs2 data
	SIGNAL dataDwe : std_logic := '0';
	SIGNAL aluop : std_logic_vector(5 downto 0) := (others => '0');
	SIGNAL PC : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL imm : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL sel1 : std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL sel2 : std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL selD : std_logic_vector(4 downto 0) := (others => '0');
	SIGNAL newBranch : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL dataResult : std_logic_vector(31 downto 0) := (others => '0');
	SIGNAL dataWriteReg : std_logic := '0';
	SIGNAL takeBranch : std_logic := '0';

	--! Clock period definitions
	CONSTANT I_clk_period : time := 2 ns;

BEGIN

	--! make the Units Under Test

	uut_control: control_simple PORT MAP (
		I_clk => I_clk,
		I_reset => reset,
		I_aluop => aluop,
		O_state => state
	);

	uut_inst: inst_cache_ent PORT MAP (
		I_clk => I_clk,
		I_we => inst_we,
		I_en => en_a_load_insts,
		I_addr => inst_addr,
		I_data => inst_w_data,
		O_data => inst_r_data
	);

	uut_pc: program_counter PORT MAP (
		I_clk => I_clk,
		I_nPC => in_pc,
		I_nPCop => pcop,
		O_PC => PC
	);

	uut_decoder: decoder PORT MAP (
		I_clk => I_clk,
		I_en => en_c_decode,
		I_inst => instruction,
		O_alu_op => aluop,
		O_imm => imm,
		O_we => dataDwe,
		O_rs1 => sel1,
		O_rs2 => sel2,
		O_rd => selD
	);

	uut_reg32: reg32_32 PORT MAP (
		I_clk => I_clk, --! clock bit
		I_en => en_d_regread OR en_i_regwrite, --! enable component bit
		I_data_alu => dataResult, --! register data from the ALU
		I_data_ram => ramWData, --! register data from cache or ram
		I_ram_en => use_ram, --! enable ram data bit, indicates use of ram output
		I_sel1 => sel1, --! selects rs1
		I_sel2 => sel2, --! selects rs2
		I_selD => selD, --! selects rd
		I_we => dataWriteReg, --! write-enable bit
		O_dataRS1 => dataRS1, --! outbound data from rs1
		O_dataRS2 => dataRS2 --! outbound data from rs2
	);

	uut_alu: alu PORT MAP (
		I_clk => I_clk,
		I_en => en_e_alu,
		I_PC => PC,
		I_dataRS1 => dataRS1,
		I_dataRS2 => dataRS2,
		I_dataDwe => dataDwe,
		I_dataIMM => imm,
		I_aluop => aluop,
		O_byte_mode => patch,
		O_ram_addr => ramAddr,
		O_ram_we => ramWE,
		O_newBranch => newBranch,
		O_dataResult => dataResult,
		O_dataWriteToReg => dataWriteReg,
    O_use_ram => use_ram,
		O_takeBranch => takeBranch
	);

	uut_L1: L1_cache PORT MAP (
		I_clk => I_clk,
		I_en => en_f_L1,
		I_we => ramWE,
		I_addr => ramAddr,
		I_data => dataResult,
		I_byte_mode => patch,
		I_ram_block => RAM_block_to_L1,
		O_block => L1_block_to_RAM, 
		O_L1_miss_count => L1_miss_count,
		O_data => carry_output_1,
		O_carry_en => carry_en_1
	);

	uut_L2: L2_cache PORT MAP (
		I_clk => I_clk,
		I_en => en_g_L2,
		I_we => ramWE,
		I_carry_en => carry_en_1, --! carry enable signal
		I_carry_input => carry_output_1, --! carry data
		I_addr => ramAddr,
		I_data => dataResult,
		I_byte_mode => patch,
		I_ram_block => RAM_block_to_L2,
		O_block => L2_block_to_RAM,
		O_L2_miss_count => L2_miss_count,
		O_data => carry_output_2,
		O_carry_en => carry_en_2
	);

	uut_mem: memory PORT MAP (
		I_en => en_h_memory,	--! enables this module
    I_carry_en => carry_en_2,
    I_carry_input => carry_output_2, --! L2 miss signal
    I_clk => I_clk, --! clock signal
    I_we => en_h_memory, --! write enable signal
    I_addr => ramAddr, --! address 
    I_data => dataResult, --! data 
    I_byte_mode => patch,
    I_L1_block => L1_block_to_RAM, --! LRU block from L1 cache
    O_L1_block => RAM_block_to_L1, --! write to L1 Cache
    I_L2_block => L2_block_to_RAM, --! LRU block from L2 cache
    O_L2_block => RAM_block_to_L2, --! write to L2 Cache
    O_wb_count => wb_count, --! write-back operations count
    O_data => ramWData --! data out 
	);

	--! Clock process definitions
	I_clk_process :process
	begin
		I_clk <= '0';
		wait for I_clk_period/2;
		I_clk <= '1';
		wait for I_clk_period/2;
	end process;

	--! tie the control_simple state machine to the enable bits
	en_a_load_insts <= state(0);
	en_b_fetch <= state(1);
	en_c_decode <= state(2);
	en_d_regread <= state(3);
	en_e_alu <= state(4);
	en_f_L1 <= state(5);
	en_g_L2 <= state(6);
	en_h_memory <= state(7);
	en_i_regwrite <= state(8);

	--! statement for proper program counter operation
	pcop <= PC_OP_RESET when reset = '1' else	
	  PC_OP_ASSIGN when takeBranch = '1' and state(8) = '1' else 
	  PC_OP_INC when takeBranch = '0' and state(8) = '1' else 
		PC_OP_NOP;

	--! set the jump address on each cycle
	in_pc <= newBranch;

	--! PC operation
	inst_addr <= std_logic_vector(unsigned(PC) / 32);

	--! Why the fuck would we write to instructions???? Keeping this here just in case I guess
	ramRData <= X"FFFFFFFC"; --! this hex is error
	inst_we <= '0';

	--! instruction baby
	instruction <= inst_r_data;

	--! Stimulus Process
	stim_proc: process
	begin
		reset <= '1'; --! reset control unit
		wait for I_clk_period;
		reset <= '0';

		--! wait until second instruction to make sure that we don't exit immediately
		wait until PC = X"00000020"; 

		--! wait until I piss my pants
		wait until instruction(0) /= '1';

		report "L1 Cache Miss Count = " & integer'image(L1_miss_count) severity note;
		report "L2 Cache Miss Count = " & integer'image(L2_miss_count) severity note;
		report "Write-Back Operations Count = " & integer'image(wb_count) severity note;

		assert false report "End of testing." severity note;
		wait;
	end process;
end architecture SYNTH_CP319;

