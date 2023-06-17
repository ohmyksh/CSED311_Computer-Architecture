module MUX2to1 (a, b, s, Q);

   input [31:0] a;
   input [31:0] b;
   input s;
   output [31:0] Q;

   assign Q = s ? b : a;
   
endmodule

module MUX4to1 (a, b, c, d, s, Q);

   input [31:0] a;
   input [31:0] b;
   input [31:0] c;
   input [31:0] d;
   input [1:0] s;
   output [31:0] Q;

   assign Q = s[1] ? (s[0] ? d : c) : (s[0] ? b : a);
   
endmodule
