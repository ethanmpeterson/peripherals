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

    udp_checksum_gen_wrapper DUT (
        .axis_payload_in(axis_payload_in.Sink),
        .udp_in(udp_in.Input),

        .axis_payload_out(axis_payload_out.Source),
        .udp_out(udp_out.Output),

        .busy(busy)
    );


    // TODO: state machine to load the payloads into the module

    // GOAL: ensure that the correct checksum comes out for single byte
    // transactions. Then scale to arbitrary length payloads

    typedef enum int {
        WAIT,
        WRITE,
        DONE
    } udp_checksum_gen_wrapper_tb_state_t;


    udp_checksum_gen_wrapper_tb_state_t state;

    always @(posedge clk) begin
        case (state)
            WAIT: begin
                axis_payload_in.tdata <= 0;
                if (axis_payload_in.tready) begin
                    axis_payload_in.tvalid <= 1;

                    state <= WRITE;
                end
            end
            WRITE: begin
                if (axis_payload_in.tready && axis_payload_in.tvalid) begin
                    state <= DONE;
                end
            end
        endcase
    end

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 0;
            busy = 0;
            reset = 0;

            // Initialize both AXIS streams and UDP interfaces
            axis_payload_in.tlast = 1;
            axis_payload_in.tkeep = 1;
            axis_payload_in.tdest = 0;
            axis_payload_in.tid = 0;
            axis_payload_in.tuser = 0;

            axis_payload_out.tready = 1;

            // UDP init
            udp_in.udp_hdr_valid = 1;
            udp_out.udp_hdr_ready = 1;

            udp_in.udp_ip_source_ip = {8'd192, 8'd168, 8'd1, 8'd128};
            udp_in.udp_ip_dest_ip = {8'd192, 8'd168, 8'd1, 8'd127};
            udp_in.udp_source_port = 3001;
            udp_in.udp_dest_port = 3000;
            udp_in.udp_length = 1;
            udp_in.udp_ip_dscp = 0;
            udp_in.udp_ip_ecn = 0;
            udp_in.udp_ip_ihl = 0;
            udp_in.udp_ip_version = 0;
            udp_in.udp_eth_type = 0;
            udp_in.udp_ip_identification = 0;
            udp_in.udp_ip_flags = 0;
            udp_in.udp_ip_fragment_offset = 0;
            udp_in.udp_ip_ttl = 64;
            udp_in.udp_checksum = 0;
            udp_in.udp_ip_header_checksum = 0;

            udp_in.udp_eth_src_mac = 48'd0;
            udp_in.udp_eth_dest_mac = 48'd0;
        end

        `TEST_CASE("single_byte_checksums") begin
            // Simple test case for manual wave form inspection. to help inform the interface design
            automatic bit checksum_checked = 0;
            while (checksum_checked == 0) begin
                @(posedge clk) begin
                    if (udp_out.udp_hdr_ready && udp_out.udp_hdr_valid) begin
                        // right most value is the checksum of a 0x00 UDP payload
                        `CHECK_EQUAL(udp_out.udp_checksum, 16'h641b);
                        checksum_checked = 1;
                    end
                end
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
