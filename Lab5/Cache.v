`include "CLOG2.v"

module Cache #(parameter LINE_SIZE = 16,
                             parameter NUM_SETS = 16,
                             parameter NUM_WAYS = 1) (
    input reset,
    input clk,
    
    input is_input_valid, // EX_MEM_mem_read | EX_MEM_mem_write
    input [31:0] addr, // EX_MEM_alu_out
    input mem_read, //  EX_MEM_mem_read
    input mem_write, // EX_MEM_mem_write
    input [31:0] din, // EX_MEM_dmem_data
    
    output is_ready, // is_ready
    output is_output_valid, // is_output_valid
    output [31:0] dout,
    output is_hit  // is_hit
    ); // DataMemOut


  // Wire declarations
  wire [23:0] tag_bit;
  wire [3:0] index;
  wire [1:0] BO; // block offset
  
  // read from cache
  wire [127:0] data_read;
  wire [23:0] tag_read;
  wire valid_read;
  wire dirty_read;

 // memory
  wire is_mem_ready;
  wire [31:0] clog2;
  wire [127:0] dmem_dout;
  wire mem_output_valid;

  // Reg declarations
  reg [127:0] data_bank [0:15];
  reg [23:0] tag_bank [0:15];
  reg valid_table [0:15];
  reg dirty_table [0:15];
  reg [9:0] i;
  
  // state for cache controller 
  reg [1:0] current_state;
  reg [1:0] next_state;

 // write to cache
  reg [127:0] data_write;
  reg [23:0] tag_write;
  reg valid_write;
  reg dirty_write;
  reg data_we;
  reg tag_we;

 // memory
  reg [31:0] dmem_addr;
  reg [127:0] dmem_din;
  reg dmem_input_valid;
  reg dmem_read;
  reg dmem_write;
  
  reg [31:0] cache_dout;
  reg cache_valid;
  
  // compute the hit rate
  reg [31:0] miss_count;
  reg [31:0] total_access;
  // You might need registers to keep the status.
  
  // -------------------bit computation ----------------
  assign tag_bit = addr[31:8];
  assign index = addr[7:4];
  assign BO = addr[3:2];
  assign clog2 = `CLOG2(LINE_SIZE);
  
  // -------------------output --------------------
  assign is_ready = is_mem_ready;
  assign is_output_valid = cache_valid;
  assign dout = cache_dout;
  assign is_hit = (tag_bit == tag_read) & valid_read;
  
  //-------------- initialize cache(data bank and tag bank) -------------------
   always @(posedge clk) begin
    if(reset) begin
      for(i=0 ; i<16 ; i=i+1) begin
        data_bank[i]<=0;
        tag_bank[i]<=0;
        valid_table[i]<=0;
        dirty_table[i]<=0;
      end
    end
  end
  
  // --------------------------- Cache read & write ------------------------
// Read
  assign data_read = data_bank[index];
  assign tag_read = tag_bank[index];
  assign valid_read = valid_table[index];
  assign dirty_read = dirty_table[index];
  
// Write
  always @(posedge clk) begin
      if(data_we) begin
        data_bank[index] <= data_write;
      end
      if(tag_we) begin
        tag_bank[index] <= tag_write;
        valid_table[index] <= valid_write;
        dirty_table[index] <= dirty_write;
      end
  end
  
  // --------------------------- Cache Controller ------------------------
  always @(posedge clk) begin
    if(reset) begin
      current_state <= 2'b00; // idle state;
      next_state <= 2'b00;
    end
    else begin
      current_state <= next_state;
    end
  end
  
  always @(*) begin
    tag_write=0;
    valid_write=0;
    dirty_write=0;
    tag_we=0;
    data_we=0;
    dmem_input_valid=0; 
    dmem_read=0;
    dmem_write=0;
    cache_dout=0;
    cache_valid = 0;

    case(current_state)
      2'b00: begin
        if(is_input_valid)
          next_state=2'b01;
        else
            cache_valid = 1;
      end

      2'b01: begin
          // cache hit
            if(is_hit) begin
                   total_access = total_access +1;
                   cache_valid = 1;
                   next_state=2'b00;
                    // write to cache
                    if(mem_write) begin
                        // write to tag bank
                         tag_we=1; 
                         tag_write = tag_read; 
                         valid_write=1;
                         dirty_write=1;
                         // write to data bank
                         data_we=1;
                         data_write = data_read;
                         case(BO)
                              2'b00: data_write[31:0] = din;
                              2'b01: data_write[63:32] = din;
                              2'b10: data_write[95:64] = din;
                              2'b11: data_write[127:96] = din;
                         endcase
                    end
                    // read from cache
                    case(BO) 
                              2'b00: cache_dout=data_read[31:0];
                              2'b01: cache_dout=data_read[63:32];
                              2'b10: cache_dout=data_read[95:64];
                              2'b11: cache_dout=data_read[127:96];
                    endcase
            end
            // cache miss
            else begin
                  miss_count = miss_count + 1;
                  dmem_input_valid=1; 
                  // old block is clean
                  if(dirty_read==0)begin
                        dmem_read=1;
                        dmem_addr=addr;
                        next_state=2'b10;  // allocate state
                  end
                  // old block is dirty
                  else begin
                  //write128 bit block to memory
                       dmem_write=1;
                       dmem_addr={tag_read, addr[7:0]};
                       dmem_din=data_read;
                       next_state=2'b11; // write back state
                  end
            end
      end

      // allocate state (Read new block from Memory)
      2'b10: begin
            // write to tag bank
              tag_we=1;
              valid_write=1;
              tag_write = tag_bit;
              dirty_write = mem_write; 
          // remain in this state waiting for the Ready signal from memory
            if(is_mem_ready) begin 
             // write to data bank
              data_we=1;
              data_write=dmem_dout; // data from memory
              next_state=2'b01;
            end
      end

       // write-back state 
      2'b11: begin
          // remain in this state waiting for the Ready signal from memory
            if(is_mem_ready) begin 
                dmem_input_valid=1;
                dmem_read=1;
                dmem_addr=addr;
                next_state=2'b10; 
            end
      end
    endcase
  end

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),
    
    .is_input_valid(dmem_input_valid),
    .addr(dmem_addr >> clog2), // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(dmem_read),
    .mem_write(dmem_write),
    .din(dmem_din),
    
    // is output from the data memory valid?
    .is_output_valid(mem_output_valid),
    .dout(dmem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_mem_ready)
  );

   //------------- count the hit and miss --------------------
 //  always @(posedge clk) begin
  //   if(reset) begin
  //    total_access <= 0;
  //    miss_count <= 0;
  //  end
  //  else begin
   //  $display("total_access = %d, miss = %d", total_access , miss_count);
   // end
  //end
  
endmodule