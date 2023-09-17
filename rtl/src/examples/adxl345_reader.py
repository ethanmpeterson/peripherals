# Quick and dirty script to dump adxl345 data reported over serial
import serial
from cobs import cobs
import struct

ser = serial.Serial('/dev/ttyUSB1', 115200)

leading_zero = False
while True:
    byte_read = ser.read(1)
    stream_data = bytes()
    if byte_read == b'\x00':
        stream_data = ser.read(7)
        if stream_data[0] == 7:
            decoded_accel_bytes = cobs.decode(stream_data)

            # Use this template to decode the data based off your configured
            # offset and data format
            accel_x_bytes = bytes(decoded_accel_bytes[0:2])
            accel_y_bytes = bytes(decoded_accel_bytes[2:4])
            accel_z_bytes = bytes(decoded_accel_bytes[4:6])