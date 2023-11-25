`default_nettype none
`timescale 1ns / 1ps

interface eth_mac_cfg_interface ();
    var logic ifg = 8'd12;
    var logic tx_enable = 1'b1;
    var logic rx_enable = 1'b1;
endinterface

`default_nettype wire
