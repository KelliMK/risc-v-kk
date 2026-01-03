--! L2 data cache

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

library work;
use work.my_constants.all;

ENTITY L2_cache IS
	PORT(
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
end L2_cache;

architecture SYNTH_L2_CACHE of L2_cache is

	signal cache_L2_miss : std_logic := '0';
	signal lru_L2_accs_val : integer := 0;
	signal lru_L2_block : integer := 0;
	signal L2_miss_count : integer := 0;
	signal s_data_output : std_logic_vector(31 downto 0);
	signal s_carry_en : std_logic;
	signal s_aux : std_logic_vector(31 downto 0);

	constant L2_SIZE_BYTES : integer := 1024; --! 1KB is the size of our L2 cache
	constant L2_BLOCK_NUM : integer := L2_SIZE_BYTES / L2_BLOCK_BYTES; --! number of blocks in our L2 cache
	constant L2_WORDS_IN_BLOCK : integer := L2_BLOCK_BYTES / 4;

	type word_block_L2_t is array (0 to (L2_WORDS_IN_BLOCK-1)) of std_logic_vector(31 downto 0);  --! for constructing L2 blocks

  --! L2 cache type declaration
  type L2_cache_t is array (0 to (L2_BLOCK_NUM - 1)) of L2_block_t;

  --! instantiate cache
  signal L2_cache : L2_cache_t := (others => BLOCK_RESET_L2);

begin
	process(I_clk)
	begin
		if (rising_edge(I_clk) AND (I_en = '1')) then --! necessary for time coordination

      --! write the new block to cache
      if (I_ram_block.data_present = '1') then
      	L2_cache(lru_L2_block) <= I_ram_block;
      end if;

      s_carry_en <= '0';

      --! transfer through the carry
      if (I_carry_en='1') then
      	s_data_output <= I_carry_input;
      	s_carry_en <= '1';
      	cache_L2_miss <= '0';

      --! operate like normal
      else

				--! set cache miss signals, and reset appropriately in below loops
		    cache_L2_miss <= '1';

		    --! loop through L2 cache to find the address value
		    for i in 0 to (L2_BLOCK_NUM - 1) loop

		      --! the following spaghetti registers a cache hit
		      if ((L2_cache(i).tag <= unsigned(I_addr)) AND 
		        (unsigned(I_addr) <= (L2_cache(i).tag + (((L2_WORDS_IN_BLOCK)-1) * ADDR_INTRVL)))) then
		        
		      	s_carry_en <= '1';

		        --! adjust cache hits and last access value
		        cache_L2_miss <= '0';
		        L2_cache(i).last_access <= 0;

		        --! if write enabled then you need to store I_data
	          if I_we = '1' then
	            for j in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
	              if ((unsigned(L2_cache(i).tag) + (j * ADDR_INTRVL)) <= unsigned(I_addr)) AND ((unsigned(L2_cache(i).tag) + ((j+1) * ADDR_INTRVL)) > unsigned(I_addr)) then
	              	if (I_byte_mode='1') then --! SB
	              		s_aux <= L2_cache(i).data(j);
	              		s_aux(7 downto 0) <= I_data(7 downto 0);
	              		L2_cache(i).data(j) <= s_aux;
	              	else --! SW
	                	L2_cache(i).data(j) <= I_data; --! data is written!!!!!
	                end if;
	              end if;
	            end loop;

		        --! else we retrieve data from this cache
		        else
		          for j in 0 to ((L2_WORDS_IN_BLOCK)-1) loop
		            if ((unsigned(L2_cache(i).tag) + (j * ADDR_INTRVL)) <= unsigned(I_addr)) AND ((unsigned(L2_cache(i).tag) + ((j+1) * ADDR_INTRVL)) > unsigned(I_addr)) then
		              if (I_byte_mode='1') then --! LBU
	              		s_aux <= L2_cache(i).data(j);
	              		s_data_output(31 downto 8) <= "000000000000000000000000";
	              		s_data_output(7 downto 0) <= s_aux(7 downto 0);
	              	else --! LW
	                	s_data_output <= L2_cache(i).data(j); --! data is found!
	              	end if;
		            end if;
		          end loop;
		        end if;
		      else
		        L2_cache(i).last_access <= L2_cache(i).last_access + 1;
		      end if;
		    end loop;
		  end if;

		  --! LRU
		  lru_L2_accs_val <= 0;
		  for i in 0 to (L2_BLOCK_NUM - 1) loop
		  	--! LRU values
        if (L2_cache(i).last_access > lru_L2_accs_val) then
          lru_L2_accs_val <= L2_cache(i).last_access;
          lru_L2_block <= i;
        end if;
		  end loop;

		  if (cache_L2_miss='1') then
		  	L2_miss_count <= L2_miss_count + 1;
		  end if;

    end if;
  end process;

  O_block <= L2_cache(lru_L2_block);
  O_data <= s_data_output;
  O_L2_miss_count <= L2_miss_count;
  O_carry_en <= s_carry_en;
	
end architecture SYNTH_L2_CACHE;