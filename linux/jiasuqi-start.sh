#!/usr/bin/env bash

# shellcheck disable=SC2154

proxy_ip="$1"      # socks代理IP
proxy_exe="$2"     # 要代理的exe名称


pwd="$(dirname "$0")"
# shellcheck source=/dev/null
source "$pwd/jiasuqi.conf"


# 停止先前启动的加速器
"$pwd/jiasuqi-stop.sh" &>/dev/null


# 启动iptables转socks代理进程
nohup "$pwd/ipt2socks" --server-addr "$proxy_ip" --server-port "$proxy_port" --listen-addr4 "$ipt2socks_ip" --listen-port "$ipt2socks_port" &>/var/log/ipt2socks.log &


# 修改DNS
touch /etc/resolv.conf
echo "nameserver $DNS_SERVER1" >/tmp/jiasuqi-resolv.conf
echo "nameserver $DNS_SERVER2" >>/tmp/jiasuqi-resolv.conf
mount --bind /tmp/jiasuqi-resolv.conf /etc/resolv.conf


# 关闭IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1


ipset -N "$privaddr_setname" hash:net family inet

echo "不代理域名:"
for bypass_domain in "${bypass_domain_array[@]}"; do
    echo "$bypass_domain" >/dev/stderr
    nslookup -type=A "$bypass_domain" | awk '/^Address: / { print "-A '"$privaddr_setname"' " $2 }' | tee /dev/stderr
done | ipset -R -exist

echo "不代理网段:"
for privaddr in "${privaddr_array[@]}"; do
    echo "-A $privaddr_setname $privaddr" | tee /dev/stderr
done | ipset -R -exist


iptables -t mangle -N SSTP_RULE
iptables -t mangle -A SSTP_RULE -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff
iptables -t mangle -A SSTP_RULE -m mark --mark "$ipts_rt_mark" -j RETURN
iptables -t mangle -A SSTP_RULE -d "$proxy_ip" -p tcp -j RETURN
iptables -t mangle -A SSTP_RULE -m set --match-set "$privaddr_setname" dst -j RETURN
iptables -t mangle -A SSTP_RULE -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j MARK --set-xmark "$ipts_rt_mark"/0xffffffff
iptables -t mangle -A SSTP_RULE -p udp -m conntrack --ctstate NEW -j MARK --set-xmark "$ipts_rt_mark"/0xffffffff
iptables -t mangle -A SSTP_RULE -j CONNMARK --save-mark --nfmask 0xffffffff --ctmask 0xffffffff

iptables -t mangle -N SSTP_OUTPUT
iptables -t mangle -A SSTP_OUTPUT -p tcp -m addrtype --src-type LOCAL ! --dst-type LOCAL -j SSTP_RULE
iptables -t mangle -A SSTP_OUTPUT -p udp -m addrtype --src-type LOCAL ! --dst-type LOCAL -j SSTP_RULE

iptables -t mangle -N SSTP_PREROUTING
iptables -t mangle -A SSTP_PREROUTING -i "$ipts_if_lo" -m mark ! --mark "$ipts_rt_mark" -j RETURN
iptables -t mangle -A SSTP_PREROUTING -p tcp -m mark --mark "$ipts_rt_mark" -j TPROXY --on-port "$ipt2socks_port" --on-ip "$ipt2socks_ip" --tproxy-mark 0x0/0x0
iptables -t mangle -A SSTP_PREROUTING -p udp -m mark --mark "$ipts_rt_mark" -j TPROXY --on-port "$ipt2socks_port" --on-ip "$ipt2socks_ip" --tproxy-mark 0x0/0x0

iptables -t nat -N SSTP_POSTROUTING
iptables -t nat -A SSTP_POSTROUTING -m addrtype ! --src-type LOCAL -m conntrack --ctstate SNAT,DNAT -j RETURN
iptables -t nat -A SSTP_POSTROUTING -p tcp -m addrtype ! --src-type LOCAL -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j MASQUERADE
iptables -t nat -A SSTP_POSTROUTING -p udp -m addrtype ! --src-type LOCAL -m conntrack --ctstate NEW -j MASQUERADE
iptables -t nat -A SSTP_POSTROUTING -p icmp -m addrtype ! --src-type LOCAL -m conntrack --ctstate NEW -j MASQUERADE

iptables -t mangle -A PREROUTING -j SSTP_PREROUTING
iptables -t mangle -A OUTPUT -j SSTP_OUTPUT
iptables -t nat -A POSTROUTING -j SSTP_POSTROUTING


ip -4 route add local default dev "$ipts_if_lo" table "$ipts_rt_tab"
ip -4 rule add fwmark "$ipts_rt_mark" table "$ipts_rt_tab"


CR=$'\r\n\r'

cat << EOF > /tmp/jiasuqi-init.bat
@echo off$CR
chcp 65001 > nul$CR
DEL /F "C:\\Tools\\3proxy\\binlink\\$proxy_exe"
mklink /H "C:\\Tools\\3proxy\\binlink\\$proxy_exe" "C:\\Tools\\3proxy\\bin\\3proxy.exe"$CR
echo 请在Windows中启动加速器，然后双击桌面上的"启动代理.bat"。 > "C:\\Tools\\3proxy\\log\\3proxy.log"$CR
echo 要停止代理，请按Ctrl+C，或者直接给Win10虚拟机关机。 >> "C:\\Tools\\3proxy\\log\\3proxy.log"$CR
EOF

cat << EOF > /tmp/jiasuqi-run.bat
@echo off$CR
chcp 65001 > nul$CR
echo 代理已启动，请不要关闭本窗口，否则Linux会断网。$CR
echo 如果加速器启动加速后没有生效，请关闭本窗口并双击"启动代理.bat"。$CR
echo 要停止代理，请直接给Win10虚拟机关机，或者在Linux终端里按Ctrl+C。$CR
echo 代理已启动。要停止代理，请直接给Win10虚拟机关机，或者在此终端按Ctrl+C。 >> "C:\\Tools\\3proxy\\log\\3proxy.log"$CR
"C:\\Tools\\3proxy\\binlink\\$proxy_exe" "C:\\Tools\\3proxy\\cfg\\3proxy.cfg"$CR
TASKKILL /IM "$proxy_exe"
DEL
EOF

# 判断Windows是32位的还是64位的
windows_arch=$(ssh -o StrictHostKeyChecking=no -i "$pwd/id_rsa" "$windows_user@$proxy_ip" echo "%PROCESSOR_ARCHITECTURE%")
if [ "$windows_arch" == "*64*" ]; then
    windows_arch="x64"
else
    windows_arch="x86"
fi

# 创建文件夹
ssh -o StrictHostKeyChecking=no -i "$pwd/id_rsa" "$windows_user@$proxy_ip" MD "C:\\Tools"

# 拷贝二进制和配置文件
scp -o StrictHostKeyChecking=no -i "$pwd/id_rsa" -r \
    "$pwd/../windows-$windows_arch/3proxy/" \
    "$pwd/../windows-$windows_arch/tail/" \
    "$windows_user@$proxy_ip:C:\\Tools\\"

# 拷贝启动脚本
scp -o StrictHostKeyChecking=no -i "$pwd/id_rsa" /tmp/jiasuqi-init.bat "$windows_user@$proxy_ip:C:\\Tools\\jiasuqi-init.bat"
scp -o StrictHostKeyChecking=no -i "$pwd/id_rsa" /tmp/jiasuqi-run.bat "$windows_user@$proxy_ip:C:\\Users\\Public\\Desktop\启动代理.bat"

rm /tmp/jiasuqi-init.bat /tmp/jiasuqi-run.bat

ssh -o StrictHostKeyChecking=no -i "$pwd/id_rsa" "$windows_user@$proxy_ip" "C:\\Tools\\jiasuqi-init.bat"

echo $$ > /tmp/jiasuqi.pid

exec ssh -o StrictHostKeyChecking=no -i "$pwd/id_rsa" "$windows_user@$proxy_ip" "C:\\Tools\\tail\\tail.exe" -f "C:\\Tools\\3proxy\\log\\3proxy.log"
