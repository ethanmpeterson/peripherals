
`default_nettype none

`include "vunit_defines.svh"

// Verifies an AND gate as an example of issuing test cases through VUnit.
module uart_rx_tb;

    var logic rx_clk;
    var logic sys_clk;

    always begin
        // wait uneven amount of time so that we can test synchronization
        // behavior
        #10001
        rx_clk <= !rx_clk;
    end

    always begin
        #10
        sys_clk <= !sys_clk;
    end

    // Begin the Test suite run
    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            rx_clk = 0;
            sys_clk = 0;
        end

        `TEST_CASE("example") begin
            @(posedge rx_clk) `CHECK_EQUAL(0, 0);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire