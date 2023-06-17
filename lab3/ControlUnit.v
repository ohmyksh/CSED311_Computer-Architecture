`include "opcodes.v"

`define INST_FETCH 0
`define INST_DECODE_REG_FETCH 1
`define MEM_ADDR_COMPUTATION 2
`define MEM_ACCESS_READ 3
`define WB_STEP 4
`define MEM_ACCESS_WRITE 5
`define EXECUTION 6
`define R_TYPE_COMPLETION 7
`define BRANCH_COMPLETION 8
`define EXECUTION_IMM 9
`define JUMP_IMM 10
`define JUMP_IMM_EXEXTUTION 11
`define HALT 12

module ControlUnit (input [6:0] part_of_inst,
                    input clk,
                    input reset,
                    input [6:0] MemData,
                    output reg PC_write_cond,
                    output reg PC_write,
                    output reg i_or_d,
                    output reg mem_read,
                    output reg mem_write,
                    output reg mem_to_reg,
                    output reg IR_write,
                    output reg PC_source,
                    output reg [1:0] ALU_op,
                    output reg ALU_src_a,
                    output reg [1:0] ALU_src_b,
                    output reg reg_write,
                    output reg is_ecall
                    );

    reg [3:0] state;
    wire [3:0] next_state;

    always @(posedge clk) begin
            if (reset) begin
                state <= `INST_FETCH;
            end
            else begin
                state <= next_state;
            end
   end
   
   MicroFSM fsm (
        .part_of_inst(part_of_inst),
        .MemData(MemData),
        .current_state(state),
        .next_state(next_state)
        );

    always @(state) begin
        PC_write_cond = 1'b0;
        PC_write = 1'b0;
        i_or_d = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        IR_write = 1'b0;
        PC_source = 1'b0;
        ALU_op = 2'b00;
        ALU_src_a = 1'b0;
        ALU_src_b = 2'b00;
        reg_write = 1'b0;
        is_ecall = 1'b0;

        case (state)
            `INST_FETCH : begin
            mem_read = 1'b1;
            ALU_src_b = 2'b01;
            IR_write = 1'b1;
            end
            `INST_DECODE_REG_FETCH : begin
            ALU_src_b = 2'b10;
            PC_write = 1'b1;
            PC_source = 1'b1; 
            end
            `MEM_ADDR_COMPUTATION : begin
            ALU_src_a = 1'b1;
            ALU_src_b = 2'b10;
            end
            `MEM_ACCESS_READ : begin
            mem_read = 1'b1;
            i_or_d = 1'b1;
            end
            `WB_STEP : begin
            reg_write = 1'b1;
            mem_to_reg = 1'b1;
            end
            `MEM_ACCESS_WRITE : begin
            mem_write = 1'b1;
            i_or_d = 1'b1;
            end
            `EXECUTION : begin
            ALU_src_a = 1'b1;
            ALU_src_b = 2'b00;
            ALU_op = 2'b10;
            end
            `R_TYPE_COMPLETION : begin
            reg_write = 1'b1;
            end
            `BRANCH_COMPLETION : begin
            ALU_src_a = 1'b1;
            ALU_src_b = 2'b00;
            ALU_op = 2'b01;
            PC_write_cond = 1'b1;
            PC_source = 1'b1;
            end
            `EXECUTION_IMM : begin
            ALU_src_a = 1'b1;
            ALU_src_b = 2'b10;
            ALU_op = 2'b10;
            end
            `JUMP_IMM : begin
            ALU_src_b = 2'b10;
            PC_write = 1'b1;
            reg_write = 1'b1;
            end
            `JUMP_IMM_EXEXTUTION : begin
            ALU_src_a = 1'b1;
            ALU_src_b = 2'b10;
            ALU_op = 2'b10;
            PC_write = 1'b1;
            reg_write = 1'b1;
            end
            `HALT : begin
            is_ecall = 1'b1;
            end
            endcase
            end
endmodule


module MicroFSM (input [6:0] part_of_inst,
                    input [6:0] MemData,
                    input [3:0] current_state,
                    output reg [3:0] next_state);
                    
 
            always @(*) begin
                case (current_state)
                    `INST_FETCH : begin
                         if (MemData == `JAL) begin
                            next_state = `JUMP_IMM;
                        end
                        else begin
                            next_state = `INST_DECODE_REG_FETCH;
                        end
                        end
                    `INST_DECODE_REG_FETCH : begin
                            if (part_of_inst == `LOAD || part_of_inst == `STORE) begin
                                next_state = `MEM_ADDR_COMPUTATION;
                            end else if (part_of_inst == `ARITHMETIC) begin
                                next_state = `EXECUTION;
                            end else if (part_of_inst == `BRANCH) begin
                                next_state = `BRANCH_COMPLETION;
                            end else if (part_of_inst == `ECALL) begin
                                next_state = `HALT;
                            end else if (part_of_inst == `ARITHMETIC_IMM) begin
                                next_state = `EXECUTION_IMM;
                            end else if (part_of_inst == `JALR) begin
                                next_state = `JUMP_IMM_EXEXTUTION;
                            end
                      end
                    `MEM_ADDR_COMPUTATION : begin
                            if(part_of_inst == `LOAD) begin
                                next_state = `MEM_ACCESS_READ;
                            end else if(part_of_inst == `STORE) begin
                                next_state = `MEM_ACCESS_WRITE;
                            end
                     end
                    `MEM_ACCESS_READ : begin
                          next_state = `WB_STEP;
                     end
                     `WB_STEP : begin
                          next_state = `INST_FETCH;
                     end
                     `MEM_ACCESS_WRITE : begin
                          next_state = `INST_FETCH;
                     end
                      `EXECUTION : begin
                          next_state = `R_TYPE_COMPLETION;
                     end
                      `R_TYPE_COMPLETION : begin
                          next_state = `INST_FETCH;
                     end 
                      `BRANCH_COMPLETION : begin
                          next_state = `INST_FETCH;
                     end 
                      `HALT : begin
                           next_state = `INST_FETCH;
                     end
                      `EXECUTION_IMM : begin
                          next_state = `R_TYPE_COMPLETION;
                     end
                      `JUMP_IMM : begin
                          next_state = `INST_FETCH;
                     end
                      `JUMP_IMM_EXEXTUTION : begin
                          next_state = `INST_FETCH;
                      end
                         endcase
        end
 endmodule