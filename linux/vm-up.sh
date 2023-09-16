#!/usr/bin/env bash

pwd="$(dirname "$0")"
# shellcheck source=/dev/null
source "$pwd/jiasuqi.conf"

sysctl -w net.ipv4.ip_forward=1

ip link set dev "$INTERFACE" addr "$MAC_ADDR"
ip link set "$INTERFACE" up

ip addr add "$TAP_IP_ADDR" dev "$INTERFACE"

ip route show default | awk -F' dev ' '{print $2}' | awk '{print $1}' | while read dev; do
    iptables -t nat -A POSTROUTING -s "$TAP_SUBNET" -o "$dev" -j MASQUERADE
    iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -A FORWARD -i "$INTERFACE" -o "$dev" -j ACCEPT
done

