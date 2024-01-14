`default_nettype none
`timescale 1ns / 1ps

// Groups relevant UDP input / output signals together

interface udp_header_interface ();
    var logic       udp_hdr_valid;
    var logic       udp_hdr_ready;
    var logic[47:0] udp_eth_dest_mac;
    var logic[47:0] udp_eth_src_mac;
    var logic[15:0] udp_eth_type;
    var logic[3:0]  udp_ip_version;
    var logic[3:0]  udp_ip_ihl;
    var logic[5:0]  udp_ip_dscp;
    var logic[1:0]  udp_ip_ecn;
    var logic[15:0] udp_ip_length;
    var logic[15:0] udp_ip_identification;
    var logic[2:0]  udp_ip_flags;
    var logic[12:0] udp_ip_fragment_offset;
    var logic[7:0]  udp_ip_ttl;
    var logic[7:0]  udp_ip_protocol;
    var logic[15:0] udp_ip_header_checksum;
    var logic[31:0] udp_ip_source_ip;
    var logic[31:0] udp_ip_dest_ip;
    var logic[15:0] udp_source_port;
    var logic[15:0] udp_dest_port;
    var logic[15:0] udp_length;
    var logic[15:0] udp_checksum;

    modport Input (
        input   udp_hdr_valid,
        input   udp_eth_dest_mac,
        input   udp_eth_src_mac,
        input   udp_eth_type,
        input   udp_ip_version,
        input   udp_ip_ihl,
        input   udp_ip_identification,
        input   udp_ip_flags,
        input   udp_ip_fragment_offset,
        input   udp_ip_header_checksum,
        input   udp_ip_dscp,
        input   udp_ip_ecn,
        input   udp_ip_ttl,
        input   udp_ip_source_ip,
        input   udp_ip_dest_ip,
        input   udp_source_port,
        input   udp_dest_port,
        input   udp_length,
        input   udp_checksum,

        output  udp_hdr_ready
    );

    modport Output (
        input udp_hdr_ready,

        output udp_hdr_valid,
        output udp_eth_dest_mac,
        output udp_eth_src_mac,
        output udp_eth_type,
        output udp_ip_version,
        output udp_ip_ihl,
        output udp_ip_dscp,
        output udp_ip_ecn,
        output udp_ip_length,
        output udp_ip_identification,
        output udp_ip_flags,
        output udp_ip_fragment_offset,
        output udp_ip_ttl,
        output udp_ip_protocol,
        output udp_ip_header_checksum,
        output udp_ip_source_ip,
        output udp_ip_dest_ip,
        output udp_source_port,
        output udp_dest_port,
        output udp_length,
        output udp_checksum
    );

endinterface

`default_nettype wire
