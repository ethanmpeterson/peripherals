# NOTE: This script should be used to test the udp_tx_example module.
# This script will print the byte integer that is sent in a loop by the FPGA

# Modified example from https://wiki.python.org/moin/UdpCommunication
import socket

UDP_IP = "192.168.1.127"
UDP_PORT = 3000

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

sock.bind((UDP_IP, UDP_PORT))

while True:
    data, addr = sock.recvfrom(8)
    print("received message: %s, address: %s" % (data, addr))

