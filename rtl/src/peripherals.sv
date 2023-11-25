`timescale 1ns / 1ps
`default_nettype none

module peripherals (
    input var logic ext_clk,
    output var logic blinky,
    output var logic accel_status_led,

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
    output var logic[3:0] eth_txd
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
    adxl345 accelerometer (
        .configured(accel_status_led),
        .reset(system_reset),
        .spi_bus(accel_spi_bus.Master),
        .accelerometer_data(accelerometer_data)
    );

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

    // ethernet Mac test instance
    // Use default 8 bit interface
    axis_interface #(
        .DATA_WIDTH(8),
        .KEEP_ENABLE(1)
    ) eth_mac_sink (
        .clk(ext_clk),
        .reset(system_reset)
    );

    var logic [7:0] counter = 0;
    always @(posedge ext_clk) begin
        eth_mac_sink.tvalid <= 1'b1;
        eth_mac_sink.tdata <= counter;
        if (eth_mac_sink.tready && eth_mac_sink.tvalid) begin
            counter <= counter + 1;
        end
    end

    axis_interface #(
        .DATA_WIDTH(8),
        .KEEP_ENABLE(1)
    ) eth_mac_src (
        .clk(ext_clk),
        .reset(system_reset)
    );

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

    eth_mac_cfg_interface mac_config ();
    eth_mac_status_interface mac_status ();
    eth_mac_mii_fifo_wrapper eth_ti_phy_mac (
        .sink(eth_mac_sink),
        .source(eth_mac_src),
        .phy_mii(mii_signals.Mac),
        .status(mac_status),
        .cfg(mac_config)
    );

endmodule

`default_nettype wire
