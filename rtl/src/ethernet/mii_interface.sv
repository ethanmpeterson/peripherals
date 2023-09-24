`default_nettype none
`timescale 1ns / 1ps

interface mii_interface ();
    var logic rx_clk;
    var logic rxd;
    var logic rx_dv;
    var logic rx_er;

    var logic tx_clk;
    var logic txd;
    var logic tx_en;
    var logic tx_er;

    modport Mac (
        input rx_clk, rxd, rx_dv, rx_er, tx_clk,
        output txd, tx_en, tx_er
    );

    modport Phy (
        input txd, tx_en, tx_er,
        output rx_clk, rxd, rx_dv, rx_er, tx_clk
    );

endinterface

`default_nettype wire
