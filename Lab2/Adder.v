module Adder (input_1, input_2, sum);

  input [31:0] input_1;
  input [31:0] input_2;
  output [31:0] sum;

  assign sum = input_1 + input_2;

endmodule