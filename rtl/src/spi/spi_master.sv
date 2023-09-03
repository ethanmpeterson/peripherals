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

    parameter CPOL = 0, // sck idle state
    parameter CPHA = 0 // sampling edge (0 for rising, 1 for falling)
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

    axis_fifo_status_interface mosi_fifo_sink_status ();
    axis_fifo_status_interface mosi_fifo_source_status ();
    axis_async_fifo_wrapper #(
        .DEPTH(FIFO_DEPTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .DATA_WIDTH(TRANSFER_WIDTH)
    ) mosi_fifo (
        .sink(mosi_stream),
        .source(mosi_frame_stream),

        .sink_status(mosi_fifo_sink_status),
        .source_status(mosi_fifo_source_status)
    );


    axis_interface #(
        .DATA_WIDTH(TRANSFER_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) miso_frame_stream (
        .clk(spi_clk),
        .reset(internal_reset)
    );

    axis_fifo_status_interface miso_fifo_sink_status ();
    axis_fifo_status_interface miso_fifo_source_status ();
    axis_async_fifo_wrapper #(
        .DEPTH(FIFO_DEPTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .DATA_WIDTH(TRANSFER_WIDTH)
    ) miso_fifo (
        .sink(miso_frame_stream),
        .source(miso_stream),

        .sink_status(miso_fifo_sink_status),
        .source_status(miso_fifo_source_status)
    );

    typedef enum int {
        SPI_MASTER_TRANSMITTER_IDLE,
        SPI_MASTER_TRANSMITTER_START_TRANSFER,
        SPI_MASTER_TRANSMITTER_TRANSFERRING,
        SPI_MASTER_TRANSMITTER_END_TRANSFER
    } spi_master_transmitter_state_t;

    spi_master_transmitter_state_t transmitter_state = SPI_MASTER_TRANSMITTER_IDLE;
    var logic[$clog2(TRANSFER_WIDTH)-1:0] transfer_bit_idx;
    var logic[TRANSFER_WIDTH-1:0] tx_data;

    // need to look at both rising and falling edge to sample correctly.
    always @(spi_clk) begin
        case (transmitter_state)
            SPI_MASTER_TRANSMITTER_IDLE: begin
                // Tell the queue we are ready to tx a new frame.

                transfer_bit_idx <= TRANSFER_WIDTH - 1;
                cs <= 1'b1;

                // collect the data from the queue on the rising edge
                if (spi_clk == 1'b1) begin
                    mosi_frame_stream.tready <= 1'b1;
                    // Do we have a new SPI frame available in the queue? If so,
                    // transfer it out.
                    if (mosi_frame_stream.tready && mosi_frame_stream.tvalid) begin
                        tx_data <= mosi_frame_stream.tdata;
                        
                        // place the first bit on the MOSI line
                        mosi <= mosi_frame_stream.tdata[transfer_bit_idx];
                        transfer_bit_idx <= transfer_bit_idx;
                        transmitter_state <= SPI_MASTER_TRANSMITTER_START_TRANSFER;
                    end
                end
            end

            SPI_MASTER_TRANSMITTER_START_TRANSFER: begin
                // Note that we always arrive in this state on the falling edge of the spi_clk
                cs <= 1'b0;

                // if we are on the edge specified in the peripheral parameters.
                // Proceed onward to the transferring state.
                if (spi_clk == !CPHA) begin
                    // place the next bit on MOSI so it is ready for the next sampling
                    mosi <= tx_data[transfer_bit_idx];
                    transfer_bit_idx <= transfer_bit_idx - 1;

                    transmitter_state <= SPI_MASTER_TRANSMITTER_TRANSFERRING;
                end
            end

            SPI_MASTER_TRANSMITTER_TRANSFERRING: begin
                // Finish the remainder of the transfer
                if (spi_clk == !CPHA) begin
                    if (transfer_bit_idx > 0) begin
                        // TODO: can delete the tracking index entirely with bit shifting
                        mosi <= tx_data[transfer_bit_idx];
                        transfer_bit_idx <= transfer_bit_idx - 1;
                    end else begin // transfer_bit_idx == 0
                        mosi <= tx_data[0];
                        transfer_bit_idx <= TRANSFER_WIDTH;

                        transmitter_state <= SPI_MASTER_TRANSMITTER_END_TRANSFER;
                    end
                end
            end

            SPI_MASTER_TRANSMITTER_END_TRANSFER: begin
                transmitter_state <= SPI_MASTER_TRANSMITTER_IDLE;
            end
        endcase
    end

    // HANDLE the state of our SCK pin relative to the spi_clk We want this pin
    // to idle in the correct state when no transfer is taking place. This
    // combinational approach may cause glitches, I will do further research to
    // determine if that is acceptable.

    always_comb begin
        if (transmitter_state == SPI_MASTER_TRANSMITTER_START_TRANSFER ||
            transmitter_state == SPI_MASTER_TRANSMITTER_TRANSFERRING ||
            transmitter_state == SPI_MASTER_TRANSMITTER_END_TRANSFER) begin
            // map sck to the spi clk directly in these states
            sck = spi_clk;
        end else begin
            // place sck in the idle state
            sck = CPOL;
        end
    end


    typedef enum int {
        SPI_MASTER_RECEIVER_IDLE,
        SPI_MASTER_RECEIVER_RECEIVING,
        SPI_MASTER_RECEIVER_END_RECEIVE
    } spi_master_receiver_state_t;

    spi_master_receiver_state_t receiver_state = SPI_MASTER_RECEIVER_IDLE;

    var logic[$clog2(TRANSFER_WIDTH)-1:0] receive_bit_idx;
    always @(posedge spi_clk) begin
        case (receiver_state)
            SPI_MASTER_RECEIVER_IDLE: begin
                receive_bit_idx <= TRANSFER_WIDTH - 1;
                if (!cs) begin
                    // cs is always asserted on the faling edge
                    receiver_state <= SPI_MASTER_RECEIVER_RECEIVING;
                end
            end

            SPI_MASTER_RECEIVER_RECEIVING: begin
                if (spi_clk == !CPHA) begin
                    // if we are on a sampling edge, populate the rx register accordingly
                    if (receive_bit_idx > 0) begin
                        miso_frame_stream.tdata[receive_bit_idx] <= miso;
                        receive_bit_idx <= receive_bit_idx - 1;
                    end else begin // receive_bit_idx == 0
                        miso_frame_stream.tdata[0] <= miso;
                        miso_frame_stream.tvalid <= 1'b1;

                        receiver_state <= SPI_MASTER_RECEIVER_END_RECEIVE;
                    end
                end
            end

            SPI_MASTER_RECEIVER_END_RECEIVE: begin
                if (spi_clk) begin
                    if (miso_frame_stream.tready && miso_frame_stream.tvalid) begin
                        miso_frame_stream.tvalid <= 1'b0;

                        receiver_state <= SPI_MASTER_RECEIVER_IDLE;
                    end
                end
            end
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
