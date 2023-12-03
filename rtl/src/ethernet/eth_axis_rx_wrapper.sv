`default_nettype none
`timescale 1ns / 1ps

module eth_axis_rx_wrapper #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1
) (
    // raw packet input
    axis_interface.Sink mii_stream,

    // ethernet encoded frame output
    eth_axis_interface.Source eth_stream,

    output var logic busy,
    output var logic error_header_early_termination
);
    eth_axis_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) eth_axis_rx_inst (
        // clocked with the MII PHY
        .clk(mii_stream.clk),
        .rst(mii_stream.reset),

        .s_axis_tdata(mii_stream.tdata),
        .s_axis_tkeep(mii_stream.tkeep),
        .s_axis_tvalid(mii_stream.tvalid),
        .s_axis_tready(mii_stream.tready),
        .s_axis_tlast(mii_stream.tlast),
        .s_axis_tuser(mii_stream.tuser),

        .m_eth_hdr_valid(eth_stream.hdr_valid),
        .m_eth_hdr_ready(eth_stream.hdr_ready),
        .m_eth_dest_mac(eth_stream.dest_mac),
        .m_eth_src_mac(eth_stream.src_mac),
        .m_eth_type(eth_stream.eth_type),
        .m_eth_payload_axis_tdata(eth_stream.tdata),
        .m_eth_payload_axis_tkeep(eth_stream.tkeep),
        .m_eth_payload_axis_tvalid(eth_stream.tvalid),
        .m_eth_payload_axis_tready(eth_stream.tready),
        .m_eth_payload_axis_tlast(eth_stream.tlast),
        .m_eth_payload_axis_tuser(eth_stream.tuser),

        .busy(busy),
        .error_header_early_termination(error_header_early_termination)
    );

endmodule

`default_nettype wire
