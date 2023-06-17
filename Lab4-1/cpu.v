// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire MemRead;
  wire MemWrite;
  wire MemToReg; 
  wire AluSrc;
  wire RegWrite;
  wire PCToReg;
  wire isEcall;
  wire [3:0] ALUop;
  
  wire [31:0] PCOut;
  wire [31:0] nextPC;
  wire [31:0] InstMemOut;
  wire [31:0] DataMemOut;
  wire [31:0] ImmGenOut;
  wire [31:0] ALUResult;
  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [4:0] rs1_field;
  
  wire isBubble;
  wire PCWrite;
  wire IF_ID_Write;
  
  wire [1:0] forwardA;
  wire [1:0] forwardB;
  wire [1:0] forward_ecall;
  wire [31:0] forward_ecall_output;

  wire [31:0] ALUSrcB_MUX_Out;
  wire [31:0] Reg_Write_MUX_Out;
  wire [31:0] ForwardA_MUX_Out;
  wire [31:0] ForwardB_MUX_Out;
  
  /***** Register declarations *****/
  reg [31:0] WB_write_rd;
  reg [31:0] WB_write_data;
  reg [31:0] WB_reg_write;
  
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_is_ecall;
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rd;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  //reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_is_ecall;
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_is_ecall;
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;
    
  reg haltFlag;
  
  
  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .PC_control(PCWrite),
    .next_pc(nextPC),     // input
    .current_pc(PCOut)   // output
  );
 
  // NextPC = pc + 4
  Adder PCAdder (
    .input_1(PCOut), 
    .input_2(32'd4), 
    .sum(nextPC)
    );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(PCOut),    // input
    .dout(InstMemOut)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
        IF_ID_inst <= 0;
    end
    else  if (IF_ID_Write) begin
            IF_ID_inst <= InstMemOut;
    end
  end

 // when isEcall, change the rs1 field of instruction to 17
  assign rs1_field = (isEcall) ? 5'd17 : IF_ID_inst[19:15];
  
  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1_field),          // input
    .rs2 (IF_ID_inst[24:20]),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (Reg_Write_MUX_Out),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );

   Forwardingunit_ecall forwardingunit_ecall(
    .EX_MEM_rd(EX_MEM_rd),
    .MEM_WB_rd(MEM_WB_rd),
    .WB_write_rd(WB_write_rd),
    .EX_MEM_reg_write(EX_MEM_reg_write),
    .MEM_WB_reg_write(MEM_WB_reg_write),
    .WB_reg_write(WB_reg_write),
    .forward_ecall(forward_ecall)
  );
  
  MUX4to1 Mux_is_ecall(
    .a(rs1_dout),
    .b(EX_MEM_alu_out),
    .c(Reg_Write_MUX_Out),
    .d(WB_write_data),
    .s(forward_ecall),
    .Q(forward_ecall_output)
  );
  
 
  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .mem_read(MemRead),      // output
    .mem_to_reg(MemToReg),    // output
    .mem_write(MemWrite),     // output
    .alu_src(AluSrc),       // output
    .write_enable(RegWrite),  // output
    .pc_to_reg(PCToReg),     // output
    //.alu_op(),        // output
    .is_ecall(isEcall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst[31:0]),  // input
    .imm_gen_out(ImmGenOut)    // output
  );


// ---------- Hazard Detection Unit ----------
HazardDetectionUnit hazard_detection_unit(
    .ID_EX_mem_read(ID_EX_mem_read),
    .EX_MEM_mem_read(EX_MEM_mem_read),
    .ID_EX_rd(ID_EX_rd),
    .EX_MEM_rd(EX_MEM_rd),
    .rs1(IF_ID_inst[19:15]),
    .rs2(IF_ID_inst[24:20]),
    .is_ecall(isEcall),
    .PC_write(PCWrite),
    .IF_ID_write(IF_ID_Write),
    .isBubble(isBubble)
  );
  
  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
          ID_EX_alu_src <= 0;      // will be used in EX stage
          ID_EX_mem_write <= 0;      // will be used in MEM stage
          ID_EX_mem_read <= 0;       // will be used in MEM stage
          ID_EX_mem_to_reg <= 0;    // will be used in WB stage
          ID_EX_reg_write <= 0;
          ID_EX_rs1_data <= 0;
          ID_EX_rs2_data <= 0;
          ID_EX_imm <= 0;
          ID_EX_ALU_ctrl_unit_input <= 0;
          ID_EX_rd <= 0;
    end
    else begin
        // From the control unit
      if (isBubble != 1) begin 
            ID_EX_alu_src <= AluSrc;      // will be used in EX stage
            ID_EX_mem_write <= MemWrite;      // will be used in MEM stage
            ID_EX_mem_read <= MemRead;       // will be used in MEM stage
            ID_EX_mem_to_reg <= MemToReg;    // will be used in WB stageF
            ID_EX_reg_write <= RegWrite;
            ID_EX_is_ecall <= (forward_ecall_output == 32'd10) && isEcall;
      end
      else if (isBubble == 1) begin // bubble
            ID_EX_alu_src <= 0;      // will be used in EX stage
            ID_EX_mem_write <= 0;      // will be used in MEM stage
            ID_EX_mem_read <= 0;       // will be used in MEM stage
            ID_EX_mem_to_reg <= 0;    // will be used in WB stage
            ID_EX_reg_write <= 0;
            ID_EX_is_ecall <= 0;
      end
     
      // From others
      ID_EX_rs1_data <= rs1_dout;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_imm <= ImmGenOut;
      ID_EX_ALU_ctrl_unit_input <= IF_ID_inst;
      ID_EX_rd <= IF_ID_inst[11:7];
    end
  end

MUX2to1 ALUSrcB_MUX (
    .a(ForwardB_MUX_Out), 
    .b(ID_EX_imm), 
    .s(ID_EX_alu_src), 
    .Q(ALUSrcB_MUX_Out)
    );
    
  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .all_of_inst(ID_EX_ALU_ctrl_unit_input),  // input
    .alu_op(ALUop)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(ALUop),      // input
    .alu_in_1(ForwardA_MUX_Out),    // input  
    .alu_in_2(ALUSrcB_MUX_Out),    // input
    .alu_result(ALUResult)  // output
    //.alu_zero()     // output
  );

ForwardingUnit forwardUnit(
    .rs1 (ID_EX_ALU_ctrl_unit_input[19:15]),
    .rs2 (ID_EX_ALU_ctrl_unit_input[24:20]),
    .EX_MEM_rd (EX_MEM_rd),
    .MEM_WB_rd (MEM_WB_rd),
    .WB_write_rd(WB_write_rd),
    .EX_MEM_reg_write (EX_MEM_reg_write),
    .MEM_WB_reg_write (MEM_WB_reg_write),
    .WB_reg_write(WB_reg_write),
    .forwardA (forwardA),
    .forwardB (forwardB)
  );
  
  MUX4to1 ForwardA_MUX (
    .a(ID_EX_rs1_data),  // original
    .b(EX_MEM_alu_out),  // dist = 1
    .c(Reg_Write_MUX_Out),  // dist = 2
    .d(WB_write_data),  // dist = 3
    .s(forwardA), 
    .Q(ForwardA_MUX_Out)
    );
    
  MUX4to1 ForwardB_MUX (
    .a(ID_EX_rs2_data), 
    .b(EX_MEM_alu_out), 
    .c(Reg_Write_MUX_Out), 
    .d(WB_write_data), 
    .s(forwardB), 
    .Q(ForwardB_MUX_Out)
    );
    
  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
          EX_MEM_mem_write <= 0;     
          EX_MEM_mem_read <= 0;      
          EX_MEM_mem_to_reg <= 0;    
          EX_MEM_reg_write <= 0;     
          EX_MEM_alu_out <= 0;
          EX_MEM_dmem_data <= 0;
          EX_MEM_rd <= 0;
    end
    else begin
        // From the control unit
          EX_MEM_mem_write <= ID_EX_mem_write;     // will be used in MEM stage
          EX_MEM_mem_read <= ID_EX_mem_read;      // will be used in MEM stage
          EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;    // will be used in WB stage
          EX_MEM_reg_write <= ID_EX_reg_write;     // will be used in WB stage
          EX_MEM_is_ecall <= ID_EX_is_ecall;
          // From others
          EX_MEM_alu_out <= ALUResult;
          EX_MEM_dmem_data <= ForwardB_MUX_Out;
          EX_MEM_rd <= ID_EX_rd;
    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (DataMemOut)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
          MEM_WB_mem_to_reg <= 0;  
          MEM_WB_reg_write <= 0;   
          MEM_WB_is_ecall <= 0;
          MEM_WB_mem_to_reg_src_1 <= 0;
          MEM_WB_mem_to_reg_src_2 <= 0;
          MEM_WB_rd <= 0;
    end
    else begin
          MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;   // will be used in WB stage
          MEM_WB_reg_write <= EX_MEM_reg_write;     // will be used in WB stage
          MEM_WB_is_ecall <= EX_MEM_is_ecall;
          // From others
          MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
          MEM_WB_mem_to_reg_src_2 <= DataMemOut;
          MEM_WB_rd <= EX_MEM_rd;
    end
  end

MUX2to1 Reg_Write_MUX (
    .a(MEM_WB_mem_to_reg_src_1), 
    .b(MEM_WB_mem_to_reg_src_2), 
    .s(MEM_WB_mem_to_reg), 
    .Q(Reg_Write_MUX_Out)
    );
    
  assign is_halted = haltFlag;
  always @(*) begin
    if (MEM_WB_is_ecall == 1'b1) begin
      haltFlag = 1'b1;
    end
    else haltFlag = 1'b0;
  end
    
    always @(posedge clk) begin 
    WB_write_data <= Reg_Write_MUX_Out;
    WB_reg_write <= MEM_WB_reg_write;
    WB_write_rd <= MEM_WB_rd;
  end
endmodule
