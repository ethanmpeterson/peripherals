`default_nettype none
`timescale 1ns / 1ps

module udp_echo_example (
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

    always_comb begin
        // Valid and ready signals for the headers of the UDP packets. Behaves
        // in the same way as it would for AXIS
        udp_in.udp_hdr_valid = udp_out.udp_hdr_valid;
        udp_out.udp_hdr_ready = udp_in.udp_hdr_ready;

        // This will be the FPGA UDP server IP
        udp_in.udp_ip_source_ip = {8'd192, 8'd168, 8'd1, 8'd128};

        // echo the packet back to the IP address it came from
        udp_in.udp_ip_dest_ip = udp_out.udp_ip_source_ip;

        // use same source and destination ports as the packet received (echo on the same port)
        udp_in.udp_source_port = udp_out.udp_source_port;
        udp_in.udp_dest_port = udp_out.udp_dest_port;

        udp_in.udp_length = udp_out.udp_length;

        // Other IP configuration info for the UDP input
        udp_in.udp_ip_dscp = 0;
        udp_in.udp_ip_ecn = 0;
        udp_in.udp_ip_ttl = 64;
        udp_in.udp_checksum = 0;
    end

    udp_complete_wrapper udp_server (
        .axis_udp_payload_in(axis_payload_loopback),
        .udp_in(udp_in),

        .axis_udp_payload_out(axis_payload_loopback),
        .udp_out(udp_out),

        // cross over input output
        .axis_eth_in(axis_eth_out),
        .eth_in(eth_out),

        .axis_eth_out(axis_eth_in),
        .eth_out(eth_in),

        .udp_configuration(udp_conf)
    );

endmodule

`default_nettype wire