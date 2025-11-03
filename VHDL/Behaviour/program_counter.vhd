--! basic RISCV 32-bit program counter

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.my_constants.all;

--! brief 32-bit RISC-V register file
entity program_counter is 
  port(
    --! inputs
    I_clk : in std_logic;
    I_nPC : in std_logic_vector(31 downto 0);
    I_nPCop : in std_logic_vector(1 downto 0);
    O_PC : out std_logic_vector(31 downto 0)
  );
end program_counter;

architecture SYNTH_pc of program_counter is
  --! initialize the PC to memory address Hx00000000
  SIGNAL current_pc: std_logic_vector(31 downto 0) := X"00000000"; 

begin
  process (I_clk)
  begin
    if rising_edge(I_clk) then
      case I_nPCop is 
        when PC_OP_NOP => --! No operation, do nothing
          --! Keeps the PC the same
        when PC_OP_INC => --! increment PC
          current_pc <= std_logic_vector(unsigned(current_pc) + 32);
        when PC_OP_ASSIGN => --! set from external input
          current_pc <= I_nPC;
        when PC_OP_RESET => --! Reset
          current_pc <= X"00000000";
        when others =>
          --! do nothing
      end case;
    end if;
  end process;
  O_PC <= current_pc;
end architecture SYNTH_pc;