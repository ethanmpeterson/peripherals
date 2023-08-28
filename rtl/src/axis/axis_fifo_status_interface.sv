// axis fifo status interface definition

// Group AXI FIFO status signals into a single interface we can read from when
// needed

//Ethan Peterson 2023

`default_nettype none
`timescale 1ns / 1ps

interface axis_fifo_status_interface #(
    parameter DEPTH = 256
) ();
    var logic [$clog2(DEPTH):0] depth;
    var logic [$clog2(DEPTH):0] depth_commit;
    var logic                   overflow;
    var logic                   bad_frame;
    var logic                   good_frame;
endinterface // axis_fifo_status_interface

`default_nettype wire
