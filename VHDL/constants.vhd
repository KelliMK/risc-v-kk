library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package my_constants is 

-- Cache Sizes and testing file
constant L1_BLOCK_BYTES : integer := 4;
constant L1_WORDS_IN_BLOCK : integer := (L1_BLOCK_BYTES / 4);
constant L2_BLOCK_BYTES : integer := 16;
constant L2_WORDS_IN_BLOCK : integer := (L2_BLOCK_BYTES / 4);
constant INPUT_FILE : string := "b1.txt";

--! Operation Codes
constant OP_ADD : std_logic_vector(5 downto 0) := "011100"; -- ADD
constant OP_ADDI : std_logic_vector(5 downto 0) := "010000"; -- ADDI
constant OP_AND : std_logic_vector(5 downto 0) := "100101"; -- AND
constant OP_ANDI : std_logic_vector(5 downto 0) := "010101"; -- ANDI
constant OP_AUIPC : std_logic_vector(5 downto 0) := "000010"; -- AUIPC
constant OP_BEQ : std_logic_vector(5 downto 0) := "000100"; -- BEQ
constant OP_BGE : std_logic_vector(5 downto 0) := "000111"; -- BGE
constant OP_BLT : std_logic_vector(5 downto 0) := "000110"; -- BLT
constant OP_BNE : std_logic_vector(5 downto 0) := "000101"; -- BNE
constant OP_ECALL : std_logic_vector(5 downto 0) := "100111"; -- ECALL
constant OP_JAL : std_logic_vector(5 downto 0) := "000011"; -- JAL
constant OP_JALR : std_logic_vector(5 downto 0) := "001010"; -- JALR
constant OP_LBU : std_logic_vector(5 downto 0) := "001110"; -- LBU
constant OP_LUI : std_logic_vector(5 downto 0) := "000001"; -- LUI
constant OP_LW : std_logic_vector(5 downto 0) := "001101"; -- LW
constant OP_OR : std_logic_vector(5 downto 0) := "100100"; -- OR
constant OP_ORI : std_logic_vector(5 downto 0) := "010100"; -- ORI
constant OP_SB : std_logic_vector(5 downto 0) := "010110"; -- SB
constant OP_SH : std_logic_vector(5 downto 0) := "010111"; -- SH
constant OP_SLL : std_logic_vector(5 downto 0) := "011110"; -- SLL
constant OP_SLLI : std_logic_vector(5 downto 0) := "011001"; -- SLLI
constant OP_SLT : std_logic_vector(5 downto 0) := "011111"; -- SLT
constant OP_SLTI : std_logic_vector(5 downto 0) := "010001"; -- SLTI
constant OP_SLTU : std_logic_vector(5 downto 0) := "100000"; -- SLTU
constant OP_SRA : std_logic_vector(5 downto 0) := "100011"; -- SRA
constant OP_SRL : std_logic_vector(5 downto 0) := "100010"; -- SRL
constant OP_SUB : std_logic_vector(5 downto 0) := "011101"; -- SUB
constant OP_SW : std_logic_vector(5 downto 0) := "011000"; -- SW
constant OP_XOR : std_logic_vector(5 downto 0) := "100001"; -- XOR
constant OP_XORI : std_logic_vector(5 downto 0) := "010011"; -- XORI

--! TO IMPLEMENT
constant OP_LB : std_logic_vector(5 downto 0) := "001011"; --! LB
constant OP_LH : std_logic_vector(5 downto 0) := "001100"; --! LH
constant OP_LHU : std_logic_vector(5 downto 0) := "001111"; --! LHU

-- Program Counter opcodes
constant PC_OP_NOP: std_logic_vector(1 downto 0):= "00"; -- Halt and spin
constant PC_OP_INC: std_logic_vector(1 downto 0):= "01"; -- Regular Operation
constant PC_OP_ASSIGN: std_logic_vector(1 downto 0):= "10"; -- Assign new value to PC
constant PC_OP_RESET: std_logic_vector(1 downto 0):= "11"; -- reset PC back to Hx00000000

-- Block stuff
type word_block_L1_t is array (0 to (L1_WORDS_IN_BLOCK-1)) of std_logic_vector(31 downto 0);  --! for constructing L1 blocks
type L1_block_t is record	--! L1 cache blocks
  data_present : std_logic; --! should be 0 if empty
  tag : unsigned(31 downto 0); --! address in main memory (RAM)
  data : word_block_L1_t;
  last_access : integer;
end record;

--! L1 block reset values/state for initialization and end of writeback
constant BLOCK_RESET_L1 : L1_block_t := (
  data_present => '0',
  tag => X"AAAAAAAA", --! address in main memory (RAM)
  data => (others => (others => '0')),
  last_access => 99
);

type word_block_L2_t is array (0 to (L2_WORDS_IN_BLOCK-1)) of std_logic_vector(31 downto 0);  --! for constructing L2 blocks

type L2_block_t is record	--! L1 cache blocks
  data_present : std_logic; --! should be 0 if empty
  tag : unsigned(31 downto 0); --! address in main memory (RAM)
  data : word_block_L2_t;
  last_access : integer;
end record;

--! L2 block reset values/state for initialization and end of writeback
constant BLOCK_RESET_L2 : L2_block_t := (
  data_present => '0',
  tag => X"AAAAAAAA", --! address in main memory (RAM)
  data => (others => (others => '0')),
  last_access => 99
);

-- other
constant ADDR_INTRVL : unsigned(31 downto 0) := "00000000000000000000000000100000";

end my_constants;

package body my_constants is 

end my_constants;