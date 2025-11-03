library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity decoder is
  port(
    I_clk : in std_logic; --! clock bit
    I_en : in std_logic; --! enable bit
    I_inst : in std_logic_vector(31 downto 0); --! the current instruction
    O_alu_op : out std_logic_vector(5 downto 0);
    O_imm : out std_logic_vector(31 downto 0);
    O_we : out std_logic; --! write enable bit, USE IF YOU ARE WRITING TO A REGISTER
    O_rs1 : out std_logic_vector(4 downto 0);
    O_rs2 : out std_logic_vector(4 downto 0);
    O_rd : out std_logic_vector(4 downto 0)
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
        --! lw operation (load word)
        when "00000" =>
          O_imm(31 downto 12) <= I_inst(31 downto 12);
          O_imm(11 downto 0) <= "000000000000";
          O_we <= '1';
          O_alu_op <= "001101";

        --! immediate operations slti, addi, andi, ori, xori
        when "00100" => 
          O_imm(11 downto 0) <= I_inst(31 downto 20);
          if (I_inst(31)='1') then
            O_imm(31 downto 12) <= "11111111111111111111";
          else
            O_imm(31 downto 12) <= "00000000000000000000";
          end if;
          O_we <= '1';
          case I_inst(14 downto 12) is 
            when "000" =>
              O_alu_op <= "010000";
            when "010" =>
              O_alu_op <= "010001";
            when "100" =>
              O_alu_op <= "010011";
            when "110" =>
              O_alu_op <= "010100";
            when "111" =>
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

        --! sw operation
        when "01000" =>
          O_imm(31 downto 5) <= std_logic_vector(resize(signed(I_inst(31 downto 25)), 27));
          O_imm(4 downto 0) <= I_inst(11 downto 7);
          O_we <= '0';
          O_alu_op <= "011000";
        
        --! mathematical/logical operations
        when "01100" => 
          O_we <= '1';
          case I_inst(14 downto 12) is 
            when "000" =>
              if (I_inst(30)='0') then
                O_alu_op <= "011100";
              else
                O_alu_op <= "011101";
              end if;
            when "001" =>
              O_alu_op <= "011110";
            when "010" =>
              O_alu_op <= "011111";
            when "011" =>
              O_alu_op <= "100000";
            when "100" =>
              O_alu_op <= "100001";
            when "101" =>
              if (I_inst(30)='0') then
                O_alu_op <= "100010";
              else
                O_alu_op <= "100011";
              end if;
            when "110" =>
              O_alu_op <= "100100";
            when "111" =>
              O_alu_op <= "100101";
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
            when "000" =>
              O_alu_op <= "000100";
            when "001" =>
              O_alu_op <= "000101";
            when "100" =>
              O_alu_op <= "000110";
            when "101" =>
              O_alu_op <= "000111";
            when others =>
              O_alu_op <= "111111";
          end case;
        when others =>
          O_we <= '0';

      end case;
    end if;
  end process;
  
end architecture SYNTH_DECODER;