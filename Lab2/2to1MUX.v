module MUX (a, b, s, Q);

   input [31:0] a;
   input [31:0] b;
   input s;
   output [31:0] Q;

   assign Q = s ? b : a;
   
endmodule