`default_nettype none
`timescale 1ns / 1ps

interface eth_mac_status_interface ();
    var logic tx_error_underflow;
    var logic tx_fifo_overflow;
    var logic tx_fifo_bad_frame;
    var logic tx_fifo_good_frame;
    var logic rx_error_bad_frame;
    var logic rx_error_bad_fcs;
    var logic rx_fifo_overflow;
    var logic rx_fifo_bad_frame;
    var logic rx_fifo_good_frame;
endinterface

`default_nettype wire
