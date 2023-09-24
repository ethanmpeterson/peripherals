`default_nettype none
`timescale 1ns / 1ps

interface eth_mac_status_interface ();
    var logic ifg;
    var logic tx_enable;
    var logic rx_enable;
endinterface

`default_nettype wire
