`default_nettype none
`timescale 1ns / 1ps

module axis_adapter_cobs_encoder (
    // clocks should be shared between these two interfaces
    
    // They must also both be 8-bit streams
    axis_interface.Sink data_stream,
    axis_interface.Source cobs_encoded_stream
);
    axis_interface #(
        .DATA_WIDTH(8)
    ) byte_stream (
        .clk(data_stream.clk),
        .reset(data_stream.reset)
    );

    axis_adapter_wrapper stream_width_adapter (
        .sink(data_stream),
        .source(byte_stream.Source)
    );

    axis_cobs_encode_wrapper cobs_encoder (
        .raw_stream(byte_stream.Sink),
        .encoded_stream(cobs_encoded_stream)
    );

endmodule

`default_nettype wire
