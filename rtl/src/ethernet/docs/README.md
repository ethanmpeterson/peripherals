# Ethernet Notes and Documentation

Below are my personal notes of useful links and information I am using while I
bring up the TI PHY.

- Checking that your PHY has linked up with the computer.
  https://www.cyberciti.biz/faq/linux-list-network-interfaces-names-command/
- MII Explained https://en.wikipedia.org/wiki/Media-independent_interface
- MDIO explained https://en.wikipedia.org/wiki/Management_Data_Input/Output#Relationship_with_MII
- sending UDP data with socat example `echo packet_data_here | socat -t 10 - udp:192.168.1.128:3000,interface=enp56s0u2c2`
- Check network activity with `nload INTERFACE_NAME`
- Use `nmcli` to list interfaces available
