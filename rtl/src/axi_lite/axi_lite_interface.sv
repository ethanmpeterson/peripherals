`default_nettype none
`timescale 1ns / 1ps

interface axi_lite_interface #(
    parameter READ_ADDRESS_WIDTH = 8,
    parameter READ_DATA_WIDTH = 8,

    parameter WRITE_ADDRESS_WIDTH = 8,
    parameter WRITE_DATA_WIDTH = 8,

    parameter WRITE_RESPONSE_WIDTH = 8
) (
    input var logic clk,
    input var logic reset
);

    localparam STROBE_WIDTH = WRITE_DATA_WIDTH / 8;

    // Address read signals
    var logic[READ_ADDRESS_WIDTH-1:0] araddr;
    var logic[2:0] arprot;

    var logic arvalid;
    var logic arready;

    // Read data channel
    var logic[READ_DATA_WIDTH-1:0] rdata;
    var logic[1:0] rresp;
    var logic rvalid;
    var logic rready;

    // Address write signals
    var logic[WRITE_ADDRESS_WIDTH-1:0] awaddr;
    var logic[2:0] awprot;
    var logic awvalid;
    var logic awready;

    // Write data channel
    var logic[WRITE_DATA_WIDTH-1:0] wdata;
    var logic[STROBE_WIDTH-1:0] wstrb;

    // Write response channel
    var logic[1:0] bresp;
    var logic bvalid;
    var logic bready;

endinterface // axi_lite_interface

`default_nettype wire
