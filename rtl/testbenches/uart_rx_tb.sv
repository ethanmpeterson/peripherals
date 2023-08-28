`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

// Verifies an AND gate as an example of issuing test cases through VUnit.
module uart_rx_tb;

    var logic rx_clk;
    var logic sys_clk;
    var logic rxd = 1;
    var logic[7:0] test_value = 10;
    always begin
        // wait uneven amount of time so that we can test synchronization
        // behavior
        #2
        rx_clk <= !rx_clk;
    end

    always begin
        #1
        sys_clk <= !sys_clk;
    end

    typedef enum int {
        SEND_START_BIT,
        SEND_TEST_DATA,
        SEND_STOP_BIT
    } uart_rx_tb_state_t;

    uart_rx_tb_state_t state = SEND_START_BIT;
    var logic [3:0] bit_count = 0;
    always @(posedge rx_clk) begin
        case (state)
            SEND_START_BIT: begin
                rxd <= 0;
                state <= SEND_TEST_DATA;
            end

            SEND_TEST_DATA: begin
                if (bit_count < 7) begin
                    rxd <= test_value[bit_count];
                    bit_count <= bit_count + 1;
                end else begin
                    bit_count <= 0;
                    state <= SEND_STOP_BIT;
                end
            end

            SEND_STOP_BIT: begin
                test_value <= test_value + 1;
                rxd <= 1'b1;
                // wait a cycle and send the start bit again
                state <= SEND_START_BIT;
            end
        endcase
    end

    axis_interface rx_stream (
        .clk(sys_clk),
        .reset(0)
    );

    uart_rx #(
        .CLKS_PER_BIT(2)
    ) DUT (
        .rxd(rxd),
        .rx_stream(rx_stream)
    );

    var logic [7:0] iter = 0;
    // Begin the Test suite run
    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            rx_clk = 0;
            sys_clk = 0;
            rx_stream.tready = 1;
        end

        `TEST_CASE("check_data_integrity") begin
            automatic int bytes_consumed = 0;
            while (bytes_consumed < 3) begin
                @(posedge sys_clk) begin
                    if (rx_stream.tvalid && rx_stream.tready) begin
                        `CHECK_EQUAL(rx_stream.tdata, 10 + bytes_consumed);
                        bytes_consumed = bytes_consumed + 1;
                    end
                end
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
