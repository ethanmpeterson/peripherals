`default_nettype none
`timescale 1ns / 1ps

// full UDP server wrapper. This should allow us to link up with the laptop.
// Needs to be cleaned up with discrete wrappers.
// AXI stream IO can hook up directly the MII MAC initialized in the top level module

// Takes a 125 MHz clock input.

module udp_loopback_server (
    input var logic sys_clk,
    input var logic system_reset,

    axis_interface.Sink mii_rx_stream,
    axis_interface.Source mii_tx_stream,

    udp_configuration_interface udp_configuration
);
    var logic                       rx_udp_hdr_valid;
    var logic                       rx_udp_hdr_ready;
    var logic [47:0]                rx_udp_eth_dest_mac;
    var logic [47:0]                rx_udp_eth_src_mac;
    var logic [15:0]                rx_udp_eth_type;
    var logic [3:0]                 rx_udp_ip_version;
    var logic [3:0]                 rx_udp_ip_ihl;
    var logic [5:0]                 rx_udp_ip_dscp;
    var logic [1:0]                 rx_udp_ip_ecn;
    var logic [15:0]                rx_udp_ip_length;
    var logic [15:0]                rx_udp_ip_identification;
    var logic [2:0]                 rx_udp_ip_flags;
    var logic [12:0]                rx_udp_ip_fragment_offset;
    var logic [7:0]                 rx_udp_ip_ttl;
    var logic [7:0]                 rx_udp_ip_protocol;
    var logic [15:0]                rx_udp_ip_header_checksum;
    var logic [31:0]                rx_udp_ip_source_ip;
    var logic [31:0]                rx_udp_ip_dest_ip;
    var logic [15:0]                rx_udp_source_port;
    var logic [15:0]                rx_udp_dest_port;
    var logic [15:0]                rx_udp_length;
    var logic [15:0]                rx_udp_checksum;
    var logic [7:0]                 rx_udp_payload_axis_tdata;
    var logic                       rx_udp_payload_axis_tvalid;
    var logic                       rx_udp_payload_axis_tready;
    var logic                       rx_udp_payload_axis_tlast;
    var logic                       rx_udp_payload_axis_tuser;

    // Ethernet input and output which can be connected directly to the eth_axis_* wrappers
    eth_axis_interface eth_packet_sink ();
    eth_axis_interface eth_packet_source ();

    eth_axis_interface eth_packet_loopback_stream ();

    eth_axis_rx_wrapper eth_axis_rx_inst (
        .mii_stream(mii_rx_stream),
        .eth_stream(eth_packet_loopback_stream),

        .busy(),
        .error_header_early_termination()
    );

    eth_axis_tx_wrapper eth_axis_tx_inst (
        .mii_stream(mii_tx_stream),
        .eth_stream(eth_packet_loopback_stream),

        .busy()
    );

    axis_interface #(
        .DATA_WIDTH(8),
        .KEEP_ENABLE(1)
    ) udp_tx_payload_stream (
        .clk(sys_clk),
        .reset(system_reset)
    );

    axis_interface #(
        .DATA_WIDTH(8),
        .KEEP_ENABLE(1)
    ) udp_rx_payload_stream (
        .clk(sys_clk),
        .reset(system_reset)
    );

    // TODO: hook up rx udp payloads to a FIFO input. Output to go to tx side
    // creating a full packet loopback interface
    axis_fifo_status_interface loopback_fifo_status ();
    axis_fifo_wrapper #(
        .DATA_WIDTH(udp_tx_payload_stream.DATA_WIDTH)
    ) loopback_fifo (
        .sink(udp_rx_payload_stream.Sink),
        .source(udp_tx_payload_stream.Source),

        .status(loopback_fifo_status)
    );

    udp_complete udp_complete_inst (
        // assuming it has the same clock as rx
        .clk(udp_tx_payload_stream.clk),
        .rst(udp_tx_payload_stream.reset),

        // Ethernet frame input
        .s_eth_hdr_valid(eth_packet_source.hdr_valid),
        .s_eth_hdr_ready(eth_packet_source.hdr_ready),
        .s_eth_dest_mac(eth_packet_source.dest_mac),
        .s_eth_src_mac(eth_packet_source.src_mac),
        .s_eth_type(eth_packet_source.eth_type),
        .s_eth_payload_axis_tdata(eth_packet_source.tdata),
        .s_eth_payload_axis_tvalid(eth_packet_source.tvalid),
        .s_eth_payload_axis_tready(eth_packet_source.tready),
        .s_eth_payload_axis_tlast(eth_packet_source.tlast),
        .s_eth_payload_axis_tuser(eth_packet_source.tuser),

        // Ethernet frame output
        .m_eth_hdr_valid(eth_packet_sink.hdr_valid),
        .m_eth_hdr_ready(eth_packet_sink.hdr_ready),
        .m_eth_dest_mac(eth_packet_sink.dest_mac),
        .m_eth_src_mac(eth_packet_sink.src_mac),
        .m_eth_type(eth_packet_sink.eth_type),
        .m_eth_payload_axis_tdata(eth_packet_sink.tdata),
        .m_eth_payload_axis_tvalid(eth_packet_sink.tvalid),
        .m_eth_payload_axis_tready(eth_packet_sink.tready),
        .m_eth_payload_axis_tlast(eth_packet_sink.tlast),
        .m_eth_payload_axis_tuser(eth_packet_sink.tuser),

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
        .s_udp_hdr_valid(rx_udp_hdr_valid),
        .s_udp_hdr_ready(rx_udp_hdr_ready),
        .s_udp_ip_dscp(0),
        .s_udp_ip_ecn(0),
        .s_udp_ip_ttl(64),
        .s_udp_ip_source_ip({8'd192, 8'd168, 8'd1,   8'd128}),
        .s_udp_ip_dest_ip(rx_udp_ip_source_ip),
        .s_udp_source_port(rx_udp_dest_port),
        .s_udp_dest_port(rx_udp_source_port),
        .s_udp_length(rx_udp_length),
        .s_udp_checksum(0),
        .s_udp_payload_axis_tdata(udp_tx_payload_stream.tdata),
        .s_udp_payload_axis_tvalid(udp_tx_payload_stream.tvalid),
        .s_udp_payload_axis_tready(udp_tx_payload_stream.tready),
        .s_udp_payload_axis_tlast(udp_tx_payload_stream.tlast),
        .s_udp_payload_axis_tuser(udp_tx_payload_stream.tuser),

        // UDP frame output
        .m_udp_hdr_valid(rx_udp_hdr_valid),
        .m_udp_hdr_ready(rx_udp_hdr_ready),
        .m_udp_eth_dest_mac(),
        .m_udp_eth_src_mac(),
        .m_udp_eth_type(),
        .m_udp_ip_version(),
        .m_udp_ip_ihl(),
        .m_udp_ip_dscp(),
        .m_udp_ip_ecn(),
        .m_udp_ip_length(),
        .m_udp_ip_identification(),
        .m_udp_ip_flags(),
        .m_udp_ip_fragment_offset(),
        .m_udp_ip_ttl(),
        .m_udp_ip_protocol(),
        .m_udp_ip_header_checksum(),
        .m_udp_ip_source_ip(rx_udp_ip_source_ip),
        .m_udp_ip_dest_ip(),
        .m_udp_source_port(rx_udp_source_port),
        .m_udp_dest_port(rx_udp_dest_port),
        .m_udp_length(rx_udp_length),
        .m_udp_checksum(),
        .m_udp_payload_axis_tdata(udp_rx_payload_stream.tdata),
        .m_udp_payload_axis_tvalid(udp_rx_payload_stream.tvalid),
        .m_udp_payload_axis_tready(udp_rx_payload_stream.tready),
        .m_udp_payload_axis_tlast(udp_rx_payload_stream.tlast),
        .m_udp_payload_axis_tuser(udp_rx_payload_stream.tuser),

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
