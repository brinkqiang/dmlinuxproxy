#!/bin/bash
#自动翻墙脚本，配合shadowsocks-libev的ss-redir使用。需要ipset
chnroute_file=~/.chnroute
ignore_ips=(
	45.32.50.160
	45.127.93.239
	103.214.68.175
	0.0.0.0/8
	10.0.0.0/8
	127.0.0.0/8
	169.254.0.0/16
	172.16.0.0/12
	192.168.0.0/16
	224.0.0.0/4
	240.0.0.0/4
	45.125.195.43
	46.8.255.210
	23.88.239.57
	103.217.253.73
	198.98.125.36
)
local_port=1080

update(){
  curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $chnroute_file
  echo "127.0.0.1/24" >> $chnroute_file
}

start_rule(){
	check_for_update
	sudo iptables -t nat -C OUTPUT -p tcp -j SHADOWTABLES >& /dev/null \
		|| sudo iptables -t nat -A OUTPUT -p tcp -j SHADOWTABLES
}

apply_redir(){
	sudo iptables -t nat -C PREROUTING -p tcp -j SHADOWTABLES >& /dev/null \
		|| sudo iptables -t nat -A PREROUTING -p tcp -j SHADOWTABLES
}

stop_rule(){
	sudo iptables -t nat -C OUTPUT -p tcp -j SHADOWTABLES >& /dev/null \
		&& sudo iptables -t nat -D OUTPUT -p tcp -j SHADOWTABLES
}

add_tables(){

	sudo iptables -t nat -N SHADOWTABLES >& /dev/null

	for ip in ${ignore_ips[@]} ;do
		sudo iptables -t nat -C SHADOWTABLES -d $ip -j RETURN >& /dev/null \
			|| sudo iptables -t nat -I SHADOWTABLES 1 -d $ip -j RETURN
	done

	sudo ipset create chnroute hash:net -exist
	cat $chnroute_file | sudo xargs -I ip ipset add chnroute ip -exist

	sudo iptables -t nat -C SHADOWTABLES -m set --match-set chnroute dst -j RETURN >& /dev/null \
		|| sudo iptables -t nat -A SHADOWTABLES -m set --match-set chnroute dst -j RETURN

	sudo iptables -t nat -C SHADOWTABLES -p tcp -j REDIRECT --to-ports $local_port >& /dev/null \
		|| sudo iptables -t nat -A SHADOWTABLES -p tcp -j REDIRECT --to-ports $local_port

}

check_for_update(){
	if [[ -r $chnroute_file ]]; then
	  current=`date +%s`
	  last_modified=`stat -c "%Y" $chnroute_file`
	  if [[ $(($current-$last_modified)) -gt 604800 ]]; then
	    if ping -q -c 1 -W 1 ftp.apnic.net >/dev/null; then
	      update
	    fi
	  fi
	else
	  update
	fi
}


case $1 in

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

