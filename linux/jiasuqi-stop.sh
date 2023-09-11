#!/usr/bin/env bash

# shellcheck disable=SC2154

proxy_ip="$1"      # socks代理IP
proxy_exe="$2"     # 要代理的exe名称


pwd="$(dirname "$0")"
# shellcheck source=/dev/null
source "$pwd/jiasuqi.conf"


CR=$'\r\n\r'

cat << EOF > /tmp/jiasuqi-stop.bat
@echo off$CR
chcp 65001 > nul$CR
taskkill /F /IM "$proxy_exe"$CR
taskkill /F /IM "tail.exe"$CR
del /F "C:\\Users\\Public\\Desktop\启动代理.bat"$CR
del /F "C:\\Tools\\3proxy\\binlink\\$proxy_exe"$CR
EOF



if "$pwd/wait-for-it.sh" -h "$proxy_ip" -p 22 -t 5; then
    scp -o StrictHostKeyChecking=no -i "$pwd/id_rsa" /tmp/jiasuqi-stop.bat "$windows_user@$proxy_ip:C:\\Tools\\jiasuqi-stop.bat"
    ssh -o StrictHostKeyChecking=no -i "$pwd/id_rsa" "$windows_user@$proxy_ip" "C:\\Tools\\jiasuqi-stop.bat"
else
    echo "虚拟机已关机，不需要停止虚拟机内代理。"
fi


rm /tmp/jiasuqi-stop.bat


ip -4 rule  del   table "$ipts_rt_tab"
ip -4 route flush table "$ipts_rt_tab"


iptables -t mangle -D PREROUTING -j SSTP_PREROUTING
iptables -t mangle -D OUTPUT -j SSTP_OUTPUT
iptables -t nat -D POSTROUTING -j SSTP_POSTROUTING

iptables -t nat -F SSTP_POSTROUTING
iptables -t mangle -F SSTP_OUTPUT
iptables -t mangle -F SSTP_PREROUTING
iptables -t mangle -F SSTP_RULE

iptables -t nat -X SSTP_POSTROUTING
iptables -t mangle -X SSTP_OUTPUT
iptables -t mangle -X SSTP_PREROUTING
iptables -t mangle -X SSTP_RULE


# 如果不延时，ipset -X 会失败
sleep 0.1

ipset -F "$privaddr_setname"
ipset -X "$privaddr_setname"


killall ipt2socks


umount /etc/resolv.conf
rm /tmp/jiasuqi-resolv.conf


# 这个脚本会破坏ss-tproxy的规则，所以顺便停止它
ss-tproxy stop &>/dev/null
ss-tproxy flush-postrule &>/dev/null
ss-tproxy flush-dnscache &>/dev/null


# 结束代理进程
if [ -f /tmp/jiasuqi.pid ]; then
    kill -9 "$(cat /tmp/jiasuqi.pid)"
    rm /tmp/jiasuqi.pid
fi
