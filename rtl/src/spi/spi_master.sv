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
    localparam SPI_CLOCK_IDLE_STATE = CPOL;
    localparam SPI_CLOCK_SAMPLING_EDGE = CPHA;
    localparam SPI_CLOCK_DATA_UPDATE_EDGE = !CPHA;

    typedef enum int {
        SPI_MASTER_TRANSMITTER_INIT,
        SPI_MASTER_TRANSMITTER_START_TRANSFER,
        SPI_MASTER_TRANSMITTER_TRANSFERRING
    } spi_master_transmitter_state_t;

    spi_master_transmitter_state_t transmitter_state = SPI_MASTER_TRANSMITTER_INIT;

    var logic[TRANSFER_WIDTH-1:0] mosi_data;
    var logic[TRANSFER_WIDTH-1:0] miso_data;
    var logic[$clog2(TRANSFER_WIDTH)-1:0] transfer_bit_idx;
    var logic[$clog2(CLKS_PER_HALF_BIT):0] transfer_clock_cycle_count;
    always_ff @(posedge mosi_stream.clk) begin
        case (transmitter_state)
            SPI_MASTER_TRANSMITTER_INIT: begin
                spi_bus.mosi <= 1'b0;
                spi_bus.cs <= 1'b1;
                spi_bus.sck <= SPI_CLOCK_IDLE_STATE;

                transfer_clock_cycle_count <= 0;

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

                        // deliver first clock pulse to keep things aligned.
                        spi_bus.sck <= !spi_bus.sck;

                        transmitter_state <= SPI_MASTER_TRANSMITTER_TRANSFERRING;
                    end else begin
                        transfer_clock_cycle_count <= transfer_clock_cycle_count + 1;
                    end
                end
            end

            SPI_MASTER_TRANSMITTER_TRANSFERRING: begin
                // generate the SPI clock
                if (transfer_clock_cycle_count == CLKS_PER_HALF_BIT - 1) begin                    
                    // reset the counter
                    transfer_clock_cycle_count <= 0;

                    spi_bus.sck <= !spi_bus.sck;

                    // update the data using the sck signal
                    if (!spi_bus.sck == SPI_CLOCK_DATA_UPDATE_EDGE) begin
                        $display("made it here");
                        spi_bus.mosi <= mosi_data[transfer_bit_idx];
                        transfer_bit_idx <= transfer_bit_idx - 1;
                    end
                end else begin
                    transfer_clock_cycle_count <= transfer_clock_cycle_count + 1;
                end

                // escape this state when we run out of bits to transfer
                if (transfer_bit_idx == 0) begin
                    transmitter_state <= SPI_MASTER_TRANSMITTER_START_TRANSFER;
                end
            end
        endcase

        if (mosi_stream.reset) begin
            // return to IDLE state here and re init
            transmitter_state <= SPI_MASTER_TRANSMITTER_INIT;
        end
    end


    // Do MISO state machine here
    // TODO but similar to mosi implementation above

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
