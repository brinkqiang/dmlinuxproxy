#!/bin/bash
# china_ip_list.txt from https://github.com/17mon/china_ip_list

chnroute_file=~/china_ip_list/china_ip_list.txt
ignore_ips=(
	0.0.0.0/8
	10.0.0.0/8
	17.0.0.0/8
	100.64.0.0/10
	127.0.0.0/8
	169.254.0.0/16
	172.16.0.0/12
	192.168.0.0/16
	224.0.0.0/4
	240.0.0.0/4
	203.205.128.0/18
)
src_addr=47.75.48.245/24
local_port=51080

update(){
	if pushd ~/china_ip_list; then git pull; else git clone https://github.com/17mon/china_ip_list ~/china_ip_list; fi
        popd
}

start_rule(){
	check_for_update
	iptables -t nat -C OUTPUT -p tcp -s $src_addr -j SHADOWTABLES >& /dev/null \
		|| iptables -t nat -A OUTPUT -p tcp -s $src_addr -j SHADOWTABLES
	# Add any UDP rules
	#ip route add local default dev lo table 100
	#ip rule add fwmark 1 lookup 100
	#iptables -t mangle -A SHADOWSOCKS -p udp --dport 53 -j TPROXY --on-port $local_port --tproxy-mark 0x01/0x01
}

apply_redir(){
	iptables -t nat -C PREROUTING -p tcp -s $src_addr -j SHADOWTABLES >& /dev/null \
		|| iptables -t nat -A PREROUTING -p tcp -s $src_addr -j SHADOWTABLES
}

stop_rule(){
	iptables -t nat -C OUTPUT -p tcp -s $src_addr -j SHADOWTABLES >& /dev/null \
		&& iptables -t nat -D OUTPUT -p tcp -s $src_addr -j SHADOWTABLES
}

add_tables(){

	iptables -t nat -N SHADOWTABLES >& /dev/null

	#for ip in ${ignore_ips[@]} ;do
	#	iptables -t nat -C SHADOWTABLES -s $src_addr -d $ip -j RETURN >& /dev/null \
	#		|| iptables -t nat -I SHADOWTABLES 1 -s $src_addr -d $ip -j RETURN
	#done

	ipset create chnroute hash:net -exist
	while IFS='' read -r ip || [[ -n "$ip" ]]; do
    		ipset add chnroute $ip -exist
	done < "$chnroute_file"
	
	for ip in ${ignore_ips[@]}; do
		ipset add chnroute $ip -exist
	done

	iptables -t nat -C SHADOWTABLES -s $src_addr -m set --match-set chnroute dst -j RETURN >& /dev/null \
		|| iptables -t nat -A SHADOWTABLES -s $src_addr -m set --match-set chnroute dst -j RETURN

	iptables -t nat -C SHADOWTABLES -p tcp -s $src_addr -j REDIRECT --to-ports $local_port >& /dev/null \
		|| iptables -t nat -A SHADOWTABLES -p tcp -s $src_addr -j REDIRECT --to-ports $local_port

}

check_for_update(){
	if [[ -r $chnroute_file ]]; then
	  current=`date +%s`
	  last_modified=`stat -c "%Y" $chnroute_file`
	  if [[ $(($current-$last_modified)) -gt 604800 ]]; then
	    if ping -q -c 1 -W 1 github.com >/dev/null; then
	      update
	    fi
	  fi
	else
	  update
	fi
}


case $1 in
	update_ip_list)
		update
		;;
		
	stop)
		stop_rule
		;;

	start|*)
		add_tables
		start_rule
		apply_redir
		;;

	apply)
		start_rule
		;;

	add_rule)
		add_tables
		;;
	restart)
		stop_rule
		add_tables
		start_rule
		;;

esac

