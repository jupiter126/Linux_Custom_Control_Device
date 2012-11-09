#!/bin/bash
directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  #determine script $directory and the user that should be notified
mkdir -p $directory/tmp
user=$(echo $directory|cut -d"/" -f3) # Works as long as script is stored in /home/user/whatever/ - #user="${SUDO_USER}" #name of the user that must be notified --> returns empty  #user="${USER}" #name of the user that must be notified --> returns root
if [ ! -f $directory/activelayout ]; then #if activelayout is not set, set it to Admin
	echo K90-Admin > $directory/activelayout
fi
activelayout="$(cat $directory/activelayout)"
if [ ! -f  $directory/LCCD_Layout_$activelayout ]; then
	echo $(ls $directory/ |grep "LCCD_Layout_"|grep -v "~"|head -n1|cut -f 3 -d"_") > $directory/activelayout #If active layout is set to a non existing one, set it to an existing one
fi
source $directory/LCCD_Layout_$activelayout && $include $directory/LCCD_Layout_$activelayout # This is where we set the activelayout, load its variables and functions
if [ -f $directory/LCCD_conf ]; then #check and load config, print error if does not exist
	source $directory/LCCD_conf
else 
	echo "LCCD_conf not found, please get a conf file!"
fi
function f_debug { # Debug mode helps tracing where crashes occur (if $debug = 1) - must be declared soon
if [ "$debug" = "1" ]; then
	echo "########################################"
	echo "debug = $1" && echo "pwd = `pwd`" # && echo "debug = $1" >> log/debug.log && echo "pwd = `pwd`" >> log/debug.log
	echo "user is $user"
	echo "########################################"
fi
}
if [ "x$libnotify" = "x1" ]; then #get DBUS_SESSION_BUS_ADDRESS
	if [ "$(xhost|grep LOCAL)" = "" ]; then
		xhost +local: #allows for local non-network connection on X (to send the notify)
	fi
	pid=$(pgrep -u $user $appli)
	dbus=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$pid/environ | sed 's/DBUS_SESSION_BUS_ADDRESS=//' )
	DBUS_SESSION_BUS_ADDRESS=$dbus
fi
if [ ! -f $directory/getscancodes ]; then #check for getscancodes binary - try to compile it if not found
	echo "getscancodes binary not detected in $directory, attempting automatic compilation" && DISPLAY=:0 notify-send -t 4000 "getscancodes binary not detected in $directory" 'Attempting automatic compilation'
	if [ -f $directory/getscancodes.c ] && [ -f $directory/Makefile ] && [ -f $directory/getscancodes.o ]; then
		sed -i "s;xxxxxxxxxxxxxxxxxxxx;$directory;" getscancodes.c
		if [ "$(which gcc|grep -v which)" != "" ] && [ "$(which make|grep -v which)" != "" ]; then
			make
			if [ -f $directory/getscancodes ]; then
				echo "Compilation successfull, moving binary to running directory" && DISPLAY=:0 notify-send -t 5000 "Compilation successfull" 'moving binary to running directory'
			else
				echo "Compilation failed, For Unknown reason" && DISPLAY=:0 notify-send -t 15000 "Compilation failed" 'For Unknown reason'
			fi
		else
			echo "Compilation failed, gcc and/or make are not available" && DISPLAY=:0 notify-send -t 15000 "Compilation failed" 'gcc and/or make are not available'
		fi
	else
		echo "Compilation failed, getscancodes.c not found" && DISPLAY=:0 notify-send -t 15000 'Compilation Failed' "getscancodes-1.0-modified directory not found"
	fi
fi
keycode=$1
function f_is_running { # Check if a function is allready running (in order to prevent it to run twice at the same time)
if [ "$checkifrunning" = "1" ]; then
	if [ -f tmp/$1 ]; then
		f_libnotify 5000 "$device" "Cancelled: $1 action allready running, and checkifrunning=1.  If not, remove $directory/tmp/$1 manually"
		exit
	else
		touch tmp/$fonction
		return 0
	fi
else
	touch tmp/$fonction
	return 0
fi
}
function f_confirm { # Confirm that you want to start a function (rsync, ...) - I linked it with G12
if [ "x$mustconfirm" = "x1" ]; then
	echo "" > $directory/tmp/check
	f_libnotify 5000 "$device $layout - $fonction Confirmation Required" "You have 5 seconds to press G12 to confirm"
	sleep 5 
	if [ "$(cat $directory/tmp/check)" != "1" ]; then #This is the code for G12
		f_libnotify 2000 "$device $layout - $fonction" "Confirmation failed"
		if [ -f tmp/$fonction ]; then
			echo "removing tmp/$fonction"
			rm tmp/$fonction
		fi
		exit
	else
		f_libnotify 2000 "$device $layout - $fonction" "Confirmation Confirmed"
		return 0
	fi
else
	return 0
fi
}
function f_select_latest { #to be done -- would allow the selection of certain files according to their extensions $1= "avi|mkv|mp4" for example
fonction=f_select_latest
f_debug $fonction
	if [ -f tmp/select ]; then
		rm tmp/select
	fi
	DISPLAY=:0 notify-send -t 5000 "Choose target file:" "$(echo -e "G1 for HOME - $(ls -t /home/$user/|egrep -i "$1$"|head -n 1)\n\nG2 for DATA $(ls -t /home/$user/data/|egrep -i "$1$"|head -n 1)\n\nG3 for DOWNLOADS $(ls -t /home/$user/Downloads/|egrep -i "$1$"|head -n 1)\n\nG4 for XCHAT $(ls -t /home/$user/.xchat2/downloads/|egrep -i "$1$"|head -n 1)")"
	sleep 5
	case $keycode in
	458960)
	echo "/home/$user/$(ls -t /home/$user/|egrep -i "$1$"|head -n 1)" > tmp/select
	;;
	458961)
	echo "/home/$user/data/$(ls -t /home/$user/data/|egrep -i "$1$"|head -n 1)" > tmp/select
	;;
	458962)
	echo "/home/$user/Downloads/$(ls -t /home/$user/Downloads/|egrep -i "$1$"|head -n 1)" > tmp/select
	;;
	458963)
	echo "/home/$user/.xchat2/downloads/$(ls -t /home/$user/.xchat2/downloads/|egrep -i "$1$"|head -n 1)" > tmp/select
	;;
	esac
	return 0
}
function f_libnotify { # manage user interaction through libnotify if enabled, else echoes its output
if [ "x$libnotify" = "x1" ]; then
	DISPLAY=:0 notify-send -t $1 "$2" "$3"
#else
	echo "$2 - $3" 
fi
}
function f_switch { # Switch between keyboard layouts - use "./LCCD_core.sh switch"
fonction=f_switch
f_debug $fonction
# You can have as much custom layouts as you wish, each one should be a copy of this script, with as filename "LCCD_Layout_[youchangethispart]" f_switch automatically detects them and parses them sequentially one by one.
if [ ! -f $directory/activelayout ]; then #create state file if it doesn't exist
	if [ "$(ls $directory|grep "LCCD_Layout_"|grep -v "~")" = "" ]; then
		f_libnotify 5000 "FATAL" "No Layout file detected, please fix by putting a LCCD_Layout_* file"
		exit
	else
	echo "$(ls $directory|grep "LCCD_Layout_"|grep -v "~"|head -n "1"|tail -n 1|cut -f3 -d "_")" > $directory/activelayout
	fi
fi
n=$(ls $directory/ |grep "LCCD_Layout_"|grep -v "~"|wc -l) # scans $directory for "./LCCD_Layout_" --> count configs
o=$(ls $directory|grep "LCCD_Layout_"|grep -v "~"|cut -f3 -d "_"|grep -ne "$(cat $directory/activelayout)"|cut -f1 -d ":") #get current conf number
if [ "$o" -ge "$n" ]; then
	echo "$(ls $directory|grep "LCCD_Layout_"|grep -v "~"|head -n "1"|tail -n 1|cut -f3 -d "_")" > $directory/activelayout
else
	o=$[ ( $o + 1 ) ]
	echo "$(ls $directory|grep "LCCD_Layout_"|grep -v "~"|head -n "$o"|tail -n 1|cut -f3 -d "_")" > $directory/activelayout
fi
f_libnotify 3000 "Keyboard Switch" "$(cat $directory/activelayout) Enabled"
exit
}
function f_create { # Creates a blank keyboard layout - use "././LCCD_core.sh create nameofprofile"
fonction=f_create
f_debug $fonction
if [ -f $directory/LCCD_Layout_$1 ]; then
	f_libnotify 5000 'Layout creation Cancelled' "$1 allready exists"
	exit
else
	cp $directory/LCCD_Layout_Blank $directory/LCCD_Layout_$1
	chown $user $directory/LCCD_Layout_$1
	chmod 755 $directory/LCCD_Layout_$1
	f_libnotify 5000 'Layout creation Successull' "You can now modify and/or switch to $1"
	exit
fi
}
function f_list {
fonction=f_list
f_debug $fonction
echo "$(ls $directory/ |grep "LCCD_Layout_"|grep -v "~"|wc -l) Layouts found:"
ls $directory/ |grep "LCCD_Layout_"|grep -v "~"
exit
}
function f_cheatsheet { # Generates a list of the functions available in currently active config, based on _-_
fonction=f_cheatsheet
f_debug $fonction
#f_libnotify 12000 "CheatSheet for $activelayout layout" "$(cat $(ls -a|grep "$activelayout" |cut -f2 -d">")|grep "_-_"|grep -v cheatsheet|cut -f2 -d"=")"
f_libnotify 12000 "CheatSheet for $activelayout layout" "$(cat $(ls -a|grep "$activelayout" |grep -v "~"|cut -f2 -d">")|grep "_-_"|grep -v cheatsheet|cut -f2 -d"=")"
}
# End of declarations, program "entry point"
source $directory/LCCD_Triggers_K90.sh #Loads the right triggers for device
exit
##### If you like this script, please consider donating something to the Free Software Foundation, Debian, OpenBSD, ... or any other valuable open source project! Thanks ;)
