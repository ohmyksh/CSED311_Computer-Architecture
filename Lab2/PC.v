module PC(
    input reset, //Use reset to initialize PC. Initial value must be 0
    input clk,
    input [31:0] next_pc,  // input
    output reg [31:0] current_pc   // output
    );
    
    always@(posedge clk)begin
        if(reset) current_pc <= 32'b0;
        else current_pc <= next_pc;
    end

endmodule
