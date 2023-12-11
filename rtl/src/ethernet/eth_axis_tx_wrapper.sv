`default_nettype none
`timescale 1ns / 1ps

module eth_axis_tx_wrapper #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1
) (
    axis_interface.Sink axis_eth_in,
    eth_interface.Sink eth_in,

    // MII encoded ethernet packets
    axis_interface.Source axis_mii_stream_out,

    output var logic busy
);

    eth_axis_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) eth_axis_tx_inst (
        .clk(axis_mii_stream_out.clk),
        .rst(axis_mii_stream_out.reset),

        .s_eth_hdr_valid(eth_in.hdr_valid),
        .s_eth_hdr_ready(eth_in.hdr_ready),
        .s_eth_dest_mac(eth_in.dest_mac),
        .s_eth_src_mac(eth_in.src_mac),
        .s_eth_type(eth_in.eth_type),
        .s_eth_payload_axis_tdata(axis_eth_in.tdata),
        .s_eth_payload_axis_tkeep(axis_eth_in.tkeep),
        .s_eth_payload_axis_tvalid(axis_eth_in.tvalid),
        .s_eth_payload_axis_tready(axis_eth_in.tready),
        .s_eth_payload_axis_tlast(axis_eth_in.tlast),
        .s_eth_payload_axis_tuser(axis_eth_in.tuser),

        .m_axis_tdata(axis_mii_stream_out.tdata),
        .m_axis_tkeep(axis_mii_stream_out.tkeep),
        .m_axis_tvalid(axis_mii_stream_out.tvalid),
        .m_axis_tready(axis_mii_stream_out.tready),
        .m_axis_tlast(axis_mii_stream_out.tlast),
        .m_axis_tuser(axis_mii_stream_out.tuser),

        .busy(busy)
    );

    // ila_eth_axis ila_eth_axis_eth_tx (
	  //     .clk(axis_mii_stream_out.clk), // input wire clk


	  //     .probe0(axis_eth_in.tdata), // input wire [7:0]  probe0
	  //     .probe1(axis_eth_in.tvalid), // input wire [0:0]  probe1
	  //     .probe2(axis_eth_in.tready), // input wire [0:0]  probe2
	  //     .probe3(axis_eth_in.tlast) // input wire [0:0]  probe3
    // );

endmodule

`default_nettype wire
