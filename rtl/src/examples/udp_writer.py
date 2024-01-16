# NOTE: This script should be used to test the udp_tx_example module.
# This script will print the byte integer that is sent in a loop by the FPGA

# Modified example from https://wiki.python.org/moin/UdpCommunication
import socket

UDP_IP = "192.168.1.128"
UDP_PORT = 3000

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, 25, str("enp56s0u2u1" + '\0').encode('utf-8'))

sock.sendto(b'A', (UDP_IP, UDP_PORT))
