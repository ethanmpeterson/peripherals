`default_nettype none
`timescale 1ns / 1ps

module udp_rx_example (
    input var logic udp_sys_clk,
    input var logic system_reset,

    mii_interface.Mac phy_mii,

    // output the rx'd value to the set of LEDs
    output var logic[3:0] led
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

    axis_interface axis_payload_in (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );

    axis_interface axis_payload_out (
        .clk(udp_sys_clk),
        .reset(system_reset)
    );

    udp_configuration_interface udp_conf ();

    udp_header_interface udp_in ();
    udp_header_interface udp_out ();

    always_comb begin
        // Set fixed values for axis_payload_in
        axis_payload_in.tvalid = 1'b0;
        axis_payload_in.tuser = 1'b0;
        axis_payload_in.tid = 1'b0;
        axis_payload_in.tdest = 1'b0;
        axis_payload_in.tkeep = 1'b1;
        axis_payload_in.tlast = 1'b1;

        // discard any data coming back for now
        axis_payload_out.tready = 1'b1;

        // Valid and ready signals for the headers of the UDP packets. Behaves
        // in the same way as it would for AXIS
        udp_in.udp_hdr_valid = 1'b1;
        udp_out.udp_hdr_ready = 1'b1;

        // This will be the FPGA UDP server IP
        udp_in.udp_ip_source_ip = {8'd192, 8'd168, 8'd1, 8'd128};

        // echo the packet back to the IP address it came from
        udp_in.udp_ip_dest_ip = {8'd192, 8'd168, 8'd1, 8'd127};

        // use same source and destination ports as the packet received (echo on the same port)
        udp_in.udp_source_port = 3001;
        udp_in.udp_dest_port = 3000;

        // Not needed since we auto generate packet length in UDP complete
        // udp_in.udp_length = udp_out.udp_length;

        // TODO: use wireshark reference checksums to get to the bottom of why
        // we get the wrong checksums in some packets. Write a TB to do this
        udp_in.udp_length = 1;

        // Other IP configuration info for the UDP input
        udp_in.udp_ip_dscp = 0;
        udp_in.udp_ip_ecn = 0;
        udp_in.udp_ip_ttl = 64;
        udp_in.udp_checksum = 0;
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

    var logic[15:0] port = 0;
    always_ff @(posedge udp_sys_clk) begin
        if (udp_out.udp_hdr_valid && udp_out.udp_hdr_ready) begin
            port <= udp_out.udp_dest_port;
        end

        if (axis_payload_out.tready && axis_payload_out.tvalid && port == 3000) begin
            led <= axis_payload_out.tdata[3:0];
            port <= 0;
        end
    end

    ila_udp_analyzer ila_udp_echo_analyzer (
	      .clk(udp_sys_clk), // input wire clk


	      .probe0(udp_out.udp_hdr_ready), // input wire [0:0]  probe0  
	      .probe1(udp_out.udp_hdr_valid), // input wire [0:0]  probe1 
	      .probe2(axis_payload_out.tdata), // input wire [7:0]  probe2 
	      .probe3(udp_out.udp_checksum), // input wire [15:0]  probe3 
	      .probe4(axis_payload_out.tvalid), // input wire [0:0]  probe4 
	      .probe5(axis_payload_out.tready), // input wire [0:0]  probe5 
	      .probe6(axis_payload_out.tlast), // input wire [0:0]  probe6 
	      .probe7(axis_payload_out.tuser) // input wire [0:0]  probe7
    );

endmodule

`default_nettype wire
