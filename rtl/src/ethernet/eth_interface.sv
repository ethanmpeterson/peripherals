`default_nettype none
`timescale 1ns / 1ps

interface eth_interface ();
    var logic hdr_valid;
    var logic hdr_ready;

    var logic[47:0] dest_mac;
    var logic[47:0] src_mac;

    var logic[15:0] eth_type;

    modport Sink (
        input hdr_valid, dest_mac, src_mac, eth_type,
        output hdr_ready
    );

    modport Source (
        output hdr_valid, dest_mac, src_mac, eth_type,
        input hdr_ready
    );

endinterface

`default_nettype wire

