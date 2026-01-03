--! 32-bit instruction cache and program counter

--! Begin Instruction Cache

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library work;
use work.my_constants.all;

--! create instruction cache
entity inst_cache_ent is
  generic(
    INST_CACHE_WORDS : natural := 512; -- number of instruction cache words
  );

  port(
    I_clk : in STD_LOGIC; --! clock
    I_we : in STD_LOGIC; --! enable write to instructions (no)
    I_en : in STD_LOGIC; --! enable this component
    I_addr : in STD_LOGIC_VECTOR (31 downto 0); --! lowest 9 bits determine the next instruction
    I_data : in STD_LOGIC_VECTOR (31 downto 0); --! data for writing to an instruction location (no)
    O_data : out STD_LOGIC_VECTOR (31 downto 0) --! output instruction
  );
end inst_cache_ent;

architecture SYNTH_inst_cache of inst_cache_ent is 
  type store_t is array (0 to (INST_CACHE_WORDS-1)) of std_logic_vector(31 downto 0); --! Making it 2 kb due to time constraints
  type word_store_t is array (0 to 7) of std_logic_vector(3 downto 0);
  type char_store_t is array (0 to 7) of character;

  impure function load_insts return store_t is -- I haven't created a function in VHDL before, oh well
    
    --! open our input file
    file file_in : text open read_mode is INPUT_FILE;

    --! variables 
    variable mem : store_t := (others => (others => '0'));
    variable idx : integer := 0;
    variable line_buff : line;
    variable char_arr : char_store_t;  -- 8 characters for reading hex representation of a word
    variable half_bytes : word_store_t;
    variable word : std_logic_vector(31 downto 0); -- word to be loaded into

  begin
    while ((NOT endfile(file_in)) AND (idx <= (INST_CACHE_WORDS-1))) loop
      --! read line from file into line_buff
      readline(file_in, line_buff);

      -- read 4 bytes
      for i in 0 to 7 loop
        read(line_buff, char_arr(i));
      end loop;

      -- place hex values into loops
      for i in 0 to 7 loop
        if (char_arr(i) = '0') then
          half_bytes(i) := "0000";
        elsif (char_arr(i) = '1') then
          half_bytes(i) := "0001";
        elsif (char_arr(i) = '2') then
          half_bytes(i) := "0010";
        elsif (char_arr(i) = '3') then
          half_bytes(i) := "0011";
        elsif (char_arr(i) = '4') then
          half_bytes(i) := "0100";
        elsif (char_arr(i) = '5') then
          half_bytes(i) := "0101";
        elsif (char_arr(i) = '6') then
          half_bytes(i) := "0110";
        elsif (char_arr(i) = '7') then
          half_bytes(i) := "0111";
        elsif (char_arr(i) = '8') then
          half_bytes(i) := "1000";
        elsif (char_arr(i) = '9') then
          half_bytes(i) := "1001";
        elsif (char_arr(i) = 'a') then
          half_bytes(i) := "1010";
        elsif (char_arr(i) = 'b') then
          half_bytes(i) := "1011";
        elsif (char_arr(i) = 'c') then
          half_bytes(i) := "1100";
        elsif (char_arr(i) = 'd') then
          half_bytes(i) := "1101";
        elsif (char_arr(i) = 'e') then
          half_bytes(i) := "1110";
        elsif (char_arr(i) = 'f') then
          half_bytes(i) := "1111";
        end if;
      end loop;

      -- assemble word from little endian binary:
      word(3 downto 0) := half_bytes(1);
      word(7 downto 4) := half_bytes(0);
      word(11 downto 8) := half_bytes(3);
      word(15 downto 12) := half_bytes(2);
      word(19 downto 16) := half_bytes(5);
      word(23 downto 20) := half_bytes(4);
      word(27 downto 24) := half_bytes(7);
      word(31 downto 28) := half_bytes(6);

      mem(idx) := word;
      idx := idx + 1;
    end loop;

    return mem;
  end function;

  signal inst_cache : store_t := load_insts;

begin
  
  process(I_clk)
  begin
    if rising_edge(I_clk) then
      if (I_we = '1') then
        inst_cache(to_integer(unsigned(I_addr(8 downto 0)))) <= I_data;
      else
        O_data <= inst_cache(to_integer(unsigned(I_addr(8 downto 0))));
      end if;
    end if;
  end process;

end architecture SYNTH_inst_cache;

--! Begin Program Counter

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! grab the constants 
library work;
use work.my_constants.all;

entity program_counter is 
  port(
    --! inputs
    I_clk : in std_logic; --! clock
    I_nPC : in std_logic_vector(31 downto 0); --! input branch location
    I_nPCop : in std_logic_vector(1 downto 0); --! opcode for PC mode
    O_PC : out std_logic_vector(31 downto 0) --! new instruction location
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
        when PC_OP_ASSIGN => --! set from branch instruction
          current_pc <= I_nPC;
        when PC_OP_RESET => --! Reset
          current_pc <= X"00000000";
        when others =>
          --! do nothing
          --! error should be thrown here, not implementing it
      end case;
    end if;
  end process;
  O_PC <= current_pc;
end architecture SYNTH_pc;