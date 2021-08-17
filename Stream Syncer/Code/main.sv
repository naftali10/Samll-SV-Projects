`include "includes.sv"

// Module: Stream Syncer
// Duty: Receive a stream of bits,
// 		 and raise an output bit when a sequece is detected.
//		 Filter out the sequence and buffer and output the rest.

module Stream_syncer(
  input clk,
  input reset,
  input logic stream,
  output logic [7:0] data_out,
  output logic data_valid,
  output logic in_frame
  );
  // Shift register
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
  // Comparator
  assign is_pattren = SR==`PATTERN;
  // Counter
  logic [$clog2(`WINDOW_SZ)-1:0] counter;
  logic reset_cntr;
  always_ff @(posedge clk) begin
    if (reset | reset_cntr) counter <= 0;
    else begin
      counter <= counter + 1'b1;
    end
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
        if (is_pattren) next = ptrn1;
      end
      ptrn1: begin
        data_valid = 0;
        in_frame = 0;
        if (is_pattren) next = ptrn2;
      end
      ptrn2:begin
        data_valid = 0;
        in_frame = 0;
      end
      in_sync:begin
        data_valid = 0;
        in_frame = 0;
      end
    endcase
  end
endmodule
