`include "alu_func.v"

module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag);
// Do not use delay in your implementation.

// You can declare any variables as needed.
/*
	YOUR VARIABLE DECLARATION...
*/

initial begin
	C = 0;
	OverflowFlag = 0;
end   	

// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')
always @(*) begin
        OverflowFlag = 0;
        // signed addition
        if (FuncCode == `FUNC_ADD) begin
			C = A + B;
			OverflowFlag = ~(A[data_width-1] ^ B[data_width-1]) && (A[data_width-1] ^ C[data_width-1]);
		end
		// signed subtraction
		else if (FuncCode == `FUNC_SUB) begin
			C = A - B;
		    OverflowFlag =(A[data_width-1] ^ B[data_width-1]) && (A[data_width-1] ^ C[data_width-1]);
		end
		//identity
		else if (FuncCode == `FUNC_ID) begin
			C = A;
		end
		// bitwise not
		else if (FuncCode == `FUNC_NOT) begin
			C = ~A;
		end
		// bitwise and
		else if (FuncCode == `FUNC_AND) begin
			C = A & B;
		end
		// bitwise or
		else if (FuncCode == `FUNC_OR) begin
			C = A | B;
		end
		// bitwise nand
		else if (FuncCode == `FUNC_NAND) begin
			C = ~(A & B);
		end
		// bitwise nor
		else if (FuncCode == `FUNC_NOR) begin
			C = ~(A | B);
		end
		// bitwise xor
		else if (FuncCode == `FUNC_XOR) begin
			C = A ^ B;
		end
		// bitwise xnor
		else if (FuncCode == `FUNC_XNOR) begin
			C = ~(A ^ B);
		end
		// logical left shift
		else if (FuncCode == `FUNC_LLS) begin
			C = A << 1;
		end
		// logical right shift
		else if (FuncCode == `FUNC_LRS) begin
			C = A >> 1;
		end
		// arithmetic left shift
		else if (FuncCode == `FUNC_ALS) begin
			C = A << 1;
		end
		// arithmetic right shift
		else if (FuncCode == `FUNC_ARS) begin
			C = {A[data_width-1], A[data_width-1:1]};
		end
		// two's complement
		else if (FuncCode == `FUNC_TCP) begin
			C = ~A + 1;
		end
		// zero
		else if (FuncCode == `FUNC_ZERO) begin
			C = 0;
		end
end
endmodule

