`include "vending_machine_def.v"

	

module check_time_and_coin(i_input_coin,i_select_item, i_trigger_return, current_total, 
coin_value, clk,reset_n,wait_time,o_return_coin);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0]	i_select_item;
	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;
	
	input i_trigger_return;
    input [31:0] coin_value [`kNumCoins-1 : 0];
    input [`kTotalBits-1:0] current_total;

    //integer temp_return;
    reg [`kTotalBits-1:0] temp_return;
    integer i;
    
	// initiate values
	initial begin
		// TODO: initiate values
		wait_time <= `kWaitTime;
		o_return_coin = 0;
	end


	// update coin return time
	always @(i_input_coin, i_select_item) begin
		// TODO: update coin return time
		
		for(i=0; i < `kNumCoins; i = i + 1) begin
			if(i_input_coin[i] == 1) begin
				wait_time = `kWaitTime;
			end
		end
		// for item input
		for(i=0; i < `kNumItems; i = i + 1) begin
			if(i_select_item[i] == 1) begin
				// needed to check if it's available
				wait_time = `kWaitTime;
			end
		end
		
	end


	always @(*) begin
		// TODO: o_return_coin
		o_return_coin = 0;
		
		// temp_return is variable that is need to calculate 
		// current_total must not be updated because it is the state value
		// so temp_retun temporarily save the value of current_total
		temp_return = current_total;
		if (wait_time == 0) begin
		      if (temp_return >= coin_value[2]) begin
		              temp_return = temp_return - coin_value[2];
		              o_return_coin[2] = 1;
		      end
		      if (temp_return >= coin_value[1]) begin
		              temp_return = temp_return - coin_value[1];
		              o_return_coin[1] = 1;
		      end
		      if (temp_return >= coin_value[0]) begin
		              temp_return = temp_return - coin_value[0];
		              o_return_coin[0] = 1;
		      end
		end      
	end


	always @(posedge clk ) begin
		if (!reset_n) begin
		// TODO: reset all states.
		wait_time <= `kWaitTime;
		end
		else begin
		// TODO: update all states.
		if (wait_time) begin
		      wait_time <= wait_time -1;
		      //i_trigger_return == 1 
		      if(i_trigger_return)
		          wait_time <=0;
		end
		end
	end
endmodule 