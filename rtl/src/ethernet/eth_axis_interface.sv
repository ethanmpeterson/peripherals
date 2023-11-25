`default_nettype none
`timescale 1ns / 1ps

interface eth_axis_interface ();
    var logic hdr_valid;
    var logic hdr_ready;

    var logic dest_mac;
    var logic src_mac;

    var logic eth_type;

    var logic tdata;
    var logic tkeep;
    var logic tvalid;
    var logic tready;
    var logic tlast;
    var logic tuser;

    var logic busy;

    modport Sink (
        input hdr_valid, dest_mac, src_mac, eth_type, tdata, tkeep, tvalid, tlast, tuser,
        output hdr_ready, tready
    );

    modport Source (
        output hdr_valid, dest_mac, src_mac, eth_type, tdata, tkeep, tvalid, tlast, tuser,
        input hdr_ready, tready
    );

endinterface

`default_nettype wire
