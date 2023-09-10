`default_nettype none
`timescale 1ns / 1ps

`include "vunit_defines.svh"

module adxl345_tb;


    var logic clk = 0;
    var logic reset = 0;
    always begin
        #10
        clk <= !clk;
    end

    axis_interface accel_data (
        .clk(clk),
        .reset(reset)
    );

    spi_interface spi_bus ();

    adxl345_bfm bfm (
        .spi_bus(spi_bus.Slave)
    );

    var logic configured;
    adxl345 DUT (
        .configured(configured),
        .reset(reset),
        .spi_bus(spi_bus.Master),
        .accelerometer_data(accel_data)
    );

    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            clk = 0;

            accel_data.tdata = 0;
            accel_data.tlast = 1'b1;
            accel_data.tkeep = 1'b1;
            accel_data.tid = 0;
            accel_data.tdest = 0;
            accel_data.tuser = 0;
            accel_data.tvalid = 0;

            accel_data.tready = 1;

        end

        `TEST_CASE("run_accel_state_machine") begin
            automatic int bytes_consumed = 0;
            while (bytes_consumed < 10000) begin
                @(posedge clk) begin
                    bytes_consumed = bytes_consumed + 1;
                end
            end
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire
