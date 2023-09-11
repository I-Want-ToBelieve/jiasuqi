#!/usr/bin/env bash

pwd="$(dirname "$0")"
source "$pwd/jiasuqi.conf"

ip route show default | awk -F' dev ' '{print $2}' | awk '{print $1}' | while read dev; do
    iptables -t nat -D POSTROUTING -s "$TAP_SUBNET" -o "$dev" -j MASQUERADE
    iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -D FORWARD -i "$INTERFACE" -o "$dev" -j ACCEPT
done

ip link set "$INTERFACE" down

# 结束代理进程
kill -9 $(cat /tmp/jiasuqi.pid)
rm /tmp/jiasuqi.pid
