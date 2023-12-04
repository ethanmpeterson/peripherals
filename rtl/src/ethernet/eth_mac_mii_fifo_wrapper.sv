`default_nettype none
`timescale 1ns / 1ps

module eth_mac_mii_fifo_wrapper #(
    // Setting these defaults for an Artix A7 Xilinx FPGA
    parameter TARGET = "XILINX",
    parameter CLOCK_INPUT_STYLE = "BUFR",

    parameter AXIS_DATA_WIDTH = 8,
    parameter AXIS_KEEP_ENABLE = 0,
    parameter AXIS_KEEP_WIDTH = 1,

    parameter TX_FIFO_DEPTH = 4096,
    parameter RX_FIFO_DEPTH = 4096
) (
    axis_interface.Sink axis_mii_in,
    axis_interface.Source axis_mii_out,

    mii_interface.Mac phy_mii,

    eth_mac_status_interface status,

    eth_mac_cfg_interface cfg
);
    eth_mac_mii_fifo #(
        .TARGET(TARGET),
        .CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE),
        .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
        .AXIS_KEEP_ENABLE(AXIS_KEEP_ENABLE),
        .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH),

        .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
        .RX_FIFO_DEPTH(RX_FIFO_DEPTH),

        .RX_FRAME_FIFO(1),
        .TX_FRAME_FIFO(1)
    ) wrapped_mac (
        // assumed that source and sink interfaces have the same reset signal
        // and the same clock
        .rst(axis_mii_in.reset),
        .logic_rst(axis_mii_in.reset),

        .logic_clk(axis_mii_in.clk),

        .tx_axis_tdata(axis_mii_in.tdata),
        .tx_axis_tkeep(axis_mii_in.tkeep),
        .tx_axis_tvalid(axis_mii_in.tvalid),
        .tx_axis_tready(axis_mii_in.tready),
        .tx_axis_tlast(axis_mii_in.tlast),
        .tx_axis_tuser(axis_mii_in.tuser),

        .rx_axis_tdata(axis_mii_out.tdata),
        .rx_axis_tkeep(axis_mii_out.tkeep),
        .rx_axis_tvalid(axis_mii_out.tvalid),
        .rx_axis_tready(axis_mii_out.tready),
        .rx_axis_tlast(axis_mii_out.tlast),
        .rx_axis_tuser(axis_mii_out.tuser),

        .mii_rx_clk(phy_mii.rx_clk),
        .mii_rxd(phy_mii.rxd),
        .mii_rx_dv(phy_mii.rx_dv),
        .mii_rx_er(phy_mii.rx_er),
        .mii_tx_clk(phy_mii.tx_clk),
        .mii_txd(phy_mii.txd),
        .mii_tx_en(phy_mii.tx_en),
        .mii_tx_er(phy_mii.tx_er),

        .tx_error_underflow(status.tx_error_underflow),
        .tx_fifo_overflow(status.tx_fifo_overflow),
        .tx_fifo_bad_frame(status.tx_fifo_bad_frame),
        .tx_fifo_good_frame(status.tx_fifo_good_frame),
        .rx_error_bad_frame(status.rx_error_bad_frame),
        .rx_error_bad_fcs(status.rx_error_bad_fcs),
        .rx_fifo_overflow(status.rx_fifo_overflow),
        .rx_fifo_bad_frame(status.rx_fifo_bad_frame),
        .rx_fifo_good_frame(status.rx_fifo_good_frame),

        .cfg_ifg(cfg.ifg),
        .cfg_tx_enable(cfg.tx_enable),
        .cfg_rx_enable(cfg.rx_enable)
    );

    ila_eth_axis ila_mii_rx_fifo (
	      .clk(axis_mii_out.clk), // input wire clk

	      .probe0(axis_mii_out.tdata), // input wire [7:0]  probe0
	      .probe1(axis_mii_out.tvalid), // input wire [0:0]  probe1
	      .probe2(axis_mii_out.tready), // input wire [0:0]  probe2
	      .probe3(axis_mii_out.tlast) // input wire [0:0]  probe3
    );

    ila_eth_axis ila_mii_tx_fifo (
	      .clk(axis_mii_in.clk), // input wire clk

	      .probe0(axis_mii_in.tdata), // input wire [7:0]  probe0
	      .probe1(axis_mii_in.tvalid), // input wire [0:0]  probe1
	      .probe2(axis_mii_in.tready), // input wire [0:0]  probe2
	      .probe3(axis_mii_in.tlast) // input wire [0:0]  probe3
    );
endmodule

`default_nettype wire
