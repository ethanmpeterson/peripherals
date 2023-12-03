`default_nettype none
`timescale 1ns / 1ps

module eth_axis_tx_wrapper #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1
) (
    eth_axis_interface.Sink eth_stream,

    // MII encoded ethernet packets
    axis_interface.Source mii_stream,

    output var logic busy
);
    eth_axis_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) eth_axis_tx_inst (
        .clk(mii_stream.clk),
        .rst(mii_stream.reset),

        .m_axis_tdata(mii_stream.tdata),
        .m_axis_tkeep(mii_stream.tkeep),
        .m_axis_tvalid(mii_stream.tvalid),
        .m_axis_tready(mii_stream.tready),
        .m_axis_tlast(mii_stream.tlast),
        .m_axis_tuser(mii_stream.tuser),

        .s_eth_hdr_valid(eth_stream.hdr_valid),
        .s_eth_hdr_ready(eth_stream.hdr_ready),
        .s_eth_dest_mac(eth_stream.dest_mac),
        .s_eth_src_mac(eth_stream.src_mac),
        .s_eth_type(eth_stream.eth_type),
        .s_eth_payload_axis_tdata(eth_stream.tdata),
        .s_eth_payload_axis_tkeep(eth_stream.tkeep),
        .s_eth_payload_axis_tvalid(eth_stream.tvalid),
        .s_eth_payload_axis_tready(eth_stream.tready),
        .s_eth_payload_axis_tlast(eth_stream.tlast),
        .s_eth_payload_axis_tuser(eth_stream.tuser),

        .busy(busy)
    );

endmodule

`default_nettype wire
