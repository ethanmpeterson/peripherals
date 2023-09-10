`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module spi_master_tb;
    // These params will be overriden by the test bench
    parameter int CPOL = 0;
    parameter int CPHA = 0;

    localparam TRANSFER_WIDTH = 8;    
    localparam FIFO_DEPTH = 2;


    localparam KEEP_WIDTH = 1;

    // Hookup test clk and local spi_clk at a lower frequency

    var logic clk = 0;    

    var logic reset = 0;

    always begin
        #10
        clk <= !clk;
    end

    spi_interface #(
        .CS_COUNT(1)
    ) spi_bus ();


    assign spi_bus.miso = spi_bus.mosi; // loop back test

    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) mosi_stream (
        .clk(clk),
        .reset(reset)
    );

    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) miso_stream (
        .clk(clk),
        .reset(reset)
    );

    spi_master #(
        .TRANSFER_WIDTH(TRANSFER_WIDTH),
        .CLKS_PER_HALF_BIT(50),
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) DUT (
        .spi_bus(spi_bus),
        
        .miso_en(0),

        .mosi_stream(mosi_stream.Sink),
        .miso_stream(miso_stream.Source)
    );


    typedef enum int {
        WAIT,
        WRITE_STREAM,
        WRITE_COMPLETE
    } spi_master_tb_state_t;

    spi_master_tb_state_t state = WAIT;

    // Send packet to the FIFO for testing
    always @(posedge clk) begin
        // Write tx_data to the MOSI fifo
        case (state)
            WAIT: begin
                mosi_stream.tdata <= 8'b1010_1010;
                if (mosi_stream.tready) begin
                    mosi_stream.tvalid <= 1'b1;

                    state <= WRITE_STREAM;
                end
            end

            WRITE_STREAM: begin
                if (mosi_stream.tvalid && mosi_stream.tready) begin
                    mosi_stream.tvalid <= 0;

                    state <= WRITE_COMPLETE;
                end
            end
        endcase
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            mosi_stream.tdata = 0;
            mosi_stream.tlast = 1'b1;
            mosi_stream.tkeep = 1'b1;
            mosi_stream.tid = 0;
            mosi_stream.tdest = 0;
            mosi_stream.tuser = 0;
            mosi_stream.tvalid = 0;

            // ready up to conusme MISO data
            miso_stream.tready = 1'b1;
        end

        `TEST_CASE("spi_loopback_test") begin
            automatic int bytes_consumed = 0;
            while (bytes_consumed < 40 * 50) begin
                @(posedge clk) begin
                    bytes_consumed = bytes_consumed + 1;

                    if (miso_stream.tready && miso_stream.tvalid) begin
                        `CHECK_EQUAL(miso_stream.tdata, 8'b1010_1010);

                        miso_stream.tready <= 1'b0;
                    end
                end
            end
        end
    end

    `WATCHDOG(0.1ms);

endmodule

`default_nettype wire
