// axis_interface definition
// Group AXI Stream signals into single SV Interface
// Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

interface axis_interface #(
    parameter DATA_WIDTH = 8,
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
) (
    input var logic clk,
    input var logic reset
);

    // Data payload of the AXI Stream Packet
    var logic [DATA_WIDTH-1:0] tdata;


    // A way of discarding any null bytes in your stream. Deassert this signal
    // to treat a given word as null data. tkeep is a multi-bit side band signal
    // because you can actually address individual bytes within a word which can
    // be useful
    // tkeep[x] = tdata[(8x + 7):8x]
    var logic [KEEP_WIDTH-1:0]     tkeep;

    // Signal to mark the contents asserted on tdata as valid
    var logic                      tvalid;

    // A consumer will assert tready when it can accept new data
    var logic                      tready;
    
    // Signal to mark the last word in a packet. Ex if you have 8 byte packets,
    // you can assert tlast for the cycle you tx the 8th byte.
    var logic                      tlast;

    // Used to encode an identifier alongside each word of data. This is useful
    // when you are txing your data out of order. tid can be used as ordering
    // information for the final endpoint.
    var logic   [ID_WIDTH-1:0]     tid;
    
    // encodes routing information for the data. Ex. Do I route my UART Rx data
    // to the ethernet PHY or the RS485 XCVR.
    var logic   [DEST_WIDTH-1:0]   tdest;
    
    // a user defined side band signal. Could be used for the source of the
    // transfer or other metadata information.
    var logic   [USER_WIDTH-1:0]   tuser;


    // Employ modports to establish AXI Stream inputs and outputs.
    
    // A source of AXI Stream data. I.e a FIFO output
    modport Source (
        input clk, reset,
        output tdata, tkeep, tvalid, tlast, tid, tdest, tuser,
        input tready
    );

    // A sink of AXI Stream data. I.e a FIFO Input
    modport Sink (
        input clk, reset,
        input tdata, tkeep, tvalid, tlast, tid, tdest, tuser,
        output tready
    );

endinterface // axis_interface

`default_nettype wire
