`default_nettype none
`timescale 1ns / 1ps

module axis_cobs_encode_wrapper (
    // clocks should be shared between these two interfaces
    
    // They must also both be 8-bit streams
    axis_interface.Sink raw_stream,
    axis_interface.Source encoded_stream
);
    axis_cobs_encode encoder (
        .clk(raw_stream.clk),
        .rst(raw_stream.reset),

        .s_axis_tdata(raw_stream.tdata),
        .s_axis_tvalid(raw_stream.tvalid),
        .s_axis_tready(raw_stream.tready),
        .s_axis_tlast(raw_stream.tlast),
        .s_axis_tuser(raw_stream.tuser),

        .m_axis_tdata(encoded_stream.tdata),
        .m_axis_tvalid(encoded_stream.tvalid),
        .m_axis_tready(encoded_stream.tready),
        .m_axis_tlast(encoded_stream.tlast),
        .m_axis_tuser(encoded_stream.tuser)
    );
endmodule

`default_nettype wire
