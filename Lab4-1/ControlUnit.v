`include "opcodes.v"

module ControlUnit(input [6:0] part_of_inst,
                   output reg mem_read,
                   output reg mem_to_reg,
                   output reg mem_write,
                   output reg alu_src,
                   output reg write_enable,
                   output reg pc_to_reg,
                   //output alu_op,
                   output reg is_ecall);

    always @(part_of_inst) begin
        mem_read = 1'b0;
        mem_to_reg = 1'b0;
        mem_write = 1'b0;
        alu_src = 1'b0;
        write_enable = 1'b0;
        pc_to_reg = 1'b0;
        //alu_op = 1'b0;
        is_ecall = 1'b0;
        
         if (part_of_inst == `ARITHMETIC) 
            begin
            //mem_write = 1'b1;
            write_enable = 1'b1;
            end
        
        if (part_of_inst ==  `ARITHMETIC_IMM)
            begin  
            //mem_write = 1'b1;
            alu_src = 1'b1;
            write_enable = 1'b1;
            end
            
         if (part_of_inst == `LOAD)
            begin 
            mem_read = 1'b1;
            mem_to_reg = 1'b1;
            alu_src = 1'b1; 
            write_enable = 1'b1;
            end

        if (part_of_inst == `STORE)
            begin 
            mem_write = 1'b1;
            alu_src = 1'b1;
            end

        if(part_of_inst == `ECALL) begin
            is_ecall = 1'b1;
        end
    end

endmodule