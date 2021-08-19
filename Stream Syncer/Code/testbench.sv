// Testbench

`define WINDOW_SZ 128
`define PATTERN_SZ 8
`define PATTERN `PATTERN_SZ'he8
`define OUT_SZ 8
`define DATA_PACK `OUT_SZ'habc
`define PACK_AMNT (`WINDOW_SZ-`PATTERN_SZ)/`OUT_SZ

module stimulus;
  logic clk;
  logic reset;
  logic stream;
  logic [`OUT_SZ-1:0] data_out;
  logic data_valid, in_frame;
  Stream_syncer stream_syncer (clk,
                               reset,
                               stream,
                               data_out,
                               data_valid,
                               in_frame);
  bit pass;
  int i, first_data_i;
  
  logic [4*`WINDOW_SZ-1:0] CHECK1_STREAM;
  assign CHECK1_STREAM = { << {{
    4{`PATTERN,{`PACK_AMNT{`DATA_PACK}}}	// Four proper frames
  	}}};
  logic [4*`WINDOW_SZ-1:0] CHECK2_STREAM;
  assign CHECK2_STREAM = { << {{
    {`PATTERN,{`PACK_AMNT{`DATA_PACK}}},	// One proper frame
    {`PATTERN,{(`PACK_AMNT-1){`DATA_PACK}}},// One short frame
    {2{`PATTERN,{`PACK_AMNT{`DATA_PACK}}}}	// Two proper frames
  	}}};
  logic [6*`WINDOW_SZ-1:0] CHECK3_STREAM;
  assign CHECK3_STREAM = { << {{
    {`PATTERN,{(`PACK_AMNT+1){`DATA_PACK}}},// One long frame
    {`PATTERN,{(`PACK_AMNT-1){`DATA_PACK}}},// One short frame
    {4{`PATTERN,{`PACK_AMNT{`DATA_PACK}}}}	// Four proper frames
  	}}};
  
  always #1 clk = ~clk;

  initial begin
    $display ("--------------- TEST STRAT --------------");
    $dumpfile("dump.vcd");
    $dumpvars(1);
    $dumpvars(1,stream_syncer);
    $display ("Resetting...");
    clk = 0;
    reset = 1;
    stream = 0;
    #2
    $display ("----------------- CHECK 1 --------------");
    $display ("Feeding proper stream of 4 frames...");
    reset = 0;
    #1
    pass = 1;
    first_data_i = 2*`WINDOW_SZ+`PATTERN_SZ;
    for (i=0; i<4*`WINDOW_SZ; i++) begin
      #2
      stream = CHECK1_STREAM[i];
      if (first_data_i<i && (i-first_data_i)%`OUT_SZ==0 &&
          i%`WINDOW_SZ!=`PATTERN_SZ) begin
        if (~data_valid) pass = 0;
        else if (data_out != `DATA_PACK) pass = 0;
      end
    end
    $display ("Verifying output signals...");
    if (pass) $display ("Check passed!");
    else $display ("Check failed.");
    $display ("----------------- CHECK 2 --------------");
    $display ("Resetting...");
    reset = 1;
    #2
    reset = 0;
    $display ("Streaming 2 proper frames + one short + one proper...");
    pass = 1;
    for (i=0; i<4*`WINDOW_SZ; i++) begin
      #2
      stream = CHECK2_STREAM[i];
      if (data_valid == 1 || in_frame == 1) pass = 0;
    end
    $display ("Verifying output signals...");
    if (pass) $display ("Check passed!");
    else $display ("Check failed.");
    $display ("----------------- CHECK 3 --------------");
    $display ("Resetting...");
    reset = 1;
    #2
    reset = 0;
    $display ("Streaming 1 long frame + 1 short + 4 proper...");
    pass = 1;
    first_data_i = 4*`WINDOW_SZ+`PATTERN_SZ;
    for (i=0; i<6*`WINDOW_SZ; i++) begin
      #2
      stream = CHECK3_STREAM[i];
      if (first_data_i<i && (i-first_data_i)%`OUT_SZ==0 &&
          i%`WINDOW_SZ!=`PATTERN_SZ) begin
        if (~data_valid) pass = 0;
        else if (data_out != `DATA_PACK) pass = 0;
      end
    end
    $display ("Verifying output signals...");
    if (pass) $display ("Check passed!");
    else $display ("Check failed.");
    $display ("------------- TEST COMPLETE --------------");
  end
endmodule
