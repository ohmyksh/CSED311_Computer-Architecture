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
  
  wire is_hazard;
  wire PCWrite;
  wire IF_ID_write;
  
  wire [31:0] Forward_Dist_1;
  wire [31:0] Forward_Dist_2;
  wire [1:0] forwardA;
  wire [1:0] forwardB;
  wire [1:0] forward_ecall;
  wire [31:0] foward_ecall_output;
  
  wire [31:0] ALUSrcB_MUX_Out;
  wire [31:0] Reg_Write_MUX_Out;
  wire [31:0] ForwardA_MUX_Out;
  wire [31:0] ForwardB_MUX_Out;
  wire [31:0] Write_Data_MUX_Out; 
  
  //  control flow instruction
  wire [31:0] pc_plus_4;
  wire [31:0] pc_plus_imm;
  wire is_jal;
  wire is_jalr;
  wire is_branch;
  wire bcond;
  wire is_flush;

  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  // control flow instruction
  reg [31:0] IF_ID_pc_plus_4;
  reg [31:0] IF_ID_pc;
  reg IF_ID_is_flush;
  reg [4:0] IF_ID_BHSR;

  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_pc_to_reg; 
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rd;
  reg ID_EX_is_ecall; 
  //  control flow instruction
  reg [31:0] ID_EX_pc_plus_4;
  reg ID_EX_is_jal;
  reg ID_EX_is_jalr;
  reg ID_EX_branch;
  reg [31:0] ID_EX_pc;
  reg [4:0] ID_EX_BHSR;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_is_ecall;
  reg EX_MEM_pc_to_reg;  
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  //  control flow instruction
  reg [31:0] EX_MEM_pc_plus_4;
  
  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_is_ecall;
  reg MEM_WB_pc_to_reg;   
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;
  //  control flow instruction
  reg [31:0] MEM_WB_pc_plus_4;
  
   reg [1:0] pc_src;
   reg haltFlag;
   reg [31:0] correct_pc;
   wire [31:0] predicted_pc;
   reg is_miss_pred;
   wire [4:0] BHSR;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .PC_control(PCWrite),
    .next_pc(nextPC),     // input
    .current_pc(PCOut)   // output
  );

//------------- pc + 4-----------------
  Adder PCAdder(
      .input_1(PCOut),
      .input_2(32'd4),
      .sum(pc_plus_4)
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
              IF_ID_inst <=0;
              IF_ID_pc <=0;
              IF_ID_pc_plus_4 <=0;
              IF_ID_is_flush <=0;
              IF_ID_BHSR <= 0;
    end
    else if (IF_ID_write) begin
              IF_ID_inst <= InstMemOut;
              IF_ID_pc <= PCOut;
              IF_ID_pc_plus_4 <= pc_plus_4;
              IF_ID_is_flush <= is_flush; 
              IF_ID_BHSR <= BHSR;
    end
  end

// when isEcall, change the rs1 field of instruction to 17
  assign rs1_field = (isEcall) ? 5'd17 : IF_ID_inst[19:15];

// ------------MUX for write data -----------
  MUX2to1 Write_Data_MUX (
    .a(Reg_Write_MUX_Out), // alu or memory data
    .b(MEM_WB_pc_plus_4), // pc + 4
    .s(MEM_WB_pc_to_reg),
    .Q(Write_Data_MUX_Out)
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1_field),          // input
    .rs2 (IF_ID_inst[24:20]),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (Write_Data_MUX_Out),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );

// ----------Data forwarding for ecall ----------
  Forwardingunit_ecall forwardingunit_ecall (
    .EX_MEM_rd(EX_MEM_rd),
    .MEM_WB_rd(MEM_WB_rd),
    .WB_write_rd(32'b0),
    .EX_MEM_reg_write(EX_MEM_reg_write),
    .MEM_WB_reg_write(MEM_WB_reg_write),
    .WB_reg_write(WB_reg_write),
    .forward_ecall(forward_ecall) // mux control
  );

//---------data forwarding ----------
  assign Forward_Dist_1 = EX_MEM_pc_to_reg? EX_MEM_pc_plus_4 : EX_MEM_alu_out;
  assign Forward_Dist_2 = MEM_WB_pc_to_reg ? MEM_WB_pc_plus_4 : Reg_Write_MUX_Out;  
  
  MUX4to1 Mux_is_ecall (
    .a(rs1_dout),
    .b(Forward_Dist_1),
    .c(Forward_Dist_2),
    .d(32'b0),
    .s(forward_ecall),
    .Q(foward_ecall_output)
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .is_jal(is_jal),   // output 
    .is_jalr(is_jalr),   // output 
    .branch(is_branch),  // output 
    .mem_read(MemRead),      // output
    .mem_to_reg(MemToReg),    // output
    .mem_write(MemWrite),     // output
    .alu_src(AluSrc),       // output
    .write_enable(RegWrite),     // output 
    .pc_to_reg(PCToReg),  // output 
    .is_ecall(isEcall)       // output 
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(ImmGenOut)    // output
  );

// ---------- Hazard Detection Unit ----------
  HazardDetectionUnit hdu(
    .ID_EX_mem_read(ID_EX_mem_read),
    .EX_MEM_mem_read(EX_MEM_mem_read),
    .ID_EX_rd(ID_EX_rd),
    .EX_MEM_rd(EX_MEM_rd),
    .rs1(rs1_field),
    .rs2(IF_ID_inst[24:20]),
    .is_ecall(isEcall),
    .PC_write(PCWrite),
    .IF_ID_write(IF_ID_write),
    .isBubble(is_hazard)
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset | is_hazard | is_flush | IF_ID_is_flush) begin
      // From the control unit
      ID_EX_alu_src<=0;        // will be used in EX stage
      ID_EX_alu_op<=0;         // will be used in EX stage
      ID_EX_mem_write<=0;      // will be used in MEM stage
      ID_EX_mem_read<=0;       // will be used in MEM stage
      ID_EX_mem_to_reg<=0;     // will be used in WB stage
      ID_EX_reg_write<=0;      // will be used in WB stage
      ID_EX_is_jal<=0;
      ID_EX_is_jalr<=0;
      ID_EX_branch<=0;
      ID_EX_pc_to_reg<=0;
      
      ID_EX_rs1_data<=0;
      ID_EX_rs2_data<=0;
      ID_EX_rd<=0;
      ID_EX_imm<=0;
      ID_EX_ALU_ctrl_unit_input <= 0; // instruction
      ID_EX_pc_plus_4<=0;
      ID_EX_pc<=0;
      ID_EX_BHSR <= 0;
      
      // for is_halted
      ID_EX_is_ecall<=0;
    end
    else begin
      // From the control unit
      ID_EX_alu_src<=AluSrc;        // will be used in EX stage
      ID_EX_mem_write<=MemWrite;      // will be used in MEM stage
      ID_EX_mem_read<=MemRead;       // will be used in MEM stage
      ID_EX_mem_to_reg<=MemToReg;     // will be used in WB stage
      ID_EX_reg_write<=RegWrite;      // will be used in WB stage
      ID_EX_is_jal<=is_jal;
      ID_EX_is_jalr<=is_jalr;
      ID_EX_branch<=is_branch;
      ID_EX_pc_to_reg<=PCToReg;
      
      ID_EX_rs1_data<=rs1_dout;
      ID_EX_rs2_data<=rs2_dout;
      ID_EX_rd<=IF_ID_inst[11:7];
      ID_EX_imm<=ImmGenOut; 
      ID_EX_ALU_ctrl_unit_input<=IF_ID_inst;    
      ID_EX_pc_plus_4<=IF_ID_pc_plus_4;
      ID_EX_pc<=IF_ID_pc;
      ID_EX_BHSR <= IF_ID_BHSR;
      // for is_halted
      ID_EX_is_ecall<=  (foward_ecall_output==32'd10) && isEcall;
    end
  end

    // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .all_of_inst(ID_EX_ALU_ctrl_unit_input),  // input
    .alu_op(ALUop)         // output
  );
  
// -------compute mux control for data forwarding -------
  ForwardingUnit forwardUnit (
    .rs1(ID_EX_ALU_ctrl_unit_input[19:15]),
    .rs2(ID_EX_ALU_ctrl_unit_input[24:20]),
    .EX_MEM_rd(EX_MEM_rd),
    .MEM_WB_rd(MEM_WB_rd),
    .WB_write_rd(32'b0),
    .EX_MEM_reg_write(EX_MEM_reg_write),
    .MEM_WB_reg_write(MEM_WB_reg_write),
    .WB_reg_write(32'b0),
    .forwardA(forwardA),
    .forwardB(forwardB)
  );

// -------data forwarding for alu src A -------
  MUX4to1 ForwardA_MUX (
    .a(ID_EX_rs1_data), // original
    .b(Forward_Dist_1), // dist = 1
    .c(Forward_Dist_2), // dist = 2
    .d(32'b0), // dist = 3
    .s(forwardA),
    .Q(ForwardA_MUX_Out)
  );

// -------data forwarding for alu src B -------
  MUX4to1 ForwardB_MUX (
    .a(ID_EX_rs2_data), 
    .b(Forward_Dist_1),
    .c(Forward_Dist_2),
    .d(32'b0),
    .s(forwardB),
    .Q(ForwardB_MUX_Out) 
  );
  
  // -------choose between forwarded data and imm -------
    MUX2to1 ALUSrcB_MUX (
    .a(ForwardB_MUX_Out), 
    .b(ID_EX_imm),
    .s(ID_EX_alu_src),
    .Q(ALUSrcB_MUX_Out) 
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_in_1(ForwardA_MUX_Out),    // input  
    .alu_in_2(ALUSrcB_MUX_Out),    // input
    .alu_op(ALUop),      // input
    .alu_result(ALUResult),  // output
    .alu_bcond(bcond)
  );
  
  // -----------PC + imm ------------
  Adder pc_imm_adder(
    .input_1(ID_EX_pc),
    .input_2(ID_EX_imm),
    .sum(pc_plus_imm)
  );

// ------------BTB for branch prediction --------
BTB btb(
    .pc(PCOut),
    .IF_ID_pc(IF_ID_pc),
    .ID_EX_pc(ID_EX_pc),
    .reset(reset),
    .clk(clk),
    .ID_EX_is_jal(ID_EX_is_jal),
    .ID_EX_is_jalr(ID_EX_is_jalr),
    .ID_EX_branch(ID_EX_branch),
    .ID_EX_bcond(bcond),
    .pc_plus_imm(pc_plus_imm),
    .reg_plus_imm(ALUResult),
    .ID_EX_BHSR(ID_EX_BHSR),
    .BHSR(BHSR),
    .predicted_pc(predicted_pc) // output
  );

  // mux part for correct_pc
  always @(*) begin
    if(ID_EX_is_jalr) begin
      correct_pc=ALUResult;
    end
    else if(ID_EX_is_jal) begin
      correct_pc=pc_plus_imm;
    end
    else if(ID_EX_branch&bcond) begin
      correct_pc=pc_plus_imm;
    end
    else begin
      correct_pc=ID_EX_pc_plus_4;
    end
  end 
  
    // determine the correctness of prediction
   always @(*) begin
        is_miss_pred = 0;
        if(ID_EX_pc != 0) begin
            if(IF_ID_pc != correct_pc) begin
                is_miss_pred=1;
            end
        end
    end 
    
   assign nextPC = is_miss_pred ? correct_pc : predicted_pc;
  // --------  determine the correctness of  branch prediction --------------
   assign is_flush = is_miss_pred;
   
  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
     // from the control unit
      EX_MEM_mem_write<=0;
      EX_MEM_mem_read<=0;
      EX_MEM_mem_to_reg<=0;
      EX_MEM_reg_write<=0;
      EX_MEM_pc_to_reg<=0;
      
      EX_MEM_rd<=0;
      EX_MEM_alu_out<=0;
      EX_MEM_dmem_data<=0;
      EX_MEM_pc_plus_4<=0;
      
      // for is_halted
      EX_MEM_is_ecall<=0;
    end
    else begin
     // from the control unit
      EX_MEM_mem_write<=ID_EX_mem_write;
      EX_MEM_mem_read<=ID_EX_mem_read;
      EX_MEM_mem_to_reg<=ID_EX_mem_to_reg;
      EX_MEM_reg_write<=ID_EX_reg_write;
      EX_MEM_pc_to_reg<=ID_EX_pc_to_reg;
      
      EX_MEM_rd<=ID_EX_rd;
      EX_MEM_alu_out<=ALUResult;
      EX_MEM_dmem_data<=ForwardB_MUX_Out;
      EX_MEM_pc_plus_4<=ID_EX_pc_plus_4;
      
      // for is_halted
      EX_MEM_is_ecall<=ID_EX_is_ecall;
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
    // from the control unit
      MEM_WB_mem_to_reg<=0;
      MEM_WB_reg_write<=0;
       MEM_WB_pc_to_reg<=0;
       
      MEM_WB_rd<=0;
      MEM_WB_pc_plus_4<=0;
      MEM_WB_mem_to_reg_src_1<=0;
      MEM_WB_mem_to_reg_src_2<=0;
      
      // for is_halted
      MEM_WB_is_ecall<=0;
    end
    else begin
     // from the control unit
      MEM_WB_mem_to_reg<=EX_MEM_mem_to_reg;
      MEM_WB_reg_write<=EX_MEM_reg_write;
      MEM_WB_pc_to_reg<=EX_MEM_pc_to_reg;
      
      MEM_WB_rd<=EX_MEM_rd;
      MEM_WB_pc_plus_4<=EX_MEM_pc_plus_4;
      MEM_WB_mem_to_reg_src_1<=EX_MEM_alu_out; 
      MEM_WB_mem_to_reg_src_2<=DataMemOut;
     
      
      // for is_halted
      MEM_WB_is_ecall<=EX_MEM_is_ecall;
    end
  end

// -----------reg_write_data MUX------------
 MUX2to1 Reg_Write_MUX (
    .a(MEM_WB_mem_to_reg_src_1), // EX_MEM_alu_out
    .b(MEM_WB_mem_to_reg_src_2), // DataMemOut
    .s(MEM_WB_mem_to_reg),
    .Q(Reg_Write_MUX_Out)
  );

// ------------is_halted-------------------
  assign is_halted  = haltFlag;
  always @(*) begin
    if (MEM_WB_is_ecall == 1'b1) begin
        haltFlag = 1'b1;
    end
    else haltFlag = 1'b0;
  end
  
endmodule