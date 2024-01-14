`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module udp_checksum_gen_wrapper_tb;


    var logic clk;
    var logic reset;
    var logic busy;

    always begin
        #10
        clk <= !clk;
    end

    udp_header_interface udp_in ();
    axis_interface axis_payload_in (
        .clk(clk),
        .reset(reset)
    );

    udp_header_interface udp_out ();
    axis_interface axis_payload_out (
        .clk(clk),
        .reset(reset)
    );



    // TODO: state machine to load the payloads into the module

    // GOAL: ensure that the correct checksum comes out for single byte
    // transactions. Then scale to arbitrary length payloads

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 0;
            busy = 0;
            reset = 0;
        end

        `TEST_CASE("single_byte_checksums") begin
            // Dummy assertion until this is implemented
            `CHECK_EQUAL(0, 0);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
