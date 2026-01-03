-- Random Access Memory with 1 read/write port

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

library work;
use work.my_constants.all;

-- Memory entity
ENTITY memory IS
  PORT(
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
end memory;

architecture SYNTH_ram of memory is 
  signal mem_writeback : std_logic := '0';
  signal ram_addr : integer := 0;
  signal wb_count : integer := 0;
  signal s_write_to_caches : std_logic := '0';
  signal s_L1_block : L1_block_t;
  signal s_L2_block : L2_block_t; 
  signal s_data_out : std_logic_vector(31 downto 0);
  signal s_aux : std_logic_vector(31 downto 0);

  constant RAM_BYTES : integer := 32768; --! 32KB of RAM

  type ram_t is array (0 to 8191) of std_logic_vector(31 downto 0);

  --! instantiate RAM
  signal ram_32KB: ram_t := (others => X"00000000"); --! alternating 1s and 0s

begin
  process(I_clk)
  begin
    if (rising_edge(I_clk) AND (I_en = '1')) then --! necessary for time coordination

      --! carry data out 
      if (I_carry_en='1') then

        s_data_out <= I_carry_input;

      --! otherwise we gotta access ram directly
      else

        ram_addr <= ((to_integer(unsigned(I_addr)) / 32) mod 8192); --! calculates ram address from input

        --! store instructions
        if I_we = '1' then
          if (I_byte_mode = '1') then
            s_aux <= ram_32KB(ram_addr);
            s_aux(7 downto 0) <= I_data(7 downto 0);
            ram_32KB(ram_addr) <= s_aux;
          else
            ram_32KB(ram_addr) <= I_data;
          end if;

        --! load instructions
        else
          if (I_byte_mode = '1') then
            s_aux <= ram_32KB(ram_addr);
            s_data_out(31 downto 8) <= "000000000000000000000000";
            s_data_out(7 downto 0) <= s_aux(7 downto 0);
          else
            s_data_out <= ram_32KB(ram_addr); --! load the data from RAM
          end if;
        end if;

        --! L1 writeback start
        if (I_L1_block.data_present = '1') then
          mem_writeback <= '1';
          wb_count <= wb_count + 1;

          --! point ram_addr at writeback location
          ram_addr <= ((to_integer(unsigned(I_L1_block.tag)) / 32) mod 8192);

          --! the actual writeback from cache L1 to RAM
          for i in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
            ram_32KB(((ram_addr + i) mod 8192)) <= I_L1_block.data(i);
          end loop;
        end if;

        --! L2 writeback start
        if (I_L2_block.data_present = '1') then
          mem_writeback <= '1';

          --! point ram_addr at writeback location
          ram_addr <= ((to_integer(unsigned(I_L2_block.tag)) / 32) mod 8192);

          --! the actual writeback from cache L2 to RAM
          for i in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
            ram_32KB(((ram_addr + i) mod 8192)) <= I_L2_block.data(i);
          end loop;
        end if;
      end if;

      ram_addr <= ((to_integer(unsigned(I_addr)) / 32) mod 8192); --! calculates ram address from input

      --! write to L1 cache
      s_L1_block.data_present <= '1';
      s_L1_block.tag <= unsigned(I_addr);
      s_L1_block.last_access <= 0;
      for i in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
        s_L1_block.data(i) <= ram_32KB(((ram_addr + i) mod 8192));
      end loop;

      --! write to L2 cache
      s_L2_block.data_present <= '1';
      s_L2_block.tag <= unsigned(I_addr);
      s_L2_block.last_access <= 0;
      for i in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
        s_L2_block.data(i) <= ram_32KB(((ram_addr + i) mod 8192));
      end loop;

    end if;

  O_wb_count <= wb_count;

  end process;
  
  --! set outputs appropriately
  O_L1_block <= s_L1_block;
  O_L2_block <= s_L2_block;
  O_data <= s_data_out;

end SYNTH_ram;