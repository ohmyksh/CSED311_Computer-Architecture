module BTB(
            input [31:0] pc, // in IF stage
            input [31:0] IF_ID_pc, // in ID stage
            input [31:0] ID_EX_pc, // in EX stage
            input reset,
            input clk,
            input ID_EX_is_jal, // ID_EX
            input ID_EX_is_jalr, // ID_EX
            input ID_EX_branch, // ID_EX
            input ID_EX_bcond, // in EX stage
            input [31:0] pc_plus_imm, // in EX stage
            input [31:0] reg_plus_imm, // in EX stage
            input [4:0] ID_EX_BHSR,
            output reg [4:0] BHSR,
            output reg [31:0] predicted_pc // in IF stage
            );

    // wire declaration
    // for prediction
    wire [24:0] tag;
    wire [4:0] index;
   // for updating BTB and tag after determining corrrectness of prediction
    wire [24:0] write_tag;
    wire [4:0] write_index;
    wire is_controlflow;
    // 2bit predictor 
    wire is_taken;
    reg [1:0] BHT[0:31];
  
    // reg declaration
    reg [31:0] BTB[0:31];
    reg [24:0] tag_table[0:31];
    reg [5:0] i;
    
    // assignment
    assign tag = pc[31:7];
    assign index = pc[6:2]^BHSR;
    
    assign write_tag = ID_EX_pc[31:7];
    assign write_index = ID_EX_pc[6:2]^ID_EX_BHSR;

    assign is_taken = (ID_EX_branch & ID_EX_bcond) | ID_EX_is_jal | ID_EX_is_jalr;
    
//------------ BTB & tag table initialization-----------
    always @(posedge clk) begin
        if (reset) begin
            for(i = 0; i < 32  ; i = i + 1) begin
                BTB[i] <= 0;
                tag_table[i] <= -1; 
                BHT[i] <= 2'b00;
            end
            BHSR <= 5'b00000;
        end
    end
 
 // ----------predict the next pc in IF stage -------------
    always @(*) begin
        if((tag_table[index] == tag) & (BHT[index] >= 2'b10) & (BTB[index] != 0)) begin
            predicted_pc = BTB[index];
        end
        else begin
            predicted_pc = pc+4;
        end
    end

// determine the correctness of prediction
   always @(posedge clk) begin
        if(ID_EX_is_jal | (ID_EX_branch&ID_EX_bcond)) begin
            if((tag_table[write_index] != write_tag) | (BTB[write_index] != pc_plus_imm)) begin
                tag_table[write_index] <= write_tag;
                BTB[write_index] <= pc_plus_imm;
            end
        end
        else if(ID_EX_is_jalr) begin
            if((tag_table[write_index] != write_tag) | (BTB[write_index] != reg_plus_imm)) begin
                tag_table[write_index] <= write_tag;
                BTB[write_index] <= reg_plus_imm;
           end
        end
    end
    
    // 2-bit saturation counter 
    always @(posedge clk) begin 
        if (ID_EX_branch | ID_EX_is_jal | ID_EX_is_jalr) begin
            if (is_taken) begin
                BHSR = {BHSR[3:0], 1'b1};
                case(BHT[write_index]) 
                    2'b00 : BHT[write_index] <= 2'b01;
                    2'b01 : BHT[write_index] <= 2'b10;
                    2'b10 : BHT[write_index] <= 2'b11;
                    2'b11 : BHT[write_index] <= 2'b11;
                endcase
            end
           else begin
                BHSR = {BHSR[3:0], 1'b0};
                case(BHT[write_index]) 
                        2'b00 : BHT[write_index] <= 2'b00;
                        2'b01 : BHT[write_index] <= 2'b00;
                        2'b10 : BHT[write_index] <= 2'b01;
                        2'b11 : BHT[write_index] <= 2'b10;
                endcase
            end
        end
     end
endmodule
