#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# Description: Auto test download & I/O speed script
# Edit Revision VPS.BEST Teddysun <i@teddysun.com>
# Copyright (C) 2024 Puck

RED='\033[0;31m' && GREEN='\033[0;32m' && YELLOW='\033[0;33m' && PLAIN='\033[0m'
next() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }
get_opsy() {
	[[ -f /etc/redhat-release ]] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
	[[ -f /etc/os-release ]] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
	[[ -f /etc/lsb-release ]] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=$(uname -m)
}
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		yum update
		yum -y install mtr curl time virt-what
		[[ ${action} == "a" ]] && yum -y install make gcc gcc-c++ gdbautomake autoconf
	else
		apt-get update
		apt-get -y install curl mtr time virt-what
		[[ ${action} == "a" ]] && apt-get -y install make gcc gdb automake autoconf
	fi
}
get_info(){
	logfile="test.log"
	IP=$(curl -s myip.ipip.net | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
	IPaddr=$(curl -s myip.ipip.net | awk -F '：' '{print $3}')
	if [[ -z "$IP" ]]; then
		IP=$(curl -s ip.cn | awk -F ' ' '{print $2}' | awk -F '：' '{print $2}')
		IPaddr=$(curl -s ip.cn | awk -F '：' '{print $3}')	
	fi
	time=$(date '+%Y-%m-%d %H:%I:%S')
	backtime=$(date +%Y-%m-%d)
	vm=$(virt-what)
	[[ -z ${vm} ]] && vm="none"
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )
	ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
	disk_size1=($( LANG=C df -ahPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' ))
	disk_size2=($( LANG=C df -ahPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' ))
	disk_total_size=$( calc_disk ${disk_size1[@]} )
	disk_used_size=$( calc_disk ${disk_size2[@]} )
}
system_info(){
	clear
	echo "========== 开始记录测试信息 ==========" > $logfile
	echo "测试时间：$time" | tee -a $logfile
	next | tee -a $logfile
	echo "CPU model            : $cname" | tee -a $logfile
	echo "Number of cores      : $cores" | tee -a $logfile
	echo "CPU frequency        : $freq MHz" | tee -a $logfile
	echo "Total size of Disk   : $disk_total_size GB ($disk_used_size GB Used)" | tee -a $logfile
	echo "Total amount of Mem  : $tram MB ($uram MB Used)" | tee -a $logfile
	echo "Total amount of Swap : $swap MB ($uswap MB Used)" | tee -a $logfile
	echo "System uptime        : $up" | tee -a $logfile
	echo "Load average         : $load" | tee -a $logfile
	echo "OS                   : $opsy" | tee -a $logfile
	echo "Arch                 : $arch ($lbit Bit)" | tee -a $logfile
	echo "Kernel               : $kern" | tee -a $logfile
	echo "ip                   : $IP" | tee -a $logfilename
	echo "ipaddr               : $IPaddr" | tee -a $logfilename
	echo "vm                   : $vm" | tee -a $logfilename
	next | tee -a $logfile
}
calc_disk() {
	local total_size=0
	local array=$@
	for size in ${array[@]}
	do
		[[ "${size}" == "0" ]] && size_t=0 || size_t=$(echo ${size:0:${#size}-1})
		[[ "$(echo ${size:(-1)})" == "M" ]] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
		[[ "$(echo ${size:(-1)})" == "T" ]] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
		[[ "$(echo ${size:(-1)})" == "G" ]] && size=${size_t}
		total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
	done
	echo ${total_size}
}
io_test_1() {
	(LANG=C dd if=/dev/zero of=test_$$ bs=64k count=4k oflag=dsync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
io_test_2() {
	(LANG=C dd if=/dev/zero of=test_$$ bs=8 count=256 conv=fdatasync && rm -f test_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
io_test(){
	io1=$( $1 )
	echo "I/O speed(1st run)   : $io1" | tee -a $logfile
	io2=$( $1 )
	echo "I/O speed(2nd run)   : $io2" | tee -a $logfile
	io3=$( $1 )
	echo "I/O speed(3rd run)   : $io3" | tee -a $logfile
	ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
	[[ "$(echo $io1 | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
	ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
	[[ "$(echo $io2 | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
	ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
	[[ "$(echo $io3 | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
	ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
	ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
	echo "Average I/O speed    : $ioavg MB/s" | tee -a $logfile
	next | tee -a $logfile
}
speed_test() {
	local speedtest=$(wget -4O /dev/null -T300 $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
	local ipaddress=$(ping -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
	local nodeName=$2
	printf "${YELLOW}%-32s${GREEN}%-24s${RED}%-14s${PLAIN}\n" "${nodeName}:" "${ipaddress}:" "${speedtest}"
}
speed() {
	printf "%-32s%-24s%-14s\n" "Node Name:" "IPv4 address:" "Download Speed"
# speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly'
	speed_test 'https://speed.cloudflare.com/__down?during=download&bytes=104857600
' 'VPS, cloudflare'	
	next | tee -a $logfile
}
mtrgo(){
	mtrurl=$1
	nodename=$2
	echo "===== 测试 [$nodename] 到此服务器的去程路由 =====" | tee -a $logfile
	mtrgostr=$(curl -s "$mtrurl")
	echo -e "$mtrgostr" > mtrlog.log
	mtrgostrback=$(curl -s -d @mtrlog.log "http://test.91yun.org/traceroute.php")
	rm -rf mtrlog.log
	echo -e $mtrgostrback | awk -F '^' '{printf("%-2s\t%-16s\t%-35s\t%-30s\t%-25s\n",$1,$2,$3,$4,$5)}' | tee -a $logfile
	echo -e "===== [$nodename] 去程路由测试结束 =====" | tee -a $logfile	
}
mtrback(){
	echo "===== 测试 [$2] 的回程路由 =====" | tee -a $logfile
	mtr -r -c 10 $1 | tee -a $logfile
	echo -e "===== 回程 [$2] 路由测试结束 =====" | tee -a $logfile	
}
tracetest(){
	mtrgo "http://www.ipip.net/traceroute.php?as=1&a=get&n=1&id=254&ip=$IP" "北京电信"
	next | tee -a $logfile
}
backtracetest(){
	mtrback "39.156.69.79" "39.156.69.79"
	next | tee -a $logfile
}
go(){
	check_sys
	Installation_dependency
	get_info
	system_info
	io_test "io_test_1"
	io_test "io_test_2"
        speed
	backtracetest
	[[ ${action} == "a" ]] && benchtest
	echo "測試脚本执行完毕！日志文件: ${logfile}"
}
action=$1
go
