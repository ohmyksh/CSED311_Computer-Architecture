module ALU (
   input [3:0] alu_op,
   input [31:0] alu_in_1, 
   input [31:0] alu_in_2,
   output reg [31:0] alu_result,
   output reg alu_bcond);

always @(*) begin
   alu_bcond = 0;
   case(alu_op)
      4'b0000: //signed addition or BEQ
         begin
            alu_result = alu_in_1 + alu_in_2;
            alu_bcond = (alu_in_1 == alu_in_2); 
         end
      4'b0001: //signend subtraction
        alu_result = alu_in_1 - alu_in_2;
      4'b0010: //identity
        alu_result = alu_in_1;
      4'b0011: //bitwise not
        alu_result = ~ alu_in_1;
      4'b0100: //bitwise and
        alu_result = alu_in_1 & alu_in_2;
      4'b0101: //bitwise or
        alu_result = alu_in_1 | alu_in_2;
      4'b0110: //bitwise nand
        alu_result = ~ (alu_in_1 & alu_in_2);
      4'b0111: //bitwise nor
        alu_result = ~ (alu_in_1 | alu_in_2);
      4'b1000: //bitwise xor or BLT
            begin
                alu_result = alu_in_1 ^ alu_in_2;
                alu_bcond = alu_in_1 < alu_in_2;
            end
      4'b1001: //bitwise xnor
        alu_result = ~(alu_in_1 ^ alu_in_2);
      4'b1010: //logical left shift or BNE
            begin
                 alu_result = alu_in_1 << alu_in_2;
                 alu_bcond = alu_in_1 != alu_in_2;
            end
      4'b1011: //logical right shift or BGE
            begin
                 alu_result = alu_in_1 >> alu_in_2;
                 alu_bcond = alu_in_1 >= alu_in_2;
            end
      4'b1100: //arithmetic left shift
        alu_result = alu_in_1 << 1;
      4'b1101: //arithmetic right shift
         begin
            alu_result = {alu_in_1[31], alu_in_1[31:1]};
         end
      4'b1110: //two's complement
        alu_result = ~alu_in_1 + 1;
      4'b1111: //zero
        alu_result = 0;
   endcase
end

endmodule