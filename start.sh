#!/usr/bin/env bash

pwd="$(realpath "$(dirname "$0")")"

# shellcheck source=/dev/null
source "$pwd/linux/jiasuqi.conf"

echo "$pwd"

############################### 判断依赖包是否安装 ###############################

depend_bins=(
    qemu-system-x86_64 remote-viewer ipset iptables ip nslookup ssh aria2c
)

zenity_version=$(zenity --version 2> /dev/null)

if [ "$zenity_version" = "" ]; then
    echo
    echo ===================================================================
    echo "你没有安装zenity，无法显示图形界面，将使用命令行界面。"
    echo "可以通过软件包管理器安装zenity，如 sudo apt install zenity"
    echo "不同发行版命令不同。"
    echo ===================================================================
    echo

    for depend_bin in "${depend_bins[@]}"; do
        if ! command -v "$depend_bin"; then
            echo "找不到 $depend_bin 命令，请按教程安装依赖包。"
            exit
        fi
    done

    exec "$pwd/jiasuqi-cli.sh"
    exit
fi

for depend_bin in "${depend_bins[@]}"; do
    if ! command -v "$depend_bin"; then
        zenity --info --text="找不到 $depend_bin 命令，请按教程安装依赖包。" --width=600 2> /dev/null
        exit
    fi
done

############################### 选择要加速的文件 ###############################

exe_name=""

text=$(
    cat <<END_HEREDOC
请在弹出的对话框中选择要加速的游戏程序（如Wow.exe）。

注意：应该选择实际游戏进程（比如Wow.exe），
不是游戏启动器（比如Battle.net.exe）。

如果游戏程序选错，加速可能不会生效。
END_HEREDOC
)

exe_name=$(cat /tmp/jiasuqi-file.txt)
zenity --info --text="$text" --width=600 2> /dev/null

if ! exe_name=$(zenity --file-selection --filename="$exe_name" --title="选择要加速的游戏程序" --file-filter="要加速的游戏程序 (*.exe) | *.exe *.EXE" 2> /dev/null); then
    zenity --info --text="您未选择要加速的游戏程序，加速器无法启动。" --width=500 2> /dev/null
    exit
fi

echo "$exe_name" >/tmp/jiasuqi-file.txt

exe_name="$(basename "$exe_name")"

############################### 启动虚拟机 ###############################

text=$(
    cat <<END_HEREDOC
即将加速 $exe_name
为保证加速效果，Linux上的IPv6功能将被暂时关闭，重启后可恢复。

请等待虚拟机开机并进入桌面，然后启动网游加速器，
加速你选择的游戏，然后双击桌面上的"启动代理.bat".

如果”启动代理.bat“没有出现，请尝试双击桌面上的"重启SSH服务.bat"/

注意：在你双击桌面上的“启动代理.bat”之前，你的Linux系统将无法上网，
只有Windows虚拟机可以上网。

要停止加速器，请给Win10虚拟机关机，或者在Linux终端里按Ctrl+C.
END_HEREDOC
)

zenity --info --text="$text" --width=700 2> /dev/null

echo
echo ===================================================================
echo

export SUDO_ASKPASS="$pwd/linux/askpass.sh"

echo "获取root权限……"
sudo -A echo "获取root权限成功" || {
    zenity --info --text="sudo密码错误，加速器无法启动" --width=300 2> /dev/null
    exit
}

echo
echo ===================================================================
echo

echo "启动虚拟机……"
"$pwd/vm-cli.sh" &

echo
echo ===================================================================
echo

echo "等待虚拟机SSH服务启动……"
"$pwd/linux/wait-for-it.sh" -h "$VM_IP_ADDR" -p 22 -t 0

echo
echo ===================================================================
echo

echo "初始化代理……"
sudo -A "$pwd/linux/jiasuqi" "$VM_IP_ADDR" "$exe_name" || {
    zenity --info --text="sudo密码错误，加速器无法启动" --width=300 2> /dev/null
    exit
}

zenity --info --text="代理已停止" --width=100 2> /dev/null
