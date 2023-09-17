`default_nettype none
`timescale 1ns / 1ps

module axis_adapter_wrapper (
    // clocks should be shared between these two interfaces
    axis_interface.Sink sink,
    axis_interface.Source source
);

    axis_adapter #(
        .S_DATA_WIDTH(sink.DATA_WIDTH),
        .S_KEEP_ENABLE(sink.KEEP_ENABLE),
        .S_KEEP_WIDTH(sink.KEEP_WIDTH),

        .M_DATA_WIDTH(source.DATA_WIDTH),
        .M_KEEP_ENABLE(source.KEEP_ENABLE),
        .M_KEEP_WIDTH(source.KEEP_WIDTH),

        .ID_ENABLE(sink.ID_ENABLE),
        .ID_WIDTH(sink.ID_WIDTH),

        .DEST_ENABLE(sink.DEST_ENABLE),
        .DEST_WIDTH(sink.DEST_WIDTH),

        .USER_ENABLE(sink.USER_ENABLE),
        .USER_WIDTH(sink.USER_WIDTH)
    ) width_adpater (
        .clk(sink.clk),
        .rst(sink.reset),

        .s_axis_tdata(sink.tdata),
        .s_axis_tkeep(sink.tkeep),
        .s_axis_tvalid(sink.tvalid),
        .s_axis_tready(sink.tready),
        .s_axis_tlast(sink.tlast),
        .s_axis_tid(sink.tid),
        .s_axis_tdest(sink.tdest),
        .s_axis_tuser(sink.tuser),

        .m_axis_tdata(source.tdata),
        .m_axis_tkeep(source.tkeep),
        .m_axis_tvalid(source.tvalid),
        .m_axis_tready(source.tready),
        .m_axis_tlast(source.tlast),
        .m_axis_tid(source.tid),
        .m_axis_tdest(source.tdest),
        .m_axis_tuser(source.tuser)
    );

endmodule

`default_nettype wire
