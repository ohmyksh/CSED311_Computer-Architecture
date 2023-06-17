// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

`include "Mux.v"
`include "ALU.v"
`include "ALUControlUnit.v"
`include "ImmediateGenerator.v"
`include "ControlUnit.v"
`include "Memory.v"
`include "PC.v"
`include "RegisterFile.v"


module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] PCIn;
  wire [31:0] PCOut;
  wire [31:0] WriteData;
  wire [31:0] MemData;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [31:0] ALUResult;
  wire [31:0] ImmGenOut;

  wire [31:0] PCtoMEM_Out;
  wire [31:0] WriteData_Out;
  wire [31:0] ALUsrcA_Out;
  wire [31:0] ALUsrcB_Out;
  wire [31:0] PCSource_Out;

  wire PCWriteCond;
  wire PCWrite;
  wire IorD;
  wire mem_read;
  wire mem_write;
  wire mem_to_reg;
  wire IRWrite;
  wire PCSource;
  wire [1:0] ALUCtrlop;
  wire [3:0] ALUop;
  wire [1:0] ALUSrcB;
  wire ALUSrcA;
  wire RegWrite;
  wire bcond;

  wire [31:0] IR_wire;
  wire [31:0] MDR_wire;
  wire [31:0] A_wire;
  wire [31:0] B_wire;
  wire [31:0] ALUOut_wire;
  wire [31:0] read_rs1;
  wire isEcall;


  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.
  reg haltFlag;


  assign IR_wire = IR;
  assign MDR_wire = MDR;
  assign A_wire = A;
  assign B_wire = B;
  assign ALUOut_wire = ALUOut;


  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .PC_control((bcond & PCWriteCond) | PCWrite), // input
    .next_pc(PCSource_Out),     // input
    .current_pc(PCOut)   // output
  );

  MUX2to1 WriteData_Mux (
    .a(ALUOut_wire), 
    .b(MDR_wire), 
    .s(mem_to_reg), 
    .Q(WriteData_Out)
    );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(read_rs1[19:15]),          // input
    .rs2(IR_wire[24:20]),          // input
    .rd(IR_wire[11:7]),           // input
    .rd_din(WriteData_Out),       // input
    .write_enable(RegWrite),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)      // output
  );

 MUX2to1 PCSource_Mux (
    .a(ALUResult), 
    .b(ALUOut_wire), 
    .s(PCSource), 
    .Q(PCSource_Out));
    
  MUX2to1 PCtoMEM_MUX (
    .a(PCOut), 
    .b(ALUOut_wire), 
    .s(IorD), 
    .Q(PCtoMEM_Out)
    );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(PCtoMEM_Out),         // input
    .din(B_wire),          // input
    .mem_read(mem_read),     // input
    .mem_write(mem_write),    // input
    .dout(MemData)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
     .part_of_inst(IR_wire[6:0]), // input
    .clk(clk), // input
    .reset(reset), // input
    .MemData(MemData[6:0]), //input
    .PC_write_cond(PCWriteCond), // output 
    .PC_write(PCWrite), // output
    .i_or_d(IorD), // output
    .mem_read(mem_read), // output
    .mem_write(mem_write), // output
    .mem_to_reg(mem_to_reg), // output
    .IR_write(IRWrite), // output
    .PC_source(PCSource), // output
    .ALU_op(ALUCtrlop), // output 
    .ALU_src_a(ALUSrcA), // output
    .ALU_src_b(ALUSrcB), // output 
    .reg_write(RegWrite), // output
    .is_ecall(isEcall) // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IR_wire[31:0]),  // input
    .imm_gen_out(ImmGenOut)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .all_of_inst(IR_wire[31:0]), // input
    .alu_ctrl_op(ALUCtrlop),  // input
    .alu_op(ALUop)         // output
  );

 MUX2to1 ALUsrcA_Mux (
    .a(PCOut), 
    .b(A_wire), 
    .s(ALUSrcA), 
    .Q(ALUsrcA_Out)
    );
    
  MUX4to1 ALUsrcB_Mux (
    .a(B_wire), 
    .b(4), 
    .c(ImmGenOut), 
    .d(0), 
    .s(ALUSrcB), 
    .Q(ALUsrcB_Out)
    );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(ALUop),      // input
    .alu_in_1(ALUsrcA_Out),    // input  
    .alu_in_2(ALUsrcB_Out),    // input
    .alu_result(ALUResult),  // output
    .alu_bcond(bcond)     // output
  );

 always @(posedge clk) begin
    if (reset) begin
      IR <= 0;
      MDR <= 0;
      A <= 0;
      B <= 0;
      ALUOut <= 0;
    end
    else begin
      if(IRWrite) IR <= MemData;
      MDR <= MemData;
      A <= rs1_dout;
      B <= rs2_dout;
      ALUOut <= ALUResult;
    end
  end

  assign read_rs1 = (isEcall) ? 32'd17 << 15 : IR;

  assign is_halted = haltFlag;
  always @(*) begin
    if (isEcall == 1'b1 && rs1_dout == 32'd10) begin
      haltFlag = 1'b1;
    end
    else haltFlag = 1'b0;
  end

endmodule
