#!/bin/bash
# vim /etc/sysconfig/iptables-config
# iptables-save > /etc/sysconfig/iptables
# iptables-restore > /etc/sysconfig/iptables
# vim /etc/sysconfig/iptables

iptables -t nat -A PREROUTING -d 127.0.0.0/24 -j RETURN
iptables -t nat -A PREROUTING -d 192.168.0.0/16 -j RETURN
iptables -t nat -A PREROUTING -d 10.42.0.0/16 -j RETURN
iptables -t nat -A PREROUTING -d 0.0.0.0/8 -j RETURN
iptables -t nat -A PREROUTING -d 10.0.0.0/8 -j RETURN
iptables -t nat -A PREROUTING -d 172.16.0.0/12 -j RETURN
iptables -t nat -A PREROUTING -d 224.0.0.0/4 -j RETURN
iptables -t nat -A PREROUTING -d 240.0.0.0/4 -j RETURN
iptables -t nat -A PREROUTING -d 169.254.0.0/16 -j RETURN
 
iptables -t nat -A PREROUTING -p tcp -s 10.42.0.0/16 -j REDIRECT --to-ports 51080
# Start the shadowsocks-redir
# ss-server -s 0.0.0.0 -p 52020 -k 91idol.com -u -m chacha20 &
ss-redir -u -s 91idol.com -p 52020 -l 51080 -m chacha20 -k 91idol.com