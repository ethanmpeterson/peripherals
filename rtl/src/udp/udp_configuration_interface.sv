`default_nettype none
`timescale 1ns / 1ps

// captures IP configuration data. Defaults are specified. Welcome to override as required

interface udp_configuration_interface ();

    var logic [47:0] local_mac = 48'h02_00_00_00_00_00;
    var logic [31:0] local_ip = {8'd192, 8'd168, 8'd1,   8'd128};
    var logic [31:0] gateway_ip = {8'd192, 8'd168, 8'd1,   8'd1};
    var logic [31:0] subnet_mask = {8'd255, 8'd255, 8'd255, 8'd0};

endinterface

`default_nettype wire
