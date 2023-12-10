`default_nettype none
`timescale 1ns / 1ps

// both AXI Streams should have the same clock
module udp_complete_wrapper (
    axis_interface.Sink axis_udp_payload_in,
    udp_header_interface.Output udp_in,

    axis_interface.Source axis_udp_payload_out,
    udp_header_interface.Output udp_out,

    axis_interface.Sink axis_eth_in,
    eth_interface.Sink eth_in,

    axis_interface.Source axis_eth_out,
    eth_interface.Source eth_out,

    udp_configuration_interface udp_configuration
);

    var logic                       rx_udp_hdr_valid;
    var logic                       rx_udp_hdr_ready;
    var logic [31:0]                rx_udp_ip_source_ip;
    var logic [15:0]                rx_udp_source_port;
    var logic [15:0]                rx_udp_dest_port;
    var logic [15:0]                rx_udp_length;

    udp_complete udp_complete_inst (
        // assuming it has the same clock as rx
        .clk(axis_udp_payload_in.clk),
        .rst(axis_udp_payload_in.reset),

        // Ethernet frame input
        .s_eth_hdr_valid(eth_in.hdr_valid),
        .s_eth_hdr_ready(eth_in.hdr_ready),
        .s_eth_dest_mac(eth_in.dest_mac),
        .s_eth_src_mac(eth_in.src_mac),
        .s_eth_type(eth_in.eth_type),
        .s_eth_payload_axis_tdata(axis_eth_in.tdata),
        .s_eth_payload_axis_tvalid(axis_eth_in.tvalid),
        .s_eth_payload_axis_tready(axis_eth_in.tready),
        .s_eth_payload_axis_tlast(axis_eth_in.tlast),
        .s_eth_payload_axis_tuser(axis_eth_in.tuser),

        // Ethernet frame output
        .m_eth_hdr_valid(eth_out.hdr_valid),
        .m_eth_hdr_ready(eth_out.hdr_ready),
        .m_eth_dest_mac(eth_out.dest_mac),
        .m_eth_src_mac(eth_out.src_mac),
        .m_eth_type(eth_out.eth_type),
        .m_eth_payload_axis_tdata(axis_eth_out.tdata),
        .m_eth_payload_axis_tvalid(axis_eth_out.tvalid),
        .m_eth_payload_axis_tready(axis_eth_out.tready),
        .m_eth_payload_axis_tlast(axis_eth_out.tlast),
        .m_eth_payload_axis_tuser(axis_eth_out.tuser),

        // IP Frame Input
        .s_ip_hdr_valid(0),
        .s_ip_hdr_ready(),
        .s_ip_dscp(0),
        .s_ip_ecn(0),
        .s_ip_length(0),
        .s_ip_ttl(0),
        .s_ip_protocol(0),
        .s_ip_source_ip(0),
        .s_ip_dest_ip(0),
        .s_ip_payload_axis_tdata(0),
        .s_ip_payload_axis_tvalid(0),
        .s_ip_payload_axis_tready(),
        .s_ip_payload_axis_tlast(0),
        .s_ip_payload_axis_tuser(0),

        // IP Frame Output
        .m_ip_hdr_valid(),
        .m_ip_hdr_ready(1),
        .m_ip_eth_dest_mac(),
        .m_ip_eth_src_mac(),
        .m_ip_eth_type(),
        .m_ip_version(),
        .m_ip_ihl(),
        .m_ip_dscp(),
        .m_ip_ecn(),
        .m_ip_length(),
        .m_ip_identification(),
        .m_ip_flags(),
        .m_ip_fragment_offset(),
        .m_ip_ttl(),
        .m_ip_protocol(),
        .m_ip_header_checksum(),
        .m_ip_source_ip(),
        .m_ip_dest_ip(),
        .m_ip_payload_axis_tdata(),
        .m_ip_payload_axis_tvalid(),
        .m_ip_payload_axis_tready(1),
        .m_ip_payload_axis_tlast(),
        .m_ip_payload_axis_tuser(),

        // UDP input
        .s_udp_hdr_valid(udp_in.udp_hdr_valid),
        .s_udp_hdr_ready(udp_in.udp_hdr_ready),
        .s_udp_ip_dscp(0),
        .s_udp_ip_ecn(0),
        .s_udp_ip_ttl(64),
        .s_udp_ip_source_ip({8'd192, 8'd168, 8'd1, 8'd128}),
        .s_udp_ip_dest_ip(udp_in.udp_ip_dest_ip),
        .s_udp_source_port(udp_in.udp_source_port),
        .s_udp_dest_port(udp_in.udp_dest_port),
        .s_udp_length(udp_in.udp_length),
        .s_udp_checksum(0),
        .s_udp_payload_axis_tdata(axis_udp_payload_in.tdata),
        .s_udp_payload_axis_tvalid(axis_udp_payload_in.tvalid),
        .s_udp_payload_axis_tready(axis_udp_payload_in.tready),
        .s_udp_payload_axis_tlast(axis_udp_payload_in.tlast),
        .s_udp_payload_axis_tuser(axis_udp_payload_in.tuser),

        // UDP frame output
        .m_udp_hdr_valid(udp_out.udp_hdr_valid),
        .m_udp_hdr_ready(udp_out.udp_hdr_ready),
        .m_udp_eth_dest_mac(udp_out.udp_eth_dest_mac),
        .m_udp_eth_src_mac(udp_out.udp_eth_src_mac),
        .m_udp_eth_type(udp_out.udp_eth_type),
        .m_udp_ip_version(udp_out.udp_ip_version),
        .m_udp_ip_ihl(udp_out.udp_ip_ihl),
        .m_udp_ip_dscp(udp_out.udp_ip_dscp),
        .m_udp_ip_ecn(udp_out.udp_ip_ecn),
        .m_udp_ip_length(udp_out.udp_ip_length),
        .m_udp_ip_identification(udp_out.udp_ip_identification),
        .m_udp_ip_flags(udp_out.udp_ip_flags),
        .m_udp_ip_fragment_offset(udp_out.udp_ip_fragment_offset),
        .m_udp_ip_ttl(udp_out.udp_ip_ttl),
        .m_udp_ip_protocol(udp_out.udp_ip_protocol),
        .m_udp_ip_header_checksum(udp_out.udp_ip_header_checksum),
        .m_udp_ip_source_ip(udp_out.udp_ip_source_ip),
        .m_udp_ip_dest_ip(udp_out.udp_ip_dest_ip),
        .m_udp_source_port(udp_out.udp_source_port),
        .m_udp_dest_port(udp_out.udp_dest_port),
        .m_udp_length(udp_out.udp_length),
        .m_udp_checksum(udp_out.udp_checksum),
        .m_udp_payload_axis_tdata(axis_udp_payload_out.tdata),
        .m_udp_payload_axis_tvalid(axis_udp_payload_out.tvalid),
        .m_udp_payload_axis_tready(axis_udp_payload_out.tready),
        .m_udp_payload_axis_tlast(axis_udp_payload_out.tlast),
        .m_udp_payload_axis_tuser(axis_udp_payload_out.tuser),

        // status signals
        .ip_rx_busy(),
        .ip_tx_busy(),
        .udp_rx_busy(),
        .udp_tx_busy(),
        .ip_rx_error_header_early_termination(),
        .ip_rx_error_payload_early_termination(),
        .ip_rx_error_invalid_header(),
        .ip_rx_error_invalid_checksum(),
        .ip_tx_error_payload_early_termination(),
        .ip_tx_error_arp_failed(),
        .udp_rx_error_header_early_termination(),
        .udp_rx_error_payload_early_termination(),
        .udp_tx_error_payload_early_termination(),

        // UDP / IP config
        .local_mac(udp_configuration.local_mac),
        .local_ip(udp_configuration.local_ip),
        .gateway_ip(udp_configuration.gateway_ip),
        .subnet_mask(udp_configuration.subnet_mask),
        .clear_arp_cache(0)
    );
endmodule

`default_nettype wire
