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
    I_clk : in std_logic; --! clock signal
    I_we : in std_logic; --! write enable signal
    I_addr : in std_logic_vector(31 downto 0);  --! address 
    I_data : in std_logic_vector(31 downto 0);  --! data 
    O_L1_miss_count : out std_logic_vector(31 downto 0); --! L1 miss count
    O_L2_miss_count : out std_logic_vector(31 downto 0); --! L2 miss count
    O_wb_count : out std_logic_vector(31 downto 0); --! write-back operations count
    O_data : out std_logic_vector(31 downto 0) --! data out 
  );
end memory;

architecture SYNTH_ram of memory is 
  signal cache_L1_miss : std_logic := '0';
  signal cache_L2_miss : std_logic := '0';
  signal mem_writeback : std_logic := '0';
  signal half_byte : unsigned(3 downto 0) := "0000";
  signal ram_addr : integer := 0;
  signal lru_L1_val : integer := 0;
  signal lru_L1_block : integer := 0;
  signal lru_L2_val : integer := 0;
  signal lru_L2_block : integer := 0;
  signal L1_miss_count : integer := 0;
  signal L2_miss_count : integer := 0;
  signal wb_count : integer := 0;

  constant ADDR_INTRVL : unsigned(31 downto 0) := "00000000000000000000000000100000";
  constant L1_SIZE_BYTES : integer := 1024; --! 1KB is the size of our L1 cache
  constant L2_SIZE_BYTES : integer := 16384;  --! 16KB is the size of our L2 cache
  constant RAM_BYTES : integer := 32768; --! 32KB of RAM
  constant L1_BLOCK_NUM : integer := L1_SIZE_BYTES / L1_BLOCK_BYTES; --! number of blocks in our L1 cache
  constant L2_BLOCK_NUM : integer := L2_SIZE_BYTES / L2_BLOCK_BYTES; --! number of blocks in our L2 cache
  constant L1_WORDS_IN_BLOCK : integer := L1_BLOCK_BYTES / 4;
  constant L2_WORDS_IN_BLOCK : integer := L2_BLOCK_BYTES / 4;

  type ram_t is array (0 to 8191) of std_logic_vector(31 downto 0);
  type word_block_L1_t is array (0 to (L1_WORDS_IN_BLOCK-1)) of std_logic_vector(31 downto 0);  --! for constructing L1 blocks
  type word_block_L2_t is array (0 to (L2_WORDS_IN_BLOCK-1)) of std_logic_vector(31 downto 0);  --! for constructing L2 blocks
  
  --! record for L1 cache blocks
  type L1_block_t is record
    data_present : std_logic; --! should be 0 if empty
    tag : unsigned(31 downto 0); --! address in main memory (RAM)
    data : word_block_L1_t;
    last_access : integer;
  end record;

  --! L1 block reset values/state for initialization and end of writeback
  constant BLOCK_RESET_L1 : L1_block_t := (
    data_present => '0',
    tag => X"00000000", --! address in main memory (RAM)
    data => (others => (others => '0')),
    last_access => 99
  );

  --! L1 cache type initialization
  type L1_cache_t is array (0 to (L1_BLOCK_NUM - 1)) of L1_block_t;

  --! record for L2 cache blocks
  type L2_block_t is record
    data_present : std_logic; --! should be 0 if empty
    tag : unsigned(31 downto 0); --! address of cache block in main memory
    data : word_block_L2_t;
    last_access : integer;
  end record;

  --! L2 block reset values/state for initialization and end of writeback
  constant BLOCK_RESET_L2 : L2_block_t := (
    data_present => '0',
    tag => X"00000000",
    data => (others => (others => '0')),
    last_access => 99
  );

  --! L2 cache type initialization
  type L2_cache_t is array (0 to (L2_BLOCK_NUM - 1)) of L2_block_t;

  --! instantiate caches
  signal L1_cache : L1_cache_t := (others => BLOCK_RESET_L1);
  signal L2_cache : L2_cache_t := (others => BLOCK_RESET_L2);

  --! instantiate RAM
  signal ram_32KB: ram_t := (others => X"AAAAAAAA"); --! alternating 1s and 0s

begin
  process(I_clk)
  begin
    if (rising_edge(I_clk) AND (I_en = '1')) then --! necessary for time coordination
      
      --! set cache miss signals, and reset appropriately in below loops
      cache_L1_miss <= '1';
      cache_L2_miss <= '1';

      --! loop through L1 cache to find the address value
      for i in 0 to (L1_BLOCK_NUM - 1) loop

        --! the following spaghetti registers a cache hit
        if ((L1_cache(i).tag <= unsigned(I_addr)) AND 
          (unsigned(I_addr) <= (L1_cache(i).tag + (((L1_WORDS_IN_BLOCK)-1) * ADDR_INTRVL)))) then
          
          --! adjust cache hits and last access value
          cache_L1_miss <= '0';
          cache_L2_miss <= '0';
          L1_cache(i).last_access <= 0;

          --! if write enabled then you need to store I_data
          if I_we = '1' then
            for j in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
              if ((unsigned(L1_cache(i).tag) + (j * ADDR_INTRVL)) = unsigned(I_addr)) then
                L1_cache(i).data(j) <= I_data; --! this is the money shot
                exit;
              end if;
            end loop;

          --! else we retrieve data from this cache
          else
            for j in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
              if ((L1_cache(i).tag + (j * ADDR_INTRVL)) = unsigned(I_addr)) then
                O_data <= L1_cache(i).data(j); --! this is the money shot
                exit;
              end if;
            end loop;
          end if;
        else
          L1_cache(i).last_access <= L1_cache(i).last_access + 1;
        end if;

        --! LRU values
        if (L1_cache(i).last_access > lru_L1_val) then
          lru_L1_val <= L1_cache(i).last_access;
          lru_L1_block <= i;
        end if;
      end loop;

      --! L2 cache implementation starts here
      if (cache_L1_miss = '1') then
        for i in 0 to (L2_BLOCK_NUM - 1) loop

          --! the following spaghetti registers a cache hit
          if ((L2_cache(i).tag <= unsigned(I_addr)) AND 
            (unsigned(I_addr) <= (L2_cache(i).tag + (((L2_WORDS_IN_BLOCK)-1) * ADDR_INTRVL)))) then
            
            --! adjust cache hits and last access value
            cache_L2_miss <= '0';
            L2_cache(i).last_access <= 0;

            --! if write enabled then you need to store I_data
            if I_we = '1' then
              for j in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
                if ((unsigned(L2_cache(i).tag) + (j * ADDR_INTRVL)) = unsigned(I_addr)) then
                  L2_cache(i).data(j) <= I_data; --! this is the money shot
                  exit;
                end if;
              end loop;

            --! else we retrieve data from this cache
            else
              for j in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
                if ((L2_cache(i).tag + (j * ADDR_INTRVL)) = unsigned(I_addr)) then
                  O_data <= L2_cache(i).data(j); --! this is the money shot
                  exit;
                end if;
              end loop;
            end if;
          else
            L2_cache(i).last_access <= L2_cache(i).last_access + 1;
          end if;

          --! LRU values
          if (L2_cache(i).last_access > lru_L2_val) then
            lru_L2_val <= L2_cache(i).last_access;
            lru_L2_block <= i;
          end if;
        end loop;
      end if;

      --! RAM implementation starts here
      if (cache_L2_miss = '1') then

        ram_addr <= ((to_integer(unsigned(I_addr)) / 32) mod 8192); --! calculates ram address from input

        --! store instructions
        if I_we = '1' then
          ram_32KB(ram_addr) <= I_data;

        --! load instructions
        else
          O_data <= ram_32KB(ram_addr); --! IDK WHY THIS WAS ONLY ram_addr ON THE RIGHT SIDE EARLIER
        end if;

        --! L1 writeback start
        if (L1_cache(lru_L1_block).data_present = '1') then
          mem_writeback <= '1';

          --! point ram_addr at writeback location
          ram_addr <= ((to_integer(unsigned(L1_cache(lru_L1_block).tag)) / 32) mod 8192);

          --! the actual writeback from cache L1 to RAM
          for i in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
            ram_32KB((ram_addr + i)) <= L1_cache(lru_L1_block).data(i);
          end loop;
        end if;

        ram_addr <= ((to_integer(unsigned(I_addr)) / 32) mod 8192); --! calculates ram address from input

        --! write to L1 cache
        L1_cache(lru_L1_block).data_present <= '1';
        L1_cache(lru_L1_block).tag <= unsigned(I_addr);
        L1_cache(lru_L1_block).last_access <= 0;
        for i in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
          L1_cache(lru_L1_block).data(i) <= ram_32KB((ram_addr + i));
        end loop;


        --! L2 writeback start
        if (L2_cache(lru_L2_block).data_present = '1') then
          mem_writeback <= '1';

          --! point ram_addr at writeback location
          ram_addr <= ((to_integer(unsigned(L2_cache(lru_L2_block).tag)) / 32) mod 8192);

          --! the actual writeback from cache L2 to RAM
          for i in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
            ram_32KB((ram_addr + i)) <= L2_cache(lru_L2_block).data(i);
          end loop;
        end if;

        ram_addr <= ((to_integer(unsigned(I_addr)) / 32) mod 8192); --! calculates ram address from input

        --! write to L2 cache
        L2_cache(lru_L2_block).data_present <= '1';
        L2_cache(lru_L2_block).tag <= unsigned(I_addr);
        L2_cache(lru_L2_block).last_access <= 0;
        for i in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
          L2_cache(lru_L2_block).data(i) <= ram_32KB((ram_addr + i));
        end loop;

      end if;

      --! tally miss counts
      if (cache_L1_miss = '1') then
        L1_miss_count <= L1_miss_count + 1;
      else 
        cache_L1_miss <= '1';
      end if;

      if (cache_L2_miss = '1') then
        L1_miss_count <= L2_miss_count + 1;
      else 
        cache_L2_miss <= '1';
      end if;

      if (mem_writeback = '1') then
        wb_count <= wb_count + 1;
        mem_writeback <= '0';
      end if;

    end if;

    --! set outputs appropriately
    O_L1_miss_count <= std_logic_vector(to_unsigned(L1_miss_count, 32));
    O_L2_miss_count <= std_logic_vector(to_unsigned(L2_miss_count, 32));
    O_wb_count <= std_logic_vector(to_unsigned(wb_count, 32));

  end process;
end SYNTH_ram;