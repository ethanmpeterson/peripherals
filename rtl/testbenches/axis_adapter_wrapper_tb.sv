`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module axis_adapter_wrapper_tb;

    var logic clk = 0;
    var logic reset = 0;
    always begin
        #10
        clk <= !clk;
    end


    axis_interface #(
        .DATA_WIDTH(16),
        .KEEP_ENABLE(1)
    ) test_stream (
        .clk(clk),
        .reset(reset)
    );

    axis_interface #(
        .DATA_WIDTH(8),
        .KEEP_ENABLE(1)
    ) adapted_stream (
        .clk(clk),
        .reset(reset)
    );

    axis_adapter_wrapper DUT (
        .sink(test_stream.Sink),

        .source(adapted_stream.Source)
    );

    typedef enum int {
        INIT,
        WRITE_TEST_STREAM
    } axis_adapter_wrapper_tb_state_t;
    axis_adapter_wrapper_tb_state_t state = INIT;

    // set up a state machine to load data into the FIFO
    // then verify output with a test case
    var logic[7:0] upper_byte = 8'hFF;
    var logic[7:0] lower_byte = 8'h00;
    always @(posedge clk) begin
        case (state)
            INIT: begin
                if (test_stream.tready) begin
                    test_stream.tvalid <= 1'b1;

                    test_stream.tdata[15:8] <= upper_byte;
                    test_stream.tdata[7:0] <= lower_byte;

                    upper_byte <= upper_byte - 1;
                    lower_byte <= lower_byte + 1;

                    state <= WRITE_TEST_STREAM;
                end
            end
            WRITE_TEST_STREAM: begin
                if (test_stream.tvalid && test_stream.tready) begin
                    test_stream.tdata[15:8] <= upper_byte;
                    test_stream.tdata[7:0] <= lower_byte;

                    upper_byte <= upper_byte - 1;
                    lower_byte <= lower_byte + 1;
                end
            end
        endcase
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 0;

            // Provide fixed values for unused FIFO signals
            test_stream.tlast = 1'b1;
            test_stream.tkeep = 2'b11;
            test_stream.tid = 0;
            test_stream.tdest = 0;
            test_stream.tuser = 0;
            test_stream.tvalid = 0;

            adapted_stream.tready = 1;

        end

        `TEST_CASE("check_adapted_output") begin
            automatic int cycle_counter = 0;
            
            // comparison values for the upper and lower bytes
            automatic int upper_cmp = 255;
            automatic int lower_cmp = 0;
            while (cycle_counter < 100) begin
                @(posedge clk) begin
                    if (adapted_stream.tvalid && adapted_stream.tready) begin
                        if (cycle_counter % 2 == 0) begin
                            `CHECK_EQUAL(adapted_stream.tdata, lower_cmp);
                            lower_cmp = lower_cmp + 1;
                        end else begin
                            `CHECK_EQUAL(adapted_stream.tdata, upper_cmp);
                            upper_cmp = upper_cmp - 1;
                        end
                        cycle_counter = cycle_counter + 1;
                    end
                end
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
