module fifo_regread #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
) (
    input  logic                       clk,
    input  logic                       rst_n,

    input  logic                       wr_en,
    input  logic [DATA_WIDTH-1:0]      wr_data,

    input  logic                       rd_en,
    output logic [DATA_WIDTH-1:0]      rd_data,

    output logic                       full,
    output logic                       empty,
    output logic [$clog2(DEPTH+1)-1:0] count
);

    initial begin
        if (DEPTH < 2) $fatal(1, "DEPTH must be >= 2");
    end

    localparam int ADDR_W = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_W-1:0]     wptr, rptr;

    logic do_write, do_read;
    assign do_write = wr_en && !full;
    assign do_read  = rd_en && !empty;

    always_comb begin
        empty = (count == 0);
        full  = (count == DEPTH);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr    <= '0;
            rptr    <= '0;
            count   <= '0;
            rd_data <= '0;
        end else begin
            // Registered read: capture data on accepted read
            if (do_read) begin
                rd_data <= mem[rptr];
            end

            if (do_write) begin
                mem[wptr] <= wr_data;
                wptr <= (wptr == DEPTH-1) ? '0 : (wptr + 1'b1);
            end

            if (do_read) begin
                rptr <= (rptr == DEPTH-1) ? '0 : (rptr + 1'b1);
            end

            unique case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

`ifndef SYNTHESIS
    always_ff @(posedge clk) begin
        if (rst_n) begin
            assert (count <= DEPTH)
                else $fatal(1, "count out of range: %0d (DEPTH=%0d)", count, DEPTH);

            assert (empty == (count == 0))
                else $fatal(1, "empty mismatch: empty=%0b count=%0d", empty, count);

            assert (full == (count == DEPTH))
                else $fatal(1, "full mismatch: full=%0b count=%0d", full, count);
        end
    end

    logic do_write_q, do_read_q;
    logic [$bits(count)-1:0] count_q;

    always_ff @(posedge clk) begin
        do_write_q <= do_write;
        do_read_q  <= do_read;
        count_q    <= count;

        if (rst_n) begin
            case ({do_write_q, do_read_q})
                2'b10: assert (count == count_q + 1'b1)
                         else $fatal(1, "count didn't increment: %0d -> %0d", count_q, count);
                2'b01: assert (count == count_q - 1'b1)
                         else $fatal(1, "count didn't decrement: %0d -> %0d", count_q, count);
                2'b11: assert (count == count_q)
                         else $fatal(1, "count changed on rd+wr: %0d -> %0d", count_q, count);
                2'b00: assert (count == count_q)
                         else $fatal(1, "count changed with no op: %0d -> %0d", count_q, count);
            endcase
        end
    end
`endif

endmodule
