`timescale 1ns / 1ps
`default_nettype none

module spi_master #(
    parameter TRANSFER_WIDTH = 8,
    parameter FIFO_DEPTH = 32,
    
    // SPI Mode Settings, from https://iopscience.iop.org/article/10.1088/1742-6596/1449/1/012027/pdf

    // Mode 0: CPOL = 0, CPHA=0. The SCK serial clock line idle is low, data is
    // sampled on the rising edge of the SCK clock, and data is switched on the
    // falling edge of the SCK clock;

    //Mode 1: CPOL = 0, CPHA=1. The SCK serial clock line idle is low, data is
    //sampled on the falling edge of the SCK clock, and data is switched on the
    //rising edge of the SCK clock;

    // Mode 2: CPOL = 1, CPHA = 0. The SCK serial clock line idle is high, data
    // is sampled on the falling edge of the SCK clock, and data is switched on
    // the rising edge of the SCK clock;

    // Mode 3: CPOL = 1, CPHA = 1. The SCK serial clock line idle is high, data
    // is sampled on the rising edge of the SCK clock, and data is switched on
    // the falling edge of the SCK clock.
    parameter CPOL = 0,
    parameter CPHA = 0
) (
    input var logic spi_clk,
    input var logic miso,

    output var logic cs,
    output var logic sck,
    output var logic mosi,

    axis_interface.Sink mosi_stream,
    axis_interface.Source miso_stream
);

    localparam KEEP_WIDTH = 1;

    var logic internal_reset = 0;
    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) mosi_frame_stream (
        .clk(spi_clk),
        .reset(internal_reset)
    );

    axis_async_fifo_wrapper #(
        .DEPTH(FIFO_DEPTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .DATA_WIDTH(TRANSFER_WIDTH)
    ) mosi_fifo (
        .sink(mosi_stream),
        .source(mosi_frame_stream)
    );


    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) miso_frame_stream (
        .clk(spi_clk),
        .reset(internal_reset)
    );

    axis_async_fifo_wrapper #(
        .DEPTH(FIFO_DEPTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .DATA_WIDTH(TRANSFER_WIDTH)
    ) miso_fifo (
        .sink(miso_frame_stream),
        .source(miso_stream)
    );

    typedef enum int {
        SPI_MASTER_MOSI_IDLE,
        SPI_MASTER_MOSI_START_TRANSFER,
        SPI_MASTER_MOSI_TRANSFERRING,
        SPI_MASTER_MOSI_END_TRANSFER
    } spi_master_transmitter_state_t;

    spi_master_transmitter_state_t transmitter_state = SPI_MASTER_MOSI_IDLE;

    // SPI transfer
    always @(posedge spi_clk) begin
        case (transmitter_state)
            // handle transfer bytes
        endcase
    end

    typedef enum int {
        SPI_MASTER_MISO_IDLE,
        SPI_MASTER_MISO_START_RECEIVE,
        SPI_MASTER_MISO_RECEIVING,
        SPI_MASTER_MISO_END_RECEIVE
    } spi_master_receiver_state_t;

    spi_master_receiver_state_t receiver_state = SPI_MASTER_MISO_IDLE;

    always @(posedge spi_clk) begin
        case (receiver_state)
            // handle data received from the slave
        endcase
    end

    always_comb begin
        // handle unused AXI Stream signals
        miso_frame_stream.tkeep = {KEEP_WIDTH{1'b1}};
        miso_frame_stream.tid = 0;
        miso_frame_stream.tuser = 0;
        miso_frame_stream.tdest = 0;
        miso_frame_stream.tlast = 1'b1;
    end

endmodule

`default_nettype wire
