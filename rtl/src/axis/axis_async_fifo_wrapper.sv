`default_nettype none
`timescale 1ns / 1ps

module axis_async_fifo_wrapper #(
    parameter DEPTH = 256,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,

    parameter DROP_WHEN_FULL = 0
) (
    axis_interface.Sink sink,
    axis_fifo_status_interface sink_status,

    axis_interface.Source source,
    axis_fifo_status_interface source_status
);
    // Wrap the async FIFO in SystemVerilog interface
    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),

        .DROP_WHEN_FULL(DROP_WHEN_FULL)
    ) async_fifo (
        // Setup AXI Stream Input
        .s_clk(sink.clk),
        .s_rst(sink.reset),
        .s_axis_tdata(sink.tdata),
        .s_axis_tkeep(sink.tkeep),
        .s_axis_tvalid(sink.tvalid),
        .s_axis_tready(sink.tready),
        .s_axis_tlast(sink.tlast),
        .s_axis_tid(sink.tid),
        .s_axis_tdest(sink.tdest),
        .s_axis_tuser(sink.tuser),

        .s_status_depth(sink_status.depth),
        .s_status_depth_commit(sink_status.depth_commit),
        .s_status_overflow(sink_status.overflow),
        .s_status_bad_frame(sink_status.bad_frame),
        .s_status_good_frame(sink_status.good_frame),

        // Setup AXI Stream Output
        .m_clk(source.clk),
        .m_rst(source.reset),
        .m_axis_tdata(source.tdata),
        .m_axis_tkeep(source.tkeep),
        .m_axis_tvalid(source.tvalid),
        .m_axis_tready(source.tready),
        .m_axis_tlast(source.tlast),
        .m_axis_tid(source.tid),
        .m_axis_tdest(source.tdest),
        .m_axis_tuser(source.tuser),

        .m_status_depth(source_status.depth),
        .m_status_depth_commit(source_status.depth_commit),
        .m_status_overflow(source_status.overflow),
        .m_status_bad_frame(source_status.bad_frame),
        .m_status_good_frame(source_status.good_frame),

        .s_pause_req(0),
        .s_pause_ack(),

        .m_pause_req(0),
        .m_pause_ack()
    );
endmodule

`default_nettype wire
