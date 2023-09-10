`timescale 1ns / 1ps
`default_nettype none

module spi_master #(
    parameter TRANSFER_WIDTH = 8,

    // default for a 100 MHz clock
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
        SPI_MASTER_TRANSMITTER_IDLE,
        SPI_MASTER_TRANSMITTER_TRANSFERRING
    } spi_master_transmitter_state_t;

    spi_master_transmitter_state_t transmitter_state = SPI_MASTER_TRANSMITTER_INIT;

    var logic[TRANSFER_WIDTH-1:0] mosi_data;
    var logic[TRANSFER_WIDTH-1:0] miso_data;
    var logic[$clog2(TRANSFER_WIDTH)-1:0] transfer_bit_idx;
    var logic[$clog2(CLKS_PER_HALF_BIT):0] transfer_clock_cycle_count;
    always_ff @(posedge mosi_stream.clk) begin
        case (transmitter_state)
            SPI_MASTER_TRANSMITTER_IDLE: begin
                // Initialize SPI outputs
                spi_bus.sck <= SPI_CLOCK_IDLE_STATE;
                spi_bus.mosi <= 1'b0;
                spi_bus.cs <= 1'b1;

                transfer_bit_idx <= TRANSFER_WIDTH - 1;
                transfer_clock_cycle_count <= $clog2(CLKS_PER_HALF_BIT){1'b0};

                mosi_data <= TRANSFER_WIDTH{1'b0};
                mosi_stream.tready <= 1'b1;
                if (mosi_stream.tvalid && mosi_stream.tready) begin
                    mosi_stream.tready <= 1'b0;

                    // latch the mosi data from the stream
                    mosi_data <= mosi_stream.tdata;

                    // in this design we are controlling cs inside the module,
                    // could also look at designs where the controller does this
                    // instead
                    spi_bus.cs <= 1'b0;

                    transmitter_state <= SPI_MASTER_TRANSMITTER_TRANSFERRING;
                end
            end

            SPI_MASTER_TRANSMITTER_TRANSFERRING: begin
                // count cycles to match SPI clock
                if (transfer_clock_cycle_count == CLKS_PER_HALF_BIT - 1) begin                    

                    // HANDLE tx here
                    spi_bus.sck <= !spi_bus.sck;
                    if (!spi_bus.sck == SPI_CLOCK_DATA_UPDATE_EDGE) begin
                        spi_bus.mosi <= mosi_data[transfer_bit_idx];
                    end

                    // escape this state when we run out of bits to transfer
                    if (transfer_bit_idx == 0) begin
                        transmitter_state <= SPI_MASTER_TRANSMITTER_IDLE;
                    end

                    transfer_bit_idx <= transfer_bit_idx - 1;
                end


                transfer_clock_cycle_count <= transfer_clock_cycle_count + 1;
            end
        endcase

        if (mosi_stream.reset) begin
            // return to IDLE state here and re init
            transmitter_state <= SPI_MASTER_TRANSMITTER_IDLE;
        end
    end


    // Do MISO state machine here


endmodule

`default_nettype wire
