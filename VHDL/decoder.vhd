library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity decoder is
  port(
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
end decoder;

architecture SYNTH_DECODER of decoder is
begin
  process (I_clk)
  begin
    if rising_edge(I_clk) and (I_en = '1') then
      O_rs1 <= I_inst(19 downto 15);
      O_rs2 <= I_inst(24 downto 20);
      O_rd <= I_inst(11 downto 7);
      O_alu_op <= I_inst(6 downto 1);

      case I_inst(6 downto 2) is 
        --! load operations
        when "00000" =>

          O_imm(11 downto 0) <= I_inst(31 downto 20);
          if (I_inst(31)='0') then
            O_imm(31 downto 12) <= "00000000000000000000";
          else
            O_imm(31 downto 12) <= "11111111111111111111";
          end if;
          O_we <= '1';

          case I_inst(14 downto 12) is            
            when "000" => --! LB
              O_alu_op <= "001011";
            
            when "001" => --! LH
              O_alu_op <= "001100";
            
            when "010" => --! LW
              O_alu_op <= "001101";
            
            when "100" => --! LBU
              O_alu_op <= "001110";

            when "101" => --! LHU
              O_alu_op <= "001111";

            when others =>
              O_alu_op <= "111111";
          end case;

        --! immediate operations slti, addi, andi, ori, xori, slli
        when "00100" => 
          O_imm(11 downto 0) <= I_inst(31 downto 20);
          if (I_inst(31)='1') then
            O_imm(31 downto 12) <= "11111111111111111111";
          else
            O_imm(31 downto 12) <= "00000000000000000000";
          end if;
          O_we <= '1';
          case I_inst(14 downto 12) is 
            when "000" => --! ADDI
              O_alu_op <= "010000";
            when "001" => --! SLLI
              O_imm(11 downto 5) <= "0000000";
              O_imm(4 downto 0) <= I_inst(24 downto 20);
              O_alu_op <= "011001";
            when "010" => --! SLTI
              O_alu_op <= "010001";
            when "100" => --! XORI
              O_alu_op <= "010011";
            when "110" => --! ORI
              O_alu_op <= "010100";
            when "111" => --! ANDI
              O_alu_op <= "010101";
            when others =>
              O_alu_op <= "111111";
          end case;

        --! auipc operation
        when "00101" => 
          O_we <= '1';
          O_imm(31 downto 12) <= I_inst(31 downto 12);
          O_imm(11 downto 0) <= "000000000000";
          O_alu_op <= "000010";

        --! store operations
        when "01000" =>
          O_imm(31 downto 5) <= std_logic_vector(resize(signed(I_inst(31 downto 25)), 27));
          O_imm(4 downto 0) <= I_inst(11 downto 7);
          O_we <= '0';
          
          case I_inst(14 downto 12) is 
            when "000" => --! SB
              O_alu_op <= "010110";

            when "001" => --! SH
              O_alu_op <= "010111";
            
            when "010" => --! SW
              O_alu_op <= "011000";

            when others =>
              O_alu_op <= "111111";
          end case;
        
        --! mathematical/logical operations
        when "01100" => 
          O_we <= '1';
          case I_inst(14 downto 12) is 
            when "000" =>
              if (I_inst(30)='0') then
                O_alu_op <= "011100"; --! ADD
              else
                O_alu_op <= "011101"; --! SUB
              end if;
            when "001" =>
              O_alu_op <= "011110"; --! SLL
            when "010" =>
              O_alu_op <= "011111"; --! SLT
            when "011" =>
              O_alu_op <= "100000"; --! SLTU
            when "100" =>
              O_alu_op <= "100001"; --! XOR
            when "101" =>
              if (I_inst(30)='0') then
                O_alu_op <= "100010"; --! SRL
              else
                O_alu_op <= "100011"; --! SRA
              end if;
            when "110" =>
              O_alu_op <= "100100"; --! OR
            when "111" =>
              O_alu_op <= "100101"; --! AND
            when others =>
              O_alu_op <= "111111";
          end case;

        --! lui operation
        when "01101" => 
          O_we <= '1';
          O_imm(31 downto 12) <= I_inst(31 downto 12);
          O_imm(11 downto 0) <= "000000000000";
          O_alu_op <= "000001";

        --! branching operations
        when "11000" =>
          O_we <= '0';
          if (I_inst(31)='0') then
            O_imm(31 downto 12) <= "00000000000000000000";
          else
            O_imm(31 downto 12) <= "11111111111111111111";
          end if;
          O_imm(11) <= I_inst(7);
          O_imm(10 downto 5) <= I_inst(30 downto 25);
          O_imm(4 downto 1) <= I_inst(11 downto 8);
          O_imm(0) <= '0';
          case I_inst(14 downto 12) is 
            when "000" => --! BEQ
              O_alu_op <= "000100";
            when "001" => --! BNE
              O_alu_op <= "000101";
            when "100" => --! BLT
              O_alu_op <= "000110";
            when "101" => --! BGE
              O_alu_op <= "000111";
            when others =>
              O_alu_op <= "111111";
          end case;

        --! JALR operation
        when "11001" =>
          O_we <= '1';
          if (I_inst(31)='1') then
            O_imm(31 downto 12) <= "11111111111111111111";
          else
            O_imm(31 downto 12) <= "00000000000000000000";
          end if;
          O_alu_op <= "001010";

        --! JAL operation
        when "11011" =>
          O_we <= '1';
          if (I_inst(31)='1') then
            O_imm(31 downto 21) <= "11111111111";
          else
            O_imm(31 downto 21) <= "00000000000";
          end if;
          O_imm(20) <= I_inst(31);
          O_imm(19 downto 12) <= I_inst(19 downto 12);
          O_imm(11) <= I_inst(20);
          O_imm(10 downto 1) <= I_inst(30 downto 21);
          O_imm(0) <= '0';
          O_alu_op <= "000011";

        --! ECALL operation
        when "11100" =>
          O_we <= '0';
          O_alu_op <= "100111";

        when others =>
          O_we <= '0';
          O_alu_op <= "111111";

      end case;
    end if;
  end process;
  
end architecture SYNTH_DECODER;