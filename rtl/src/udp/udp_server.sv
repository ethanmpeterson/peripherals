`default_nettype none
`timescale 1ns / 1ps

// Simple AXI stream in/out UDP wrapper
module udp_complete_wrapper (
    // Ethernet input and output which can be connected directly to the eth_axis_* wrappers
    eth_axis_interface.Sink eth_packet_sink,
    eth_axis_interface.Source eth_packet_source,

    udp_configuration_interface udp_configuration
);
    var logic             tx_ip_hdr_valid;
    var logic             tx_ip_hdr_ready;
    var logic [5:0]       tx_ip_dscp;
    var logic [1:0]       tx_ip_ecn;
    var logic [15:0]      tx_ip_length;
    var logic [7:0]       tx_ip_ttl;
    var logic [7:0]       tx_ip_protocol;
    var logic [31:0]      tx_ip_source_ip;
    var logic [31:0]      tx_ip_dest_ip;
    var logic [7:0]       tx_ip_payload_axis_tdata;
    var logic             tx_ip_payload_axis_tvalid;
    var logic             tx_ip_payload_axis_tready;
    var logic             tx_ip_payload_axis_tlast;
    var logic             tx_ip_payload_axis_tuser;


    udp_complete udp_complete_wrapped (
        // Ethernet frame input
        .s_eth_hdr_valid(eth_packet_sink.hdr_valid),
        .s_eth_hdr_ready(eth_packet_sink.hdr_ready),
        .s_eth_dest_mac(eth_packet_sink.dest_mac),
        .s_eth_src_mac(eth_packet_sink.src_mac),
        .s_eth_type(eth_packet_sink.eth_type),
        .s_eth_payload_axis_tdata(eth_packet_sink.tdata),
        .s_eth_payload_axis_tvalid(eth_packet_sink.tvalid),
        .s_eth_payload_axis_tready(eth_packet_sink.tready),
        .s_eth_payload_axis_tlast(eth_packet_sink.tlast),
        .s_eth_payload_axis_tuser(eth_packet_sink.tuser),

        // Ethernet frame output
        .m_eth_hdr_valid(eth_packet_source.hdr_valid),
        .m_eth_hdr_ready(eth_packet_source.hdr_ready),
        .m_eth_dest_mac(eth_packet_source.dest_mac),
        .m_eth_src_mac(eth_packet_source.src_mac),
        .m_eth_type(eth_packet_source.eth_type),
        .m_eth_payload_axis_tdata(eth_packet_source.tdata),
        .m_eth_payload_axis_tvalid(eth_packet_source.tvalid),
        .m_eth_payload_axis_tready(eth_packet_source.tready),
        .m_eth_payload_axis_tlast(eth_packet_source.tlast),
        .m_eth_payload_axis_tuser(eth_packet_source.tuser),

        // TODO: IP input/output
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

        // TODO: UDP input/output

        // UDP / IP config
        .local_mac(udp_configuration.local_mac),
        .local_ip(udp_configuration.local_ip),
        .gateway_ip(udp_configuration.gateway_ip),
        .subnet_mask(udp_configuration.subnet_mask)
    );
endmodule

`default_nettype wire
