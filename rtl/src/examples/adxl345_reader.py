# Quick and dirty script to dump adxl345 data reported over serial
import serial

ser = serial.Serial('/dev/ttyUSB1', 115200)

while True:
    print(int.from_bytes(ser.read(1), "big"))

