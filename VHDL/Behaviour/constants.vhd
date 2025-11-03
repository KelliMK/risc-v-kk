library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package my_constants is 

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
constant OP_LUI : std_logic_vector(5 downto 0) := "000001"; -- LUI
constant OP_LW : std_logic_vector(5 downto 0) := "001101"; -- LW
constant OP_OR : std_logic_vector(5 downto 0) := "100100"; -- OR
constant OP_ORI : std_logic_vector(5 downto 0) := "010100"; -- ORI
constant OP_SLL : std_logic_vector(5 downto 0) := "011110"; -- SLL
constant OP_SLT : std_logic_vector(5 downto 0) := "011111"; -- SLT
constant OP_SLTI : std_logic_vector(5 downto 0) := "010001"; -- SLTI
constant OP_SLTU : std_logic_vector(5 downto 0) := "100000"; -- SLTU
constant OP_SRA : std_logic_vector(5 downto 0) := "100011"; -- SRA
constant OP_SRL : std_logic_vector(5 downto 0) := "100010"; -- SRL
constant OP_SUB : std_logic_vector(5 downto 0) := "011101"; -- SUB
constant OP_SW : std_logic_vector(5 downto 0) := "011000"; -- SW
constant OP_XOR : std_logic_vector(5 downto 0) := "100001"; -- XOR
constant OP_XORI : std_logic_vector(5 downto 0) := "010011"; -- XORI

-- Program Counter opcodes
constant PC_OP_NOP: std_logic_vector(1 downto 0):= "00"; -- Halt and spin
constant PC_OP_INC: std_logic_vector(1 downto 0):= "01"; -- Regular Operation
constant PC_OP_ASSIGN: std_logic_vector(1 downto 0):= "10"; -- Assign new value to PC
constant PC_OP_RESET: std_logic_vector(1 downto 0):= "11"; -- reset PC back to Hx00000000

end my_constants;

package body my_constants is 

end my_constants;