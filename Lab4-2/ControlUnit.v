`include "opcodes.v"

module ControlUnit (
                    input [6:0] part_of_inst,
                    output reg is_jal,
                    output reg is_jalr,
                    output reg branch,
                    output reg mem_read,
                    output reg mem_to_reg,
                    output reg mem_write,
                    output reg alu_src,
                    output reg write_enable,
                    output reg pc_to_reg,
                    output reg is_ecall);

    always @(*) begin
        is_jal = 1'b0;
        is_jalr = 1'b0;
        branch = 1'b0;
        mem_read = 1'b0;
        mem_to_reg = 1'b0;
        mem_write = 1'b0;
        alu_src = 1'b0;
        write_enable = 1'b0;
        pc_to_reg = 1'b0;
        is_ecall = 1'b0;
        
        case(part_of_inst)
        
        `ARITHMETIC: 
            begin
            //mem_write = 1'b1;
            write_enable = 1'b1;
            end
        `ARITHMETIC_IMM: 
            begin  
            //mem_write = 1'b1;
            alu_src = 1'b1;
            write_enable = 1'b1;
            end
            
         `LOAD:
            begin 
            mem_read = 1'b1;
            mem_to_reg = 1'b1;
            alu_src = 1'b1; 
            write_enable = 1'b1;
            end

        `STORE: 
            begin 
            mem_write = 1'b1;
            alu_src = 1'b1;
            end

        `BRANCH: branch = 1'b1;
        
        `JAL:
            begin 
            is_jal = 1'b1;
            write_enable = 1'b1;
            pc_to_reg = 1'b1;
            end
        
        `JALR:
            begin 
            is_jalr = 1'b1;
            alu_src = 1'b1;
            write_enable = 1'b1;
            pc_to_reg = 1'b1;
            end

        `ECALL: is_ecall = 1'b1;
        endcase
    end

endmodule