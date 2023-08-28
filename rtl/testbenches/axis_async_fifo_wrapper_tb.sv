`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module axis_async_fifo_wrapper_tb;

    var logic s_clk = 0;
    var logic m_clk = 0;
    var logic reset = 0;
    always begin
        #10
        s_clk <= !s_clk;
    end

    always begin
        #15
        m_clk <= !m_clk;
    end

    axis_interface test_stream (
        .clk(s_clk),
        .reset(reset)
    );

    axis_interface return_stream (
        .clk(m_clk),
        .reset(reset)
    );

    // Set up the FIFO wrapper    
    axis_fifo_status_interface dut_sink_status ();
    axis_fifo_status_interface dut_source_status ();

    axis_async_fifo_wrapper DUT (
        .sink(test_stream.Sink),
        .sink_status(dut_sink_status),

        .source(return_stream.Source),
        .source_status(dut_source_status)
    );

    typedef enum int {
        WAIT,
        WRITE_FIFO
    } axis_fifo_wrapper_tb_state_t;
    axis_fifo_wrapper_tb_state_t state = WAIT;

    // set up a state machine to load data into the FIFO
    // then verify output with a test case
    always @(posedge s_clk) begin
        case (state)
            WAIT: begin
                if (test_stream.tready) begin
                    test_stream.tvalid <= 1'b1;

                    state <= WRITE_FIFO;
                end
            end
            WRITE_FIFO: begin
                if (test_stream.tvalid && test_stream.tready) begin
                    test_stream.tdata <= test_stream.tdata + 1;
                    test_stream.tvalid <= 0;

                    state <= WAIT;
                end
            end
        endcase
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            s_clk = 0;
            m_clk = 0;

            // Provide fixed values for unused FIFO signals
            test_stream.tdata = 0;
            test_stream.tlast = 1'b1;
            test_stream.tkeep = 1'b1;
            test_stream.tid = 0;
            test_stream.tdest = 0;
            test_stream.tuser = 0;
            test_stream.tvalid = 0;

            return_stream.tready = 1;

        end

        `TEST_CASE("check_fifo_output") begin
            automatic int bytes_consumed = 0;
            while (bytes_consumed < 10) begin
                @(posedge m_clk) begin
                    if (return_stream.tvalid && return_stream.tready) begin
                        `CHECK_EQUAL(return_stream.tdata, bytes_consumed);
                        bytes_consumed = bytes_consumed + 1;
                    end
                end
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
