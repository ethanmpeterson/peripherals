// axis_fifo library module wrapper.
// Wrap the FIFO to use the axis_interface making it easier to interact with.
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

module axis_fifo_wrapper #(
    parameter DEPTH = 256,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH > 8),
    parameter KEEP_WIDTH = (DATA_WIDTH + 7) / 8,
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,

    parameter DROP_WHEN_FULL = 0
) (
    // NOTE: This is a synchronous FIFO. both streams need to share the same
    // clock signal    

    // AXI Stream Input
    axis_interface.Sink sink,
    
    // AXI Stream Output
    axis_interface.Source source,

    // FIFO status interface
    axis_fifo_status_interface status 
);
    axis_fifo #(
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
    ) wrapped_fifo (
        // Shared Clock and Reset Lines
        .clk(sink.clk),
        .rst(sink.reset),

        // Hook up AXI Stream Input
        .s_axis_tdata(sink.tdata),
        .s_axis_tkeep(sink.tkeep),
        .s_axis_tvalid(sink.tvalid),
        .s_axis_tready(sink.tready),
        .s_axis_tlast(sink.tlast),
        .s_axis_tid(sink.tid),
        .s_axis_tdest(sink.tdest),
        .s_axis_tuser(sink.tuser),

        // Hook up AXI Stream Output
        .m_axis_tdata(source.tdata),
        .m_axis_tkeep(source.tkeep),
        .m_axis_tvalid(source.tvalid),
        .m_axis_tready(source.tready),
        .m_axis_tlast(source.tlast),
        .m_axis_tid(source.tid),
        .m_axis_tdest(source.tdest),
        .m_axis_tuser(source.tuser),

        .status_depth(status.depth),
        .status_depth_commit(status.depth_commit),
        .status_overflow(status.overflow),
        .status_bad_frame(status.bad_frame),
        .status_good_frame(status.good_frame)
    );
endmodule

`default_nettype wire
