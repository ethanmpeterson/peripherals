`default_nettype none
`timescale 1ns / 1ps

module udp_checksum_gen_wrapper (
    axis_interface.Sink axis_payload_in,
    udp_header_interface.Input udp_in,

    axis_interface.Source axis_payload_out,
    udp_header_interface.Output udp_out,

    output var logic busy
);

    udp_checksum_gen udp_checksum_gen_wrapped (
        // assume both axis streams carry the same clock
        .clk(axis_payload_in.clk),
        .rst(axis_payload_in.reset),

        .s_udp_hdr_valid(udp_in.udp_hdr_valid),
        .s_udp_hdr_ready(udp_in.udp_hdr_ready),
        .s_eth_dest_mac(udp_in.udp_eth_dest_mac),
        .s_eth_src_mac(udp_in.udp_eth_src_mac),
        .s_eth_type(udp_in.udp_eth_type),
        .s_ip_version(udp_in.udp_ip_version),
        .s_ip_ihl(udp_in.udp_ip_ihl),
        .s_ip_dscp(udp_in.udp_ip_dscp),
        .s_ip_ecn(udp_in.udp_ip_ecn),
        .s_ip_identification(udp_in.udp_ip_identification),
        .s_ip_flags(udp_in.udp_ip_flags),
        .s_ip_fragment_offset(udp_in.udp_ip_fragment_offset),
        .s_ip_ttl(udp_in.udp_ip_ttl),
        .s_ip_header_checksum(udp_in.udp_ip_header_checksum),
        .s_ip_source_ip(udp_in.udp_ip_source_ip),
        .s_ip_dest_ip(udp_in.udp_ip_dest_ip),
        .s_udp_source_port(udp_in.udp_source_port),
        .s_udp_dest_port(udp_in.udp_dest_port),

        .s_udp_payload_axis_tdata(axis_payload_in.tdata),
        .s_udp_payload_axis_tvalid(axis_payload_in.tvalid),
        .s_udp_payload_axis_tready(axis_payload_in.tready),
        .s_udp_payload_axis_tlast(axis_payload_in.tlast),
        .s_udp_payload_axis_tuser(axis_payload_in.tuser),

        // UDP Out
        .m_udp_hdr_valid(udp_out.udp_hdr_valid),
        .m_udp_hdr_ready(udp_out.udp_hdr_ready),
        .m_eth_dest_mac(udp_out.udp_eth_dest_mac),
        .m_eth_src_mac(udp_out.udp_eth_src_mac),
        .m_eth_type(udp_out.udp_eth_type),
        .m_ip_version(udp_out.udp_ip_version),
        .m_ip_ihl(udp_out.udp_ip_ihl),
        .m_ip_dscp(udp_out.udp_ip_dscp),
        .m_ip_ecn(udp_out.udp_ip_ecn),
        .m_ip_length(udp_out.udp_ip_length),
        .m_ip_identification(udp_out.udp_ip_identification),
        .m_ip_flags(udp_out.udp_ip_flags),
        .m_ip_fragment_offset(udp_out.udp_ip_fragment_offset),
        .m_ip_ttl(udp_out.udp_ip_ttl),
        .m_ip_protocol(udp_out.udp_ip_protocol),
        .m_ip_header_checksum(udp_out.udp_ip_header_checksum),
        .m_ip_source_ip(udp_out.udp_ip_source_ip),
        .m_ip_dest_ip(udp_out.udp_ip_dest_ip),
        .m_udp_source_port(udp_out.udp_source_port),
        .m_udp_dest_port(udp_out.udp_dest_port),
        .m_udp_length(udp_out.udp_length),
        .m_udp_checksum(udp_out.udp_checksum),

        .m_udp_payload_axis_tdata(axis_payload_out.tdata),
        .m_udp_payload_axis_tvalid(axis_payload_out.tvalid),
        .m_udp_payload_axis_tready(axis_payload_out.tready),
        .m_udp_payload_axis_tlast(axis_payload_out.tlast),
        .m_udp_payload_axis_tuser(axis_payload_out.tuser),

        .busy(busy)
    );

endmodule

`default_nettype wire
