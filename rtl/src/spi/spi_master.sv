`timescale 1ns / 1ps
`default_nettype none

module spi_master #(
    parameter TRANSFER_WIDTH = 8,

    // default for a 100 MHz clock
    // produces 1 MHz SPI
    parameter CLKS_PER_HALF_BIT = 50,
    
    parameter CPOL = 0, // sck idle state
    parameter CPHA = 0 // sampling edge (0 for rising, 1 for falling)
) (
    input var logic miso_en,
    spi_interface.Master spi_bus,

    // it is assumed that these two streams share the same clock
    axis_interface.Sink mosi_stream,
    axis_interface.Source miso_stream
);
    localparam SPI_MODE = (CPOL << 1) | CPHA;

    localparam SPI_CLOCK_IDLE_STATE = CPOL;
    localparam SPI_CLOCK_SAMPLING_EDGE = (SPI_MODE == 0 || SPI_MODE == 1);
    localparam SPI_CLOCK_DATA_UPDATE_EDGE = (SPI_MODE == 1 || SPI_MODE == 2);

    typedef enum int {
        SPI_MASTER_TRANSMITTER_INIT,
        SPI_MASTER_TRANSMITTER_START_TRANSFER,
        SPI_MASTER_TRANSMITTER_TRANSFERRING,
        SPI_MASTER_TRANSMITTER_END_TRANSFER
    } spi_master_transmitter_state_t;

    spi_master_transmitter_state_t transmitter_state = SPI_MASTER_TRANSMITTER_INIT;

    var logic[TRANSFER_WIDTH-1:0] mosi_data;
    var logic[$clog2(TRANSFER_WIDTH)-1:0] transfer_bit_idx;
    var logic[$clog2(CLKS_PER_HALF_BIT):0] transfer_clock_cycle_count;

    // single cycle pulse that marks when we hit a sampling edge of the SPI clock
    var logic sampling_edge;

    // depending on the SPI mode the update edge can come before the sampling
    // edge when transferring the first bit. This signal is asserted to mark
    // that the first bit saw a sampling edge allowing us to move onto updating
    // mosi as normal for the rest of the transfer.
    var logic got_first_sample;
    
    always_ff @(posedge mosi_stream.clk) begin
        case (transmitter_state)
            SPI_MASTER_TRANSMITTER_INIT: begin
                spi_bus.mosi <= 1'b0;
                spi_bus.cs <= 1'b1;
                spi_bus.sck <= SPI_CLOCK_IDLE_STATE;

                transfer_clock_cycle_count <= 0;

                got_first_sample <= 1'b0;

                transmitter_state <= SPI_MASTER_TRANSMITTER_START_TRANSFER;
            end

            SPI_MASTER_TRANSMITTER_START_TRANSFER: begin
                // Initialize SPI outputs
                spi_bus.sck <= SPI_CLOCK_IDLE_STATE;

                transfer_bit_idx <= TRANSFER_WIDTH - 2;
                mosi_stream.tready <= 1'b1;
                if (mosi_stream.tvalid && mosi_stream.tready) begin
                    mosi_stream.tready <= 1'b0;

                    // latch the mosi data from the stream
                    mosi_data <= mosi_stream.tdata;
                    spi_bus.mosi <= mosi_stream.tdata[TRANSFER_WIDTH - 1];

                    // in this design we are controlling cs inside the module,
                    // could also look at designs where the controller does this
                    // instead
                    spi_bus.cs <= 1'b0;
                end
                
                // start transferring after cs has been low for at least a half
                // cycle
                if (!spi_bus.cs) begin
                    if (transfer_clock_cycle_count == CLKS_PER_HALF_BIT - 1) begin
                        transfer_clock_cycle_count <= 0;

                        transmitter_state <= SPI_MASTER_TRANSMITTER_TRANSFERRING;
                    end else begin
                        transfer_clock_cycle_count <= transfer_clock_cycle_count + 1;
                    end
                end
            end

            // This is working on

            // MODE3
            // MODE1
            SPI_MASTER_TRANSMITTER_TRANSFERRING: begin
                // generate the SPI clock
                if (transfer_clock_cycle_count == CLKS_PER_HALF_BIT - 1) begin
                    // reset the counter
                    transfer_clock_cycle_count <= 0;

                    spi_bus.sck <= !spi_bus.sck;
                    // assert pulse signal when we have a sampling edge. This
                    // tells the receiver state machine when to sample the
                    // contents of MISO
                    if (!spi_bus.sck == SPI_CLOCK_SAMPLING_EDGE) begin
                        sampling_edge <= 1'b1;
                        got_first_sample <= 1'b1;
                    end else begin
                        sampling_edge <= 1'b0;
                    end

                    // update the data using the sck signal
                    if (!spi_bus.sck == SPI_CLOCK_DATA_UPDATE_EDGE && got_first_sample) begin
                        if (transfer_bit_idx == 0) begin
                            spi_bus.mosi <= mosi_data[transfer_bit_idx];

                            transmitter_state <= SPI_MASTER_TRANSMITTER_END_TRANSFER;
                        end else begin
                            spi_bus.mosi <= mosi_data[transfer_bit_idx];
                            transfer_bit_idx <= transfer_bit_idx - 1;
                        end
                    end
                end else begin
                    transfer_clock_cycle_count <= transfer_clock_cycle_count + 1;
                end
            end

            SPI_MASTER_TRANSMITTER_END_TRANSFER: begin
                // Handle transferring the last bit
                if (transfer_clock_cycle_count == CLKS_PER_HALF_BIT - 1) begin
                    transfer_clock_cycle_count <= 0;

                    spi_bus.sck <= !spi_bus.sck;
                    if (!spi_bus.sck == SPI_CLOCK_DATA_UPDATE_EDGE) begin
                        spi_bus.cs <= 1'b1; // end this transfer

                        // prevent glitch by placing clock in the idle state
                        // rather than adding a false edge
                        spi_bus.sck <= SPI_CLOCK_IDLE_STATE;

                        transmitter_state <= SPI_MASTER_TRANSMITTER_START_TRANSFER;
                    end
                end else begin
                    transfer_clock_cycle_count <= transfer_clock_cycle_count + 1;
                end
            end
        endcase

        if (mosi_stream.reset) begin
            // return to IDLE state here and re init
            transmitter_state <= SPI_MASTER_TRANSMITTER_INIT;
        end
    end


    // We will monitor for sampling edges of the clock and grab the value on
    // miso.
    typedef enum int {
        SPI_MASTER_RECEIVER_START_RECEIVE,
        SPI_MASTER_RECEIVER_RECEIVING,
        SPI_MASTER_RECEIVER_END_RECEIVE
    } spi_master_receiver_state_t;

    spi_master_receiver_state_t receiver_state = SPI_MASTER_RECEIVER_START_RECEIVE;

    var logic[TRANSFER_WIDTH-1:0] miso_data;
    var logic[$clog2(TRANSFER_WIDTH)-1:0] receive_bit_idx;
    always_ff @(posedge miso_stream.clk) begin
        case (receiver_state)
            SPI_MASTER_RECEIVER_START_RECEIVE: begin
                receive_bit_idx <= TRANSFER_WIDTH - 1;
                if (!spi_bus.cs) begin
                    receiver_state <= SPI_MASTER_RECEIVER_RECEIVING;
                end
            end

            SPI_MASTER_RECEIVER_RECEIVING: begin
                // use sampling edge strobe signal to read in MISO values
                if (sampling_edge) begin
                    miso_data[receive_bit_idx] <= spi_bus.miso;

                    receive_bit_idx <= receive_bit_idx - 1;
                end

                // when the transaction ends, stop receiving
                if (spi_bus.cs) begin
                    receiver_state <= SPI_MASTER_RECEIVER_START_RECEIVE;
                end
            end
        endcase
    end

    // handle unused AXI stream signals in combinational logic here
    always_comb begin
        // TODO: get these matched to actual signal width. Want to clean this up
        // in the broader project too
        miso_stream.tkeep <= 1'b1;
        miso_stream.tlast <= 1'b1;
        miso_stream.tid <= 0;
        miso_stream.tdest <= 0;
        miso_stream.tuser <= 0;
    end

endmodule

`default_nettype wire
