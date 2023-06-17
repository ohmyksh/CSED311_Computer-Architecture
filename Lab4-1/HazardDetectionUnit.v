module HazardDetectionUnit(
                           input ID_EX_mem_read,
                           input EX_MEM_mem_read,
                           input [4:0] ID_EX_rd,
                           input [4:0] EX_MEM_rd,
                           input [4:0] rs1,
                           input [4:0] rs2,
                           input is_ecall,
                           output reg PC_write,
                           output reg IF_ID_write,
                           output reg isBubble
);

    wire load_hazard;
    wire ecall_hazard;
    wire load_ecall_hazard;
    
    assign load_hazard = (ID_EX_mem_read && ID_EX_rd != 0) && ((ID_EX_rd == rs1) || (ID_EX_rd == rs2));
    assign ecall_hazard = is_ecall && (ID_EX_rd == 17);
    assign load_ecall_hazard = is_ecall && (EX_MEM_rd == 17) && (EX_MEM_mem_read);
    
    always @(*) begin
        PC_write = 1'b1;
        IF_ID_write = 1'b1;
        isBubble = 1'b0;
        
        if ( load_hazard || ecall_hazard || load_ecall_hazard ) begin
            PC_write = 1'b0;
            IF_ID_write = 1'b0;
            isBubble = 1'b1;
        end
    end

endmodule