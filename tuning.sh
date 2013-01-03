#!/bin/bash
# file : tuning.sh -> Expect/Tcl/gnuplot/Bash
# Author : James Magochi
# Email : james@magochi.net
# Objective : Identifying memory [hungry|intensive] [process|services|daemons] and Identify the part of the system that is critical for improving the performance.
# DESCRIPTION: The wizard lets you input the IP/hostname + credentials. Then logs in to the server and gets the Top process consuming the memory, then presents in a nice gnuplot graph.
# Usage : $bash tuning.sh or ./tuning.sh
# Dependancies : You are required to have gnuplot and expect/Tcl on you Linux installed
# Beging <=
mainmenu () 
{
loc=`yad --width 350 --entry --title "Linux Performance Tuning Tool" --image=gnome-shutdown --field="Username:2" --button="gtk-ok:0" --button="gtk-close:1" --text "Choose action:" --entry-text "Local" "Remote"`
wapi=`echo $loc`
}
mainmenu
remote () 
{
Geometry='Top Left!Top Right!Bottom Left!Bottom Right!Top!Bottom!Left!Right!Center!Tiled'
magochi=`yad --title "Remote Server Details" --form      \
            --field="IP/Domain" \
  	 --field="Username"  \
	    --width 500 --dialog-sep --image xfce4-keyboard \
            --field "TOP PROCESSES:NUM"                     \
            --button gtk-ok:0 --button gtk-cancel:1         \
            "" "" '20!0..100!5' `
	ip=`echo $magochi |awk -F "|" '{print $1}'`
	username=`echo $magochi |awk -F "|" '{print $2}'`
	list=`echo $magochi |awk -F "|" '{print $3}' |awk -F "." '{print $1}'`
	if [ $ip != "" ]; then
		password=`zenity --entry --title="Remote password" --text="Enter your _password:" --entry-text "" --hide-text`
		kate
	else
	 	zenity --error --text="No input provided"
		exit 0
	fi
}
kate () {
expect - <<EOF
match_max 1000000
spawn ssh $username@$ip
expect "password:" {
send "$password\r"
} "*yes/no)*" {
send "yes\r"
exit 1
}
expect "Last* | *]$"
send "ps -AH v > mem1\r"
sleep 1
EOF
cd ~/
expect - <<EOF
match_max 1000000
spawn scp $username@$ip:~/mem1 .
expect "password:" 
send "$password\r"
expect "mem*"
sleep 3
EOF
cat ~/mem1 |awk '{ print $8,$9,$10}' |sort -h |tail -n$list  | awk -F "/" "{print $NF }" > ~/mem2
cat ~/mem2 | awk -F '/| ' '{print $NF }' > ~/mem4
paste ~/mem4 ~/mem2 > ~/mem3
~/graphing
rm ~/mem1 ~/mem2 ~/mem3 ~/mem4
display ~/memory-utilization.png
}
echo $wapi
if [ "$wapi" != "Remote" ]; then
	getps
else
	remote
fi
