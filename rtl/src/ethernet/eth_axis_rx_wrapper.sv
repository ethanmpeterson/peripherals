`default_nettype none
`timescale 1ns / 1ps

module eth_axis_rx_wrapper #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = 0,
    parameter KEEP_WIDTH = 1
) (
    axis_interface.Sink axis_mii_stream_in,

    axis_interface.Source axis_eth_out,
    eth_interface.Source eth_out,

    output var logic busy,
    output var logic error_header_early_termination
);
    eth_axis_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) eth_axis_rx_inst (
        // clocked with the MII PHY
        .clk(axis_mii_stream_in.clk),
        .rst(axis_mii_stream_in.reset),

        .s_axis_tdata(axis_mii_stream_in.tdata),
        .s_axis_tkeep(axis_mii_stream_in.tkeep),
        .s_axis_tvalid(axis_mii_stream_in.tvalid),
        .s_axis_tready(axis_mii_stream_in.tready),
        .s_axis_tlast(axis_mii_stream_in.tlast),
        .s_axis_tuser(axis_mii_stream_in.tuser),

        .m_eth_hdr_valid(eth_out.hdr_valid),
        .m_eth_hdr_ready(eth_out.hdr_ready),
        .m_eth_dest_mac(eth_out.dest_mac),
        .m_eth_src_mac(eth_out.src_mac),
        .m_eth_type(eth_out.eth_type),
        .m_eth_payload_axis_tdata(axis_eth_out.tdata),
        .m_eth_payload_axis_tkeep(axis_eth_out.tkeep),
        .m_eth_payload_axis_tvalid(axis_eth_out.tvalid),
        .m_eth_payload_axis_tready(axis_eth_out.tready),
        .m_eth_payload_axis_tlast(axis_eth_out.tlast),
        .m_eth_payload_axis_tuser(axis_eth_out.tuser),

        .busy(busy),
        .error_header_early_termination(error_header_early_termination)
    );

    // ila_eth_axis ila_eth_axis_inst (
	  //     .clk(axis_eth_out.clk), // input wire clk


	  //     .probe0(axis_eth_out.tdata), // input wire [7:0]  probe0
	  //     .probe1(axis_eth_out.tvalid), // input wire [0:0]  probe1
	  //     .probe2(axis_eth_out.tready), // input wire [0:0]  probe2
	  //     .probe3(axis_eth_out.tlast) // input wire [0:0]  probe3
    // );

endmodule

`default_nettype wire
