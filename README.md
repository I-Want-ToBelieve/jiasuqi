## Other

```zsh
git submodule init
git submodule update
```

# 在Linux中通过虚拟机使用Windows版网游加速器

前往 [https://hu60.cn/q.php/bbs.topic.95932.html](https://hu60.cn/q.php/bbs.topic.95932.html) 查看安装使用教程。

该版本库只含在Linux和Windows中使用的脚本、二进制，不含可启动的Windows虚拟机镜像，所以无法单独使用。请前往上面的帖子寻找可启动镜像的下载链接。

安装方法

在最下面，请点击“查看全部”展开全文。
版本库

版本库（不含Windows虚拟机镜像，无法单独使用）：
https://gitee.com/winegame/tproxy-jiasuqi （如果你不是专家，你不需要它）
更新说明
[v0.1.3]

    修复了v1.0.2使用一段时间后会断网的问题，该问题是3proxy的DNS代理功能存在Bug导致的，只要触发，就会不断循环显示解析同一个域名，并且无法再联网。目前的解决方案是由Linux侧直接发起DNS请求，不再使用3proxy的DNS代理功能。
    增加了并发连接数，以前最多只能有100个连接，现在增加到16万个。
    启用加速时自动禁用Linux的IPv6功能，以防游戏走IPv6流量，加速不生效。
    Linux侧对配置文件的修改会自动同步到Windows虚拟机，不再需要进入Windows虚拟机修改3proxy配置文件。

[v0.1.4]

    添加了不代理某些域名的功能，打开~/jiasuqi/linux/jiasuqi.conf就能看到不代理域名列表。
    默认不代理哔哩哔哩、斗鱼、虎牙的直播推流服务器，防止直播卡顿。
    修复了在默认开启防火墙的设备上虚拟机无法联网的问题。
    如果依赖的命令不存在，启动加速器时会给出明确的提示。

升级方法（不是安装方法）
注意，如果你是首次安装，不应该使用升级方法，应该使用下面的安装方法。

命令行操作方法：

# 安装nslookup命令
# 适用于UOS/Deepin/Debian
# 其他发行版请自行想办法安装nslookup命令
command -v nslookup || sudo apt install dnsutils

cd ~

aria2c -x5 -s5 --allow-overwrite -o jiasuqi.tar.xz https://file.winegame.net/jiasuqi/jiasuqi-v0.1.4-without-vm.tar.xz

tar -vxf jiasuqi.tar.xz

安装方法
1. 安装依赖包

UOS/Deepin/Debian：

sudo apt install qemu-system virt-viewer zenity ipset iptables iproute2 dnsutils openssh-client aria2 xz-utils

2. 下载并解压压缩包

通过命令行下载并解压。
下载并解压加速器脚本：

cd ~

aria2c -x5 -s5 --allow-overwrite -o jiasuqi.tar.xz https://file.winegame.net/jiasuqi/jiasuqi-v0.1.4-without-vm.tar.xz

tar -vxf jiasuqi.tar.xz

下载并解压Windows虚拟机镜像：

cd ~/jiasuqi/vm

# 虚拟机镜像有两个版本，任选其一

# 64位版（推荐）
aria2c -x5 -s5 --allow-overwrite -o windows.img.xz https://file.winegame.net/jiasuqi/windows-x64.img.xz

# 32位版（不推荐，不支持某些加速器，如果执行了上面的命令，就不需要执行这一条命令）
#aria2c -x5 -s5 --allow-overwrite -o windows.img.xz https://file.winegame.net/jiasuqi/windows.img.xz

# 执行上面任一命令后，继续执行后续解压操作
echo "正在解压..."

XZ_DEFAULTS="-T 0" xz -d windows.img.xz

文件会解压到你当前用户的主目录（/home/用户名）里，文件夹名称jiasuqi。
解压Windows虚拟机镜像很慢，请耐心等待，如果你想看进度，可以开另一个终端执行以下命令：

watch -n1 ls -lh ~/jiasuqi/vm

3. 启动加速器

进入解压出来的jiasuqi文件夹（在主目录，又名“主文件夹”，又名“Home目录”，不在桌面），双击“启动加速器.sh”，选择“在终端中运行”，然后按提示操作（参考上面的视频）。

如果虚拟机无法联网，请为它配置静态IP：

IP：10.23.45.2
子网前缀长度：24（或者子网掩码：255.255.255.0）
网关：10.23.45.1
首选DNS：114.114.114.114
备用DNS：114.114.115.115

参考教程：https://jingyan.baidu.com/article/63acb44af8602820fcc17e82.html
注意

    刚开始弹出的exe选择框，选择的是要加速的游戏，不是要安装的加速器。你可以在虚拟机内下载、安装加速器，不需要在Linux里下载。

    虚拟机打开后，如果不在里面运行“启动代理.bat”，Linux就无法联网。注意，“启动代理.bat”打开的黑色窗口必须一直开着，关掉它相当于关掉代理，Linux会立即断网！此外，如果用完代理后想恢复Linux正常联网，请给虚拟机关机。

    如果虚拟机无法打开，终端上出现以下错误：

        qemu-system-x86_64: failed to initialize KVM: No such file or directory

    需要在BIOS中打开虚拟化支持，Intel叫做VT-x，AMD叫做SVM或者AMD-v。也有的BIOS直接叫做"Virtualization Technology"（VT）。

    开启方法可参考以下教程：https://blog.csdn.net/weixin_44210782/article/details/104661303

    如果虚拟机经常卡死，可能是内存不足，可以打开jiasuqi/vm-cli.sh文件，然后把-m 2G改成-m 3G或更大。

扩容虚拟机磁盘

如果虚拟机磁盘空间不足，可以用以下方法扩容：

    虚拟机关机。

    打开终端执行命令（把10G改成想要增加的容量）：

qemu-img resize ~/jiasuqi/vm/windows.img +10G

    虚拟机开机，右击“此电脑”，选“管理”，选“计算机管理”，选“磁盘管理”，右击C盘，选“扩展卷”，一直下一步，扩容完成。

已测试的加速器

    迅游：模式2、3、4可用。建议使用模式3（虚拟网卡路由模式），兼容性更好。模式2、4有些游戏不能被加速。
    UU：模式3（虚拟网卡路由模式）可用，游戏可被加速。其他模式似乎无效，虽然能启动，但是游戏不会被加速。

其他加速器未测试，欢迎补充。
已测试的游戏

    《魔兽世界》：与迅游模式4兼容，游戏程序需要选择“_retail_”里的“Wow.exe”（正式服）或者“_classic_”里的“WowClassic.exe”（怀旧服）。
    《守望先锋》：与迅游模式4兼容，游戏程序需要选择“_retail_”里的“Overwatch.exe”，不是外面的“Overwatch Launcher.exe”。
    《英雄联盟》国际服：与迅游模式4兼容，游戏程序需要选择“league-of-legends/drive_c/Riot Games/League of Legends”文件夹里的“LeagueClient.exe”。注意：v1.0.3之前的版本有Bug，无法加速LOL国际服，请升级到v1.0.3后使用。

细节

加速器使用了114 DNS，在jiasuqi/linux/jiasuqi.conf中指定。如果效果不好，你可以换成其他DNS。注意，为了让DNS解析请求被代理，请不要使用内网IP作为DNS（比如192.168.1.1），否则DNS查询流量不会经过加速器，加速可能不会生效。

图片.png

此外，jiasuqi/linux/jiasuqi.conf中指定的DNS只用于Linux侧，Windows侧的DNS是由Windows自己管理的，你可以在网络适配器IPv4属性中修改（教程）。
限制

    只能转发TCP和UDP流量，不能转发ICMP流量，所以如果你手动执行ping命令进行延迟或者可达性测试，结果不会有变化。
    不支持IPv6，IPv6流量不会被转发。如果游戏支持IPv6，为了让加速生效，加速器会暂时关闭Linux中的IPv6功能（重启后可恢复）。
    某些加速器的某些模式（比如UU加速器的模式4）不转发代理的流量，所以加速不会生效，就算我们已经自动把代理程序的文件名改为和游戏同名，也没用。

原理

    在Windows上用3proxy创建socks代理（支持TCP/UDP）和DNS代理。
    为了让加速器对3proxy生效，启动时会把3proxy.exe重命名为游戏的文件名（实际用的是硬连接，相当于复制，但是不额外占用空间）。比如加速魔兽世界时会改为“Wow.exe”（这就是要你选择“要加速的游戏程序”的原因）。这样当在Windows虚拟机里启动“Wow.exe”（实际是“3proxy”）时，加速器就会以为这就是魔兽世界，就会代理它的流量。
    Linux通过源于ss-tproxy的脚本和静态编译的二进制ipt2socks，实现把Linux主动发起的所有TCP/UDP连接全部转发到虚拟机内的3proxy socks代理。此时，对于加速器想转发的流量，加速器就可以转发到自己服务器。对于加速器不转发的流量，就通过虚拟机网络直接发出去。
    修改/etc/resolv.conf，DNS改为虚拟机IP，这样就可以应用加速器修改后的域名解析结果。DNS服务也由3proxy提供。
    Linux侧通过SSH与Windows侧通信。在Windows里运行了微软发布的SSH服务器（https://github.com/powershell/win32-openssh）。
    Windows侧的文件放在“C:\Users\Public\Desktop”文件夹里，与Linux里的windows-x86文件夹内容相同。其中的OpenSSH进行了安装，放置了Linux侧的公钥并修复了权限。
    采用了CPRA_X86FRE_ZH-CN_DREY.iso这个精简版Win10镜像。用32位是因为64位安装后镜像太大，占用的内存也更多。
    压缩包内的vm-cli.sh里有虚拟机启动命令，可以在里面改内存和核数。默认是2GB内存（-m 2G）和2核（-smp 2,sockets=1,cores=2,threads=1，这四个数字分别是当前分配，插槽，核心，线程。目前的数字代表：只有1个CPU插槽sockets=1，插槽里的CPU有2个核心cores=2，每个核心1线程threads=1，也就是不支持超线程，然后把这个CPU中的2核全部分配给虚拟机-smp 2，你可以根据你的CPU实际情况进行调整）。
    顺便一提，之所以要手动双击桌面上的“启动代理.bat”，不通过SSH由Linux侧自动启动，是因为我发现自动启动时加速器的非虚拟网卡模式（就是除了模式3之外的）都不会生效。但是如果手动启动，迅游的模式4就可以生效。
