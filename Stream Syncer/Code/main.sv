`include "includes.sv"

// Module: Stream Syncer
// Duty: Receive a stream of bits,
// 		 and raise an output bit when a sequece is detected.
//		 Filter out the sequence and buffer and output the rest.

module Stream_syncer(
  input clk,
  input reset,
  input logic stream,
  output logic [`OUT_SZ-1:0] data_out,
  output logic data_valid,
  output logic in_frame
  );
  // Pattern shift register
  logic [`SR_SZ-1:0] SR;
  int i;
  always_ff @(posedge clk) begin
    if (reset) SR <= 0;
    else begin
      for(i=`SR_SZ-1; i>0; i--)
        SR[i] <= SR[i-1];
      SR[0] <= stream;
    end
  end
  // Data shift register
  int j;
  always_ff @(posedge clk) begin
    if (reset) data_out <= 0;
    else begin
      for(j=`OUT_SZ-1; j>0; j--)
        data_out[j] <= data_out[j-1];
      data_out[0] <= stream;
    end
  end
  // Comparator
  logic is_pattern;
  assign is_pattern = SR==`PATTERN;
  // Counter
  logic [$clog2(`WINDOW_SZ)-1:0] counter;
  logic reset_cntr;
  always_ff @(posedge clk) begin
    if (reset | reset_cntr) counter <= 0;
    else if (counter>=`WINDOW_SZ-1) counter <= 0;
    	else counter <= counter + 1'b1;
  end
  // Controller
  enum logic [1:0] {no_sync = 2'b00,
              		ptrn1 = 2'b01,
                    ptrn2 = 2'b10,
                    in_sync = 2'b11} state, next;
  always_ff @(posedge clk) begin
    if (reset) state <= no_sync;
    else state <= next;
  end
  always_comb begin
    next = state; // Default value
    unique case (state)
      no_sync: begin
        data_valid = 0;
        in_frame = 0;
        reset_cntr = 0;
        if (is_pattern) begin
          next = ptrn1;
          reset_cntr = 1;
        end
      end
      ptrn1: begin
        data_valid = 0;
        in_frame = 0;
        reset_cntr = 0;
        if (~is_pattern && counter==`WINDOW_SZ-1) next = no_sync; // Pattern is missing
        else begin
          if (is_pattern && counter==`WINDOW_SZ-1) next = ptrn2;
          else if (is_pattern && counter!=`WINDOW_SZ-1) begin
            next = ptrn1;
            reset_cntr = 1;
          end
        end
      end
      ptrn2:begin
        data_valid = 0;
        in_frame = 0;
        reset_cntr = 0;
        if (~is_pattern && counter==`WINDOW_SZ-1) next = no_sync; // Pattern is missing
        else begin
          if (is_pattern && counter==`WINDOW_SZ-1) next = in_sync;
          else if (is_pattern && counter!=`WINDOW_SZ-1) begin
            next = ptrn1;
            reset_cntr = 1;
          end
        end
      end
      in_sync:begin
        data_valid = 0;
        in_frame = 1;
        reset_cntr = 0;
        if (~is_pattern && counter==`WINDOW_SZ-1) begin // Pattern is missing
          in_frame = 0;
          next = no_sync;
        end
        else begin
          if (~is_pattern && (counter+1)%`OUT_SZ==0 && counter<`WINDOW_SZ-`PATTERN_SZ) data_valid = 1; // Positive routine function
          else if (is_pattern && counter!=`WINDOW_SZ-1) begin // Early pattern
            in_frame = 0;
            next = ptrn1;
            reset_cntr = 1;
          end
        end
      end
    endcase
  end
endmodule
