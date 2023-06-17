`include "opcodes.v"

module ALUControlUnit(
    input [31:0] all_of_inst,  // input
    input [1:0] alu_ctrl_op, 
    output reg [3:0] alu_op      // output
    );

    always @(*) begin
        alu_op = 4'b0000;
        if (alu_ctrl_op == 2'b00) begin // add (load, store)
            alu_op = 4'b0000;
        end
        else if  (alu_ctrl_op == 2'b01) begin // sub -> branch
            case(all_of_inst[14:12])
                `FUNCT3_BEQ: alu_op = 4'b0000;
                `FUNCT3_BNE: alu_op = 4'b1010;
                `FUNCT3_BLT: alu_op = 4'b1000;
                `FUNCT3_BGE: alu_op = 4'b1011;
            endcase
        end
        else begin // if (alu_ctrl_op == 2'b10) begin // ALU operations
             if (all_of_inst[6:0] == `ARITHMETIC || all_of_inst[6:0] == `ARITHMETIC_IMM) begin
                case(all_of_inst[14:12])
                `FUNCT3_ADD:
                begin
                if (all_of_inst[6:0] ==`ARITHMETIC) 
                     alu_op = (all_of_inst[31:25] == `FUNCT7_SUB) ? 4'b0001 : 4'b0000;
                else if (all_of_inst[6:0] ==`ARITHMETIC_IMM) 
                     alu_op = 4'b0000;
                end
                `FUNCT3_SLL: alu_op = 4'b1010;
                `FUNCT3_XOR: alu_op = 4'b1000;
                `FUNCT3_SRL: alu_op = 4'b1011;
                `FUNCT3_OR: alu_op = 4'b0101;
                `FUNCT3_AND: alu_op = 4'b0100;
                endcase
            end
        end
        end
endmodule