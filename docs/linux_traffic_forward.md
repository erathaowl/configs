## Traffic Forwarding in ubuntu 20

On the Linux system you intend to use as a router, determine if IPv4 forwarding is currently enabled or disabled. The command below outputs the value of the given parameter. A value of 1 indicates that the setting is enabled, while 0 indicates it is disabled.

` sudo sysctl net.ipv4.ip_forward `

the expected result is:

` net.ipv4.ip_forward = 0 `

edit the sysctl.conf file:

` sudo nano /etc/sysctl.conf `

Find the line corresponding with the type of forwarding you wish to enable, uncomment it, and set the value to 1.
Then run (or reboot the system):
---

` sudo sysctl -p `

Install iptables permanent package:

` sudo apt install iptables-permanent `

Check actual iptables rules:

` sudo iptables -L `

Configure the utility to allow traffic forwarding, specify only your current lan addresses as allowed sources:

` sudo iptables -A FORWARD -j ACCEPT -s 192.168.0.0/24 `

Configure NAT (network address translation) within the utility. This modifies the IP address details in network packets, allowing all systems on the private network to share the same public IP address of the router. Replace 192.168.0.0/24 in the following command with the subnet of your private VLAN.

` sudo iptables -t nat -s 192.168.0.0/24 -A POSTROUTING -j MASQUERADE `

