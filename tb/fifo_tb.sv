`timescale 1ns/1ps

module fifo_tb;

  localparam int DATA_WIDTH = 8;
  localparam int DEPTH      = 16;

  logic clk, rst_n;
  logic wr_en, rd_en;
  logic [DATA_WIDTH-1:0] wr_data;

  logic [DATA_WIDTH-1:0] rd_data;
  logic full, empty;
  logic [$clog2(DEPTH+1)-1:0] count;

  fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .wr_data(wr_data),
    .rd_en(rd_en), .rd_data(rd_data),
    .full(full), .empty(empty), .count(count)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  logic [DATA_WIDTH-1:0] sb_mem [0:DEPTH-1];
  int sb_wptr, sb_rptr, sb_count;

  logic [DATA_WIDTH-1:0] exp, sampled;

  task automatic reset_dut;
    begin
      wr_en = 0; rd_en = 0; wr_data = '0;
      sb_wptr = 0; sb_rptr = 0; sb_count = 0;

      rst_n = 0;
      repeat (2) @(posedge clk);
      rst_n = 1;
      @(posedge clk);
    end
  endtask

  task automatic check_flags;
    begin
      if ((sb_count == 0) && (empty !== 1'b1)) begin
        $display("FAIL empty: sb_count=%0d time=%0t", sb_count, $time);
        $finish;
      end
      if ((sb_count == DEPTH) && (full !== 1'b1)) begin
        $display("FAIL full: sb_count=%0d time=%0t", sb_count, $time);
        $finish;
      end
      if ((sb_count > 0) && (empty === 1'b1)) begin
        $display("FAIL empty asserted: sb_count=%0d time=%0t", sb_count, $time);
        $finish;
      end
      if ((sb_count < DEPTH) && (full === 1'b1)) begin
        $display("FAIL full asserted: sb_count=%0d time=%0t", sb_count, $time);
        $finish;
f
      end
      if (count !== sb_count[$clog2(DEPTH+1)-1:0]) begin
        $display("FAIL count: dut=%0d sb=%0d time=%0t", count, sb_count, $time);
        $finish;
      end
    end
  endtask

  task automatic do_push(input logic [DATA_WIDTH-1:0] data);
    logic full_pre;
    begin
      @(negedge clk);
      wr_data = data;
      wr_en   = 1;
      rd_en   = 0;

      full_pre = full;

      @(posedge clk);
      if (!full_pre) begin
        sb_mem[sb_wptr] = data;
        sb_wptr  = (sb_wptr + 1) % DEPTH;
        sb_count = sb_count + 1;
      end

      @(negedge clk);
      wr_en = 0;
    end
  endtask

  task automatic do_pop;
    logic empty_pre;
    begin
      @(negedge clk);
      wr_en = 0;
      rd_en = 1;

      empty_pre = empty;

      #1 sampled = rd_data;

      @(posedge clk);
      if (!empty_pre) begin
        exp = sb_mem[sb_rptr];
        sb_rptr  = (sb_rptr + 1) % DEPTH;
        sb_count = sb_count - 1;

        if (sampled !== exp) begin
          $display("FAIL data: exp=%0h got=%0h time=%0t", exp, sampled, $time);
          $finish;
        end
      end

      @(negedge clk);
      rd_en = 0;
    end
  endtask

  initial begin
    $dumpfile("fifo.vcd");
    $dumpvars(0, fifo_tb);

    reset_dut();

    do_pop(); check_flags();

    for (int i = 0; i < DEPTH; i++) begin
      do_push(i[7:0]);
      check_flags();
    end

    do_push(8'hAA);
    check_flags();

    for (int j = 0; j < DEPTH; j++) begin
      do_pop();
      check_flags();
    end

    do_pop(); check_flags();

    for (int k = 0; k < 20; k++) begin
      if (!full)  do_push(8'h80 + k[7:0]);
      if (!empty) do_pop();
      check_flags();
    end

    while (sb_count > 0) begin
      do_pop();
      check_flags();
    end

    $display("ALL TESTS PASSED");
    $finish;
  end

endmodule
