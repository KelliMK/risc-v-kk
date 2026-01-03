--! L1 data cache

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

library work;
use work.my_constants.all;

ENTITY L1_cache IS
	PORT(
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
end L1_cache;

architecture SYNTH_L1_CACHE of L1_cache is

	signal cache_L1_miss : std_logic := '0';
	signal lru_L1_accs_val : integer := 0;
	signal lru_L1_block : integer := 0;
	signal L1_miss_count : integer := 0;
	signal s_data_output : std_logic_vector(31 downto 0);
	signal s_aux : std_logic_vector(31 downto 0);
	signal s_carry_en : std_logic := '0';

	constant L1_SIZE_BYTES : integer := 1024; --! 1KB is the size of our L1 cache
	constant L1_BLOCK_NUM : integer := L1_SIZE_BYTES / L1_BLOCK_BYTES; --! number of blocks in our L1 cache
	constant L1_WORDS_IN_BLOCK : integer := L1_BLOCK_BYTES / 4;

	type word_block_L1_t is array (0 to (L1_WORDS_IN_BLOCK-1)) of std_logic_vector(31 downto 0);  --! for constructing L1 blocks

  --! L1 cache type declaration
  type L1_cache_t is array (0 to (L1_BLOCK_NUM - 1)) of L1_block_t;

  --! instantiate cache
  signal L1_cache : L1_cache_t := (others => BLOCK_RESET_L1);

begin
	process(I_clk)
	begin
		if (rising_edge(I_clk) AND (I_en = '1')) then --! necessary for time coordination

      --! write the new block to cache
      if (I_ram_block.data_present = '1') then
      	L1_cache(lru_L1_block) <= I_ram_block;
      end if;

			--! set cache miss signals, and reset appropriately in below loops
      cache_L1_miss <= '1';
      s_carry_en <= '0';

      --! loop through L1 cache to find the address value
      for i in 0 to (L1_BLOCK_NUM - 1) loop

        --! the following spaghetti registers a cache hit
        if ((L1_cache(i).tag <= unsigned(I_addr)) AND 
          (unsigned(I_addr) <= (L1_cache(i).tag + (((L1_WORDS_IN_BLOCK)-1) * ADDR_INTRVL)))) then

        	--! set carry
        	s_carry_en <= '1';
          
          --! adjust cache hits and last access value
          cache_L1_miss <= '0';
          L1_cache(i).last_access <= 0;

          --! if write enabled then you need to store I_data
          if I_we = '1' then
            for j in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
              if ((unsigned(L1_cache(i).tag) + (j * ADDR_INTRVL)) <= unsigned(I_addr)) AND ((unsigned(L1_cache(i).tag) + ((j+1) * ADDR_INTRVL)) > unsigned(I_addr)) then
              	if (I_byte_mode='1') then --! SB
              		s_aux <= L1_cache(i).data(j);
              		s_aux(7 downto 0) <= I_data(7 downto 0);
              		L1_cache(i).data(j) <= s_aux;
              	else --! SW
                	L1_cache(i).data(j) <= I_data; --! data is written!!!!!
                end if;
              end if;
            end loop;

          --! else we retrieve data from this cache
          else
            for j in 0 to ((L1_WORDS_IN_BLOCK)-1) loop
              if ((unsigned(L1_cache(i).tag) + (j * ADDR_INTRVL)) <= unsigned(I_addr)) AND ((unsigned(L1_cache(i).tag) + ((j+1) * ADDR_INTRVL)) > unsigned(I_addr)) then
              	if (I_byte_mode='1') then --! LBU
              		s_aux <= L1_cache(i).data(j);
              		s_data_output(31 downto 8) <= "000000000000000000000000";
              		s_data_output(7 downto 0) <= s_aux(7 downto 0);
              	else --! LW
                	s_data_output <= L1_cache(i).data(j); --! data is found!
              	end if;
              end if;
            end loop;
          end if;
        else
          L1_cache(i).last_access <= L1_cache(i).last_access + 1;
        end if;

        --! LRU values
        if (L1_cache(i).last_access > lru_L1_accs_val) then
          lru_L1_accs_val <= L1_cache(i).last_access;
          lru_L1_block <= i;
        end if;
      end loop;

      if (cache_L1_miss='1') then
		  	L1_miss_count <= L1_miss_count + 1;
		  end if;

    end if;
  end process;

  O_block <= L1_cache(lru_L1_block);
  O_data <= s_data_output;
  O_L1_miss_count <= L1_miss_count;
  O_carry_en <= s_carry_en;
	
end architecture SYNTH_L1_CACHE;