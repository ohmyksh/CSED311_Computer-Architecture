module ForwardingUnit(
                      input [4:0] rs1,
                      input [4:0] rs2,
                      input [4:0] EX_MEM_rd,
                      input [4:0] MEM_WB_rd,
                      input [4:0] WB_write_rd,
                      input EX_MEM_reg_write,
                      input MEM_WB_reg_write,
                      input WB_reg_write,
                      output reg [1:0] forwardA,
                      output reg [1:0] forwardB
                      );
    
    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;

        // forwardA
       if (EX_MEM_rd == rs1 && EX_MEM_reg_write && rs1 != 0) begin // dist  = 1
            forwardA = 2'b01;
       end
       else if  (MEM_WB_rd == rs1 && MEM_WB_reg_write && rs1 != 0) begin  // dist = 2
            forwardA = 2'b10;
       end
       else if (WB_write_rd == rs1 && WB_reg_write && rs1 != 0) begin // dist = 3
            forwardA = 2'b11;
       end
        
        // forwardB
       if (EX_MEM_rd == rs2 && EX_MEM_reg_write && rs2 != 0) begin // dist  = 1
            forwardB = 2'b01;
       end
       else if  (MEM_WB_rd == rs2 && MEM_WB_reg_write && rs2 != 0) begin  // dist = 2
            forwardB = 2'b10;
       end
       else if (WB_write_rd == rs2 && WB_reg_write && rs2 != 0) begin // dist = 3
            forwardB = 2'b11; 
       end
    end

endmodule


module Forwardingunit_ecall(
    input[4:0] EX_MEM_rd,
    input[4:0] MEM_WB_rd,
    input[4:0] WB_write_rd,
    input EX_MEM_reg_write, 
    input MEM_WB_reg_write,
    input WB_reg_write,
    output [1:0] forward_ecall);
    
    reg [1:0] forward_ecall_reg;

    assign forward_ecall = forward_ecall_reg;
    always @(*) begin
        if((EX_MEM_rd == 5'd17) && EX_MEM_reg_write) begin
            forward_ecall_reg = 2'b01;
        end
        else if((MEM_WB_rd == 5'd17) && MEM_WB_reg_write) begin
            forward_ecall_reg = 2'b10;
        end
        else if((WB_write_rd == 5'd17) && WB_reg_write) begin
            forward_ecall_reg = 2'b11;
        end
        else
            forward_ecall_reg = 2'b0;
    end
endmodule