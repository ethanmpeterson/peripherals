`default_nettype none
`timescale 1ns / 1ps

module udp_tx_example (
    input var logic udp_sys_clk,
    input var logic system_reset,
    mii_interface.Mac phy_mii
);


    axis_interface axis_mii_rx_stream (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );

    axis_interface axis_mii_tx_stream (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );

    eth_mac_cfg_interface mac_config ();
    eth_mac_status_interface mac_status ();
    eth_mac_mii_fifo_wrapper mac_wrapper_inst (
        .axis_mii_in(axis_mii_tx_stream),
        .axis_mii_out(axis_mii_rx_stream),

        .phy_mii(phy_mii),

        .status(mac_status),
        .cfg(mac_config)
    );

    axis_interface axis_eth_out (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );
    eth_interface eth_out ();

    axis_interface axis_eth_in (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );
    eth_interface eth_in ();

    eth_axis_rx_wrapper eth_axis_rx_wrapper_inst (
        .axis_mii_stream_in(axis_mii_rx_stream),

        .axis_eth_out(axis_eth_out),
        .eth_out(eth_out),

        .busy(),
        .error_header_early_termination()
    );

    // configure loopback through the wrappers
    eth_axis_tx_wrapper eth_axis_tx_wrapper_inst (
        .axis_mii_stream_out(axis_mii_tx_stream),

        .axis_eth_in(axis_eth_in),
        .eth_in(eth_in),

        .busy()
    );

    axis_interface axis_payload_loopback (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );

    udp_configuration_interface udp_conf ();

    udp_header_interface udp_in ();
    udp_header_interface udp_out ();

    // always_comb begin
        // Valid and ready signals for the headers of the UDP packets. Behaves
        // in the same way as it would for AXIS
        // udp_in.udp_hdr_valid = udp_out.udp_hdr_valid;
        // udp_out.udp_hdr_ready = udp_in.udp_hdr_ready;

        // This will be the FPGA UDP server IP
        // udp_in.udp_ip_source_ip = {8'd192, 8'd168, 8'd1, 8'd128};

        // echo the packet back to the IP address it came from
        // udp_in.udp_ip_dest_ip = udp_out.udp_ip_source_ip;

        // use same source and destination ports as the packet received (echo on the same port)
        // udp_in.udp_source_port = udp_out.udp_source_port;
        // udp_in.udp_dest_port = udp_out.udp_dest_port;

        // udp_in.udp_length = udp_out.udp_length;

        // Other IP configuration info for the UDP input
        // udp_in.udp_ip_dscp = 0;
        // udp_in.udp_ip_ecn = 0;
        // udp_in.udp_ip_ttl = 64;
        // udp_in.udp_checksum = 0;
    // end

    axis_interface axis_payload_in (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );

    axis_interface axis_payload_out (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );

    // set fixed values for unused AXIS signals
    always_comb begin
        // Set defaults for UDP inputs
        axis_payload_in.tkeep = 1'b1;
        axis_payload_in.tid = 0;
        axis_payload_in.tdest = 0;
        axis_payload_in.tuser = 1'b0;
        // axis_payload_in.tlast = 1'b1;
        // axis_payload_in.tlast = 1'b0;

        udp_in.udp_hdr_valid = 1'b1; // Mark header as always valid

        // This is the IP FPGA will tx data from
        udp_in.udp_ip_source_ip = {8'd192, 8'd168, 8'd1, 8'd128};

        // This is the IP of your ethernet adapter connected to the FPGA on your computer
        udp_in.udp_ip_dest_ip = {8'd192, 8'd168, 8'd1, 8'd127};

        // Port the FPGA will tx UDP messages from
        udp_in.udp_source_port = 3000;

        // Destination port for the UDP messages transmitted from the FPGA. The
        // example python script will listen on this port.
        udp_in.udp_dest_port = 3000;

        // Not yet sure how to set this based off a 1 byte payload
        udp_in.udp_length = 20;

        udp_in.udp_ip_dscp = 0;
        udp_in.udp_ip_ecn = 0;
        udp_in.udp_ip_ttl = 2;
        udp_in.udp_checksum = 0;

        // Set defaults for UDP outputs
        axis_payload_out.tready = 1'b1;
        udp_out.udp_hdr_ready = 1'b1;
    end

    always_ff @(posedge udp_sys_clk) begin
        axis_payload_in.tdata <= 0;
        axis_payload_in.tvalid <= 1'b1;

        // Tx increasing int in a loop. Can be checked with the udp_tx_example python script
        if (axis_payload_in.tvalid && axis_payload_in.tready) begin
            axis_payload_in.tdata <= axis_payload_in.tdata + 1;
            if (axis_payload_in.tdata == 255) begin
                axis_payload_in.tlast <= 1'b1;
            end else begin
                axis_payload_in.tlast <= 1'b0;
            end
        end
    end

        udp_complete_wrapper udp_server (
            .axis_udp_payload_in(axis_payload_in.Sink),
            .udp_in(udp_in.Input),

            .axis_udp_payload_out(axis_payload_out.Source),
            .udp_out(udp_out.Output),

            // cross over input output
            .axis_eth_in(axis_eth_out),
            .eth_in(eth_out),

            .axis_eth_out(axis_eth_in),
            .eth_out(eth_in),

            .udp_configuration(udp_conf)
        );


        // ila_eth_axis ila_tx_example_inst (
	      //     .clk(axis_payload_in.clk), // input wire clk

	      //     .probe0(axis_payload_in.tdata), // input wire [7:0]  probe0
	      //     .probe1(axis_payload_in.tvalid), // input wire [0:0]  probe1
	      //     .probe2(udp_in.udp_hdr_valid), // input wire [0:0]  probe2
	      //     .probe3(udp_in.udp_hdr_ready) // input wire [0:0]  probe3
        // );

endmodule

`default_nettype wire

