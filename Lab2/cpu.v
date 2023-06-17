// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

`include "ALU.v"
`include "ALUControlUnit.v"
`include "ImmediateGenerator.v"
`include "Memory.v"
`include "PC.v"
`include "RegisterFile.v"
`include "2to1MUX.v"
`include "Adder.v"

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] PC_Out;
  wire [31:0] PC_In;
  wire [31:0] InstMem_Out;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [31:0] ALU_In;
  wire [31:0] ALU_Out;
  wire [31:0] ImmGen_Out;
  wire [31:0] PCAdder_Out1;
  wire [31:0] PCAdder_Out2;
  wire [31:0] PCAdderMux_Out;
  wire [31:0] DataMem_Out;
  wire [31:0] DataMemMux_Out;
  wire [31:0] WriteData;
  
  /***** Register declarations *****/
  wire JAL;
  wire JALR;
  wire Branch;
  wire bcond;
  wire ALUSrc;
  wire RegWrite;
  wire MemWrite;
  wire MemToReg;
  wire MemRead;
  wire PCtoReg;
  wire [3:0] ALUOp;
  wire isEcall;
  wire [31:0] x17;
  reg haltFlag;
  
  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(PC_In),     // input
    .current_pc(PC_Out)   // outputs
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(PC_Out),    // input
    .dout(InstMem_Out)     // output
  );

// ---------- Adder for PC+4 addition ----------
  Adder PCAdder1 (
    .input_1(PC_Out),
    .input_2(4),
    .sum(PCAdder_Out1)
  );
  
// ----- mux for choosing Write Data betweem mem_data and pc+4-----
  MUX WriteDataMux (
    .a(DataMemMux_Out), //input
    .b(PCAdder_Out1), //input
    .s(PCtoReg), //control input
    .Q(WriteData) // output
   );
  
  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (InstMem_Out[19:15]),          // input
    .rs2 (InstMem_Out[24:20]),          // input
    .rd (InstMem_Out[11:7]),           // input (destination register)
    .rd_din (WriteData),       // input (data for write to rd register)
    .write_enable (RegWrite),    // control input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout),      // output
    .x17 (x17) //output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(InstMem_Out[6:0]),  // input
    .is_jal(JAL),        // output
    .is_jalr(JALR),       // output
    .branch(Branch),        // output
    .mem_read(MemRead),      // output
    .mem_to_reg(MemToReg),    // output
    .mem_write(MemWrite),     // output
    .alu_src(ALUSrc),       // output
    .write_enable(RegWrite),     // output
    .pc_to_reg(PCtoReg),     // output
    .is_ecall(isEcall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(InstMem_Out[31:0]),  // input
    .imm_gen_out(ImmGen_Out)    // output
  );

  // ---------- Mux for choosing ALU input between rs2_out and immgen_out---------
  MUX ALUInputMux (
    .a(rs2_dout),  // rs2 reg data
    .b(ImmGen_Out), // imm
    .s(ALUSrc), // control input
    .Q(ALU_In) // output
   );
  
  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .all_of_inst(InstMem_Out[31:0]),  // input
    .alu_op(ALUOp)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_in_1(rs1_dout),    // input  (from rs1 register)
    .alu_in_2(ALU_In),    // input (from ALU_in_mux)
    .alu_op(ALUOp),      // control input
    .alu_result(ALU_Out),  // output
    .alu_bcond(bcond)     // output for branch condition
  );

//  ---------- Adder for PC + IMM ----------
  Adder PCAdder2(
    .input_1(PC_Out), // input (PC value)
    .input_2(ImmGen_Out), // input (IMM value)
    .sum(PCAdder_Out2)
   );

  MUX PCAdderMux1(
    .a(PCAdder_Out1), // pc + 4
    .b(PCAdder_Out2), // pc + IMM
    .s((Branch & bcond) | JAL), // control input ( if Branch&bcond or JAL -> pc + IMM(jump) , else pc + 4(just next inst))
    .Q(PCAdderMux_Out) 
   );
   
  MUX PCAdderMux2(
    .a(PCAdderMux_Out), // pc + 4 or pc + IMM (pc-relative)
    .b(ALU_Out), // Reg + IMM (register-relative)
    .s(JALR), // control input (if JALR -> jump to reg + IMM (register-relative)
    .Q(PC_In) // next instruction
   );
   
  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (ALU_Out),       // input
    .din (rs2_dout),        // input
    .mem_read (MemRead),   // input
    .mem_write (MemWrite),  // input
    .dout (DataMem_Out)        // output
  );
  
  MUX DataMemMux(
    .a(ALU_Out), // output of  ALU
    .b(DataMem_Out), // memory data
    .s(MemToReg), // control input ( if MemToReg == 1 -> memory data to register, else -> ALU output to register)
    .Q(DataMemMux_Out) // output
   );
  
  assign is_halted = haltFlag;

  always @(*) begin
    if (isEcall == 1'b1 && x17 == 10) begin
      haltFlag = 1'b1;
    end
    else haltFlag = 1'b0;
   end
  
endmodule
