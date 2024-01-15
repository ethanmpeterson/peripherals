`timescale 1ns / 1ps
`default_nettype none

module peripherals (
    input var logic ext_clk,
    // output var logic blinky,
    // output var logic accel_status_led,

    output var logic ftdi_uart_tx,
    input var logic ftdi_uart_rx,

    // SPI bus accelerometer
    output var logic accel_pmod_cs,
    output var logic accel_pmod_mosi,
    output var logic accel_pmod_sck,

    input var logic accel_pmod_miso,

    // ETH PHY IO
    input var logic eth_col,
    input var logic eth_crs,

    output var logic eth_mdc,
    output var logic eth_mdio,

    output var logic eth_ref_clk,
    output var logic eth_rstn,

    input var logic eth_rx_clk,
    input var logic eth_rx_dv,
    input var logic[3:0] eth_rxd,
    input var logic eth_rxerr,

    input var logic eth_tx_clk,
    output var logic eth_tx_en,
    output var logic[3:0] eth_txd,

    output var logic[3:0] led
);
    assign eth_rstn = 1'b1;
    // Configure PHY clocks generates a 25 MHz clock for the PHY
    eth_phy_clk phy_clk_div (
        // Clock out ports
        .eth_ref_clk(eth_ref_clk),     // output eth_ref_clk
        // Status and control signals
        .reset(1'b0), // input reset
        .locked(),       // output locked
        // Clock in ports
        .ext_clk(ext_clk)      // input ext_clk
    );

    var logic udp_sys_clk;
    udp_clock_generator udp_clock_div (
        // Clock out ports
        .udp_sys_clk(udp_sys_clk),     // output udp_sys_clk
        // Status and control signals
        .reset(1'b0), // input reset
        .locked(),       // output locked
        // Clock in ports
        .ext_clk(ext_clk)      // input ext_clk
    );

    // global reset signal propagated down into all submodules assertion has the
    // effect of resetting the entire design
    var logic system_reset = 0;

    axis_interface internal (
        .clk(ext_clk),
        .reset(system_reset)
    );

    uart arty_ftdi_bridge (
        .tx_stream(cobs_stream.Sink),
        .rx_stream(internal.Source),

        .txd(ftdi_uart_tx),
        .rxd(ftdi_uart_rx)
    );

    axis_interface #(
        .DATA_WIDTH(48),
        .KEEP_ENABLE(1)
    ) accelerometer_data (
        .clk(ext_clk),
        .reset(system_reset)
    );

    spi_interface #(
        .CS_COUNT(1)
    ) accel_spi_bus ();

    // connect the spi signals to FPGA I/O
    assign accel_pmod_cs = accel_spi_bus.cs;
    assign accel_pmod_mosi = accel_spi_bus.mosi;
    assign accel_pmod_sck = accel_spi_bus.sck;

    assign accel_spi_bus.miso = accel_pmod_miso;
    // adxl345 accelerometer (
    //     .configured(accel_status_led),
    //     .reset(system_reset),
    //     .spi_bus(accel_spi_bus.Master),
    //     .accelerometer_data(accelerometer_data)
    // );

    axis_interface #(
        .DATA_WIDTH(8),
        .KEEP_ENABLE(1)
    ) cobs_stream (
        .clk(ext_clk),
        .reset(system_reset)
    );

    axis_adapter_cobs_encoder cobs_encoder (
        .data_stream(accelerometer_data.Sink),
        .cobs_encoded_stream(cobs_stream.Source)
    );

    // AXI between MAC and Ethernet modules
    // var logic [7:0] rx_axis_tdata;
    // var logic rx_axis_tvalid;
    // var logic rx_axis_tready;
    // var logic rx_axis_tlast;
    // var logic rx_axis_tuser;

    // eth_mac_mii_fifo #(
    //     .TARGET("XILINX"),
    //     .CLOCK_INPUT_STYLE("BUFR"),
    //     .ENABLE_PADDING(1),
    //     .MIN_FRAME_LENGTH(64),
    //     .TX_FIFO_DEPTH(4096),
    //     .TX_FRAME_FIFO(1),
    //     .RX_FIFO_DEPTH(4096),
    //     .RX_FRAME_FIFO(1)
    // )
    // eth_mac_inst (
    //     .rst(system_reset),
    //     .logic_clk(eth_ref_clk),
    //     .logic_rst(system_reset),

    //     .tx_axis_tdata(rx_axis_tdata),
    //     .tx_axis_tvalid(rx_axis_tvalid),
    //     .tx_axis_tready(rx_axis_tready),
    //     .tx_axis_tlast(rx_axis_tlast),
    //     .tx_axis_tuser(rx_axis_tuser),

    //     .rx_axis_tdata(rx_axis_tdata),
    //     .rx_axis_tvalid(rx_axis_tvalid),
    //     .rx_axis_tready(rx_axis_tready),
    //     .rx_axis_tlast(rx_axis_tlast),
    //     .rx_axis_tuser(rx_axis_tuser),

    //     .mii_rx_clk(eth_rx_clk),
    //     .mii_rxd(eth_rxd),
    //     .mii_rx_dv(eth_rx_dv),
    //     .mii_rx_er(eth_rxerr),
    //     .mii_tx_clk(eth_tx_clk),
    //     .mii_txd(eth_txd),
    //     .mii_tx_en(eth_tx_en),
    //     .mii_tx_er(),

    //     .tx_fifo_overflow(),
    //     .tx_fifo_bad_frame(),
    //     .tx_fifo_good_frame(),
    //     .rx_error_bad_frame(),
    //     .rx_error_bad_fcs(),
    //     .rx_fifo_overflow(),
    //     .rx_fifo_bad_frame(),
    //     .rx_fifo_good_frame(),

    //     .cfg_ifg(8'd12),
    //     .cfg_tx_enable(1'b1),
    //     .cfg_rx_enable(1'b1)
    // );

    // ila_mii ila_mii_inst (
	  //     .clk(eth_rx_clk), // input wire clk


	  //     .probe0(eth_rxd), // input wire [3:0]  probe0  
	  //     .probe1(eth_rx_dv), // input wire [0:0]  probe1 
	  //     .probe2(eth_rxerr) // input wire [0:0]  probe2
    // );

    // ethernet Mac test instance
    // Use default 8 bit interface

    // axis_interface axis_mii_rx_stream (
    //     .clk(udp_sys_clk),
    //     .reset(system_reset)
    // );

    // axis_interface axis_mii_tx_stream (
    //     .clk(udp_sys_clk),
    //     .reset(system_reset)
    // );

    // axis_interface axis_eth_out (
    //     .clk(udp_sys_clk),
    //     .reset(system_reset)
    // );
    // eth_interface eth_out ();


    // axis_interface axis_eth_in (
    //     .clk(udp_sys_clk),
    //     .reset(system_reset)
    // );
    // eth_interface eth_in ();

    mii_interface mii_signals ();
    always_comb begin
        mii_signals.rx_clk = eth_rx_clk;
        mii_signals.rxd = eth_rxd;
        mii_signals.rx_dv = eth_rx_dv;
        mii_signals.rx_er = eth_rxerr;

        mii_signals.tx_clk = eth_tx_clk;
        eth_txd = mii_signals.txd;
        eth_tx_en = mii_signals.tx_en;
    end

    // udp_tx_example udp_tx_example_inst (
    //     .udp_sys_clk(udp_sys_clk),
    //     .system_reset(system_reset),
    //     .phy_mii(mii_signals)
    // );

    udp_rx_example udp_rx_example_inst (
        .udp_sys_clk(udp_sys_clk),
        .system_reset(system_reset),
        .phy_mii(mii_signals),
        .led(led)
    );

    // udp_echo_example udp_echo_example_inst (
    //     .udp_sys_clk(udp_sys_clk),
    //     .system_reset(system_reset),
    //     .phy_mii(mii_signals)
    // );
endmodule

`default_nettype wire
