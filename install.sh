#!/bin/bash
# vim /etc/sysconfig/iptables-config
# iptables-save > /etc/sysconfig/iptables
# iptables-restore > /etc/sysconfig/iptables
# vim /etc/sysconfig/iptables

bash shadowiptables.sh start
# Start the shadowsocks-redir
# ss-server -s 0.0.0.0 -p 52020 -k 91idol.com -u -m chacha20 &
ss-redir -u -s 91idol.com -p 52020 -l 51080 -m chacha20 -k 91idol.com
bash shadowiptables.sh stop