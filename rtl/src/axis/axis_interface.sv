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


    var logic [KEEP_WIDTH-1:0]     tkeep;

    var logic                      tvalid;
    var logic                      tready;
    var logic                      tlast;

    var logic   [ID_WIDTH-1:0]     tid;
    var logic   [DEST_WIDTH-1:0]   tdest;
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
