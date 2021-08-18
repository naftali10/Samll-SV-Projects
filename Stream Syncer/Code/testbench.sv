// Testbench

`define WINDOW_SZ 16
`define PATTERN_SZ 8
`define PATTERN `PATTERN_SZ'he8
`define OUT_SZ 8

module stimulus;
  logic clk;
  logic reset;
  logic stream;
  logic [7:0] data_out;
  logic data_valid, in_frame;
  Stream_syncer stream_syncer (clk,
                               reset,
                               stream,
                               data_out,
                               data_valid,
                               in_frame);
                                       
  int i;
  logic [4*`WINDOW_SZ-1:0] FULL_PATTERN;
  assign FULL_PATTERN = { << {{4{`PATTERN,{`WINDOW_SZ-`PATTERN_SZ{1'b0}}}}}};
  
  always #1 clk = ~clk;

  initial begin
    $display ("----------------- TEST STRAT --------------");
    $dumpfile("dump.vcd");
    $dumpvars(1);
    $dumpvars(1,stream_syncer);
    clk = 0;
    reset = 1;
    stream = 0;
    #2
    reset = 0;
    #1
    for (i=0; i<4*`WINDOW_SZ; i++) begin
      #2
      stream = FULL_PATTERN[i];
    end
  end
endmodule
