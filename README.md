# RISC-V-KK

### What is RISC-V-KK?

RISC-V-KK is a simple sythesizable RISC-V CPU implementing the [RV32I ISA](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html), written in VHDL. Originally, I created a similar cpu project for a university course, but this is my personal version which I will continue updating. I plan to continue this project until I have fully written the project for implementation using an FPGA, but that may involve rewriting my codebase in Verilog, since VHDL's FPGA synthesis is rather limited unless you're able to fork over 5 digits of money to Intel. 

### RISC-V-KK is a personal project

RISC-V-KK was programmed for my own learning and as such is not meant for use in an actual technical environment. Testing was done primarily through EDAPlayground. It runs pretty slow cycles and is not really pipelined, at all. One instruction takes 6 cycles to function. It's still functional, so whatever your criticisms are, I'm not interested in hearing them.

### Future Plans for RISC-V-KK

    Finish entire ISA instruction implementations in behavioural form.
    Refactor code so it's less... unbearable
    Rewrite codebase in Verilog.
    Synthesize on an FPGA.

## License

RISC-V-KK is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.