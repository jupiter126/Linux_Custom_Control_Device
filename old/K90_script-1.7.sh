#!/bin/bash
# DEV RELEASE - UNSTABLE - If Unsure, please run 1.0
directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  #determine script $directory and the user that should be notified
user=$(echo $directory|cut -d"/" -f3) # Works as long as script is stored in /home/user/whatever/ - #user="${SUDO_USER}" #name of the user that must be notified --> returns empty  #user="${USER}" #name of the user that must be notified --> returns root
if [ ! -f $directory/activelayout ]; then #if 	activelayout is not set, set it to Admin
	echo Admin > $directory/activelayout
fi
activelayout="$(cat $directory/activelayout)" && source $directory/K90_Layout_$activelayout && $include $directory/K90_Layout_$activelayout # This is where we set the activelayout, load its variables and functions
if [ -f K90_conf ]; then #check and load config, print error if does not exist
	source K90_conf
else 
	echo "K90_conf.txt not found, please set a conf file!"
fi
function f_debug { # Debug mode helps tracing where crashes occur (if $debug = 1) - must be declared soon
if [ "$debug" = "1" ]; then
	echo "########################################"
	echo "debug = $1" && echo "pwd = `pwd`" # && echo "debug = $1" >> log/debug.log && echo "pwd = `pwd`" >> log/debug.log
	echo "cachefile is $cachefile"
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
if [ ! -f getscancodes ]; then #check for getscancodes binary - try to compile it if not found
	echo "getscancodes binary not detected in $directory, attempting automatic compilation" && DISPLAY=:0 notify-send -t 4000 "getscancodes binary not detected in $directory" 'Attempting automatic compilation'
	if [ -d getscancodes-1.0-modified ]; then
		cd "getscancodes-1.0-modified"
		if [ "$(which gcc|grep -v which)" != "" ] && [ "$(which make|grep -v which)" != "" ]; then
			make
			if [ -f getscancodes ]; then
				echo "Compilation successfull, moving binary to running directory" && DISPLAY=:0 notify-send -t 5000 "Compilation successfull" 'moving binary to running directory'
				mv getscancodes $directory
				cd $directory
			else
				echo "Compilation failed, For Unknown reason" && DISPLAY=:0 notify-send -t 15000 "Compilation failed" 'For Unknown reason'
			fi
		else
			echo "Compilation failed, gcc and/or make are not available" && DISPLAY=:0 notify-send -t 15000 "Compilation failed" 'gcc and/or make are not available'
		fi
	else
		echo "Compilation failed, getscancodes-1.0-modified directory not found" && DISPLAY=:0 notify-send -t 15000 'Compilation Failed' "getscancodes-1.0-modified directory not found"
	fi
fi
if [ "$(whoami)" = "root" ]; then # As the script is ran by root and controlled by $cachefile, it is a good idea to leave as chown 644 and owned by root!
	touch $cachefile
	chown root $cachefile
	chmod 644 $cachefile
fi
function f_initcache { #gets the scancodes - resets the filecache - be careful, as this will kill all running instances of getscancodes running on the host. I guess this is kind'of OK on most systems
fonction=f_initcache
f_debug $fonction
echo "f_initcache disabled"
gscpid=$(pgrep getscancodes)
if [ $(whoami) = "root" ] && [ "$gscpid" = "" ]; then #restart getscancodes
	fonction="restart_getscancodes"
	f_debug $fonction
#	killall -q getscancodes # Modifications made, it's better if it works without killing ;)
	./getscancodes $eventnbr | tee /dev/null $cachefile & # Somehow when I > the output in a file, I can't tail it without stopping getscancodes, although it doesn't stop when pipng trough tee
fi
}
f_initcache
keycode=`tail -n 2 $cachefile` #extract the last line, and store it in $keycode
function f_is_running { # Check if a function is allready running (in order to prevent it to run twice at the same time)
fonction=f_is_running
f_debug $fonction
if [ "$checkifrunning" = "1" ]; then
	if [ -f tmp/$1 ]; then
		f_libnotify 5000 'Corsair - K90' "Cancelled: $1 action allready running, and checkifrunning=1.  If not, remove $directory/tmp/$1 manually"
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
function f_confirm { # Confirm that you want to start a function (rsync, ...)
fonction=f_confirm
f_debug $fonction
if [ "x$mustconfirm" = "x1" ]; then
	f_libnotify 5000 "Corsair K90 $layout - $fonction Confirmation Required" "You have 5 seconds to press G16 to confirm"
	sleep 5 
	f_initcache
	keycode=`tail -n 2 $cachefile`
	if [ "x$keycode" != "x458975" ]; then #This is the code for G16, you can find each keys code lower (elif [ "x$keycode" = ....... )
		f_libnotify 2000 "Corsair K90 $layout - $fonction" "Confirmation failed"
		rm tmp/$fonction
		exit
	else
		return 0		
	fi
else
	return 0
fi
}
function f_select_latest { #to be done -- would allow the selection of certain files according to their extensions $1= "avi|mkv|mp4" for example
fonction=f_select_latest
f_debug $fonction
	rm tmp/select
	DISPLAY=:0 notify-send -t 5000 "Choose target file:" "$(echo -e "G1 for HOME - $(ls -t /home/$user/|egrep -i "$1$"|head -n 1)\n\nG2 for DATA $(ls -t /home/$user/data/|egrep -i "$1$"|head -n 1)\n\nG3 for DOWNLOADS $(ls -t /home/$user/Downloads/|egrep -i "$1$"|head -n 1)\n\nG4 for XCHAT $(ls -t /home/$user/.xchat2/downloads/|egrep -i "$1$"|head -n 1)")"
	sleep 5
	f_initcache
	keycode=`tail -n 2 $cachefile`
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
fonction=f_libnotify
f_debug $fonction
	DISPLAY=:0 notify-send -t $1 "$2" "$3"
#else
	echo "$2 - $3" 
fi
}
function f_switch { # Switch between keyboard layouts - use "./K90_script switch"
fonction=f_switch
f_debug $fonction
# You can have as much custom layouts as you wish, each one should be a copy of this script, with as filename "K90_script-[youchangethispart]"
# f_switch automatically detects them and parses them sequentially one by one.
if [ ! -f $directory/tmp/switch.state ]; then #create state file if it doesn't exist
	echo "1" > $directory/tmp/switch.state
fi
x=$(cat $directory/tmp/switch.state) # read current state from file
n=$(ls $directory/ |grep "K90_Layout_"|wc -l) # scans $directory for "K90_script-" --> count configs
if [ "$x" -ge "$n" ]; then #set X to correct value
	x="1"
else
	x=$((x+1))
fi
echo "$x" > $directory/tmp/switch.state # write new state in file
rm $directory/K90_script.sh #remove old ln
ln -s $(ls $directory|grep "K90_script-"|head -n "$x"|tail -n 1) $directory/K90_script.sh # create new ln
f_libnotify 3000 "Keyboard Switch" "$(ls $directory|grep "K90_script-"|head -n "$x"|tail -n 1) Enabled"
chown $user $directory/K90_script.sh && chown -R $user $directory/tmp #change ownership
exit
}
function f_create { # Creates a blank keyboard layout - use "./K90_script create nameofprofile"
fonction=f_create
f_debug $fonction
if [ -f $directory/K90_Layout_$1 ]; then
	f_libnotify 5000 'Layout creation Cancelled' "$1 allready exists"
	exit
else
	cp $directory/K90_Layout_Blank $directory/K90_Layout_$1
	chown $user $directory/K90_Layout_$1
	chmod 755 $directory/K90_Layout_$1
	f_libnotify 5000 'Layout creation Successull' "You can now modify and/or switch to $1"
	exit
fi
}
function f_cheatsheet { # Generates a list of the functions available in currently active config, based on _-_
fonction=f_initcache
f_debug $fonction
#f_libnotify 12000 "CheatSheet for $activelayout layout" "$(cat $(ls -a|grep "$activelayout" |cut -f2 -d">")|grep "_-_"|grep -v cheatsheet|cut -f2 -d"=")"
f_libnotify 12000 "CheatSheet for $activelayout layout" "$(cat $(ls -a|grep "$activelayout" |grep -v "~"|cut -f2 -d">")|grep "_-_"|grep -v cheatsheet|cut -f2 -d"=")"
}
# End of declarations, program "entry point"
if [ "x$1" = "x" ]; then # Launch with arguments if any
	echo "No arguments detected, running normally"
elif [ $1 = "switch" ]; then
	f_switch
elif [ $1 = "create" ]; then
	f_create "$2"
elif [ $1 = "458960" ]; then
	f_G01
	exit
elif [ $1 = "458961" ]; then
	f_G02
	exit
elif [ $1 = "458962" ]; then
	f_G03
	exit
elif [ $1 = "458963" ]; then
	f_G04
	exit
elif [ $1 = "458964" ]; then
	f_G05
	exit
elif [ $1 = "458965" ]; then
	f_G06
	exit
elif [ $1 = "458966" ]; then
	f_G07
	exit
elif [ $1 = "458967" ]; then
	f_G08
	exit
elif [ $1 = "458969" ]; then
	f_G10
	exit
elif [ $1 = "458970" ]; then
	f_G11
	exit
elif [ $1 = "458971" ]; then
	f_G12
	exit
elif [ $1 = "458972" ]; then
	f_G13
	exit
elif [ $1 = "458973" ]; then
	f_G14
	exit
elif [ $1 = "458974" ]; then
	f_G15
	exit
elif [ $1 = "cheatsheet" ] || [ $1 = "458975" ]; then
	f_G16
	exit
else
	echo 'argument not known.'
fi
if [ "$keybmode" = "Admin" ]; then #If launched from cron (keybmode=admin) then read last action and repeat 4 times on 1 min - This var is defined in the keyboard layout
	delay=15 # define delay: custom keys' results will be parsed every X seconds
	seconds=1
	while [ "$seconds" -le "60" ];
	do
		f_initcache
		keycode=`tail -n 2 $cachefile`
		echo "Timer is at $seconds seconds and repeats every $delay until 60"
		case $keycode in
		458998) 
			f_MR ;;
		458960)
			f_G01 ;;
		458961) 
			f_G02 ;;
		458962)
			f_G03 ;;
		458963) 
			f_G04 ;;
		458964) 
			f_G05 ;;
		458965)
			f_G06 ;;
		458966)
			f_G07 ;;
		458967) 
			f_G08 ;;
		458968)
			f_G09 ;;
		458969)
			f_G10 ;;
		458970) 
			f_G11 ;;
		458971) 
			f_G12 ;;
		458972) 
			f_G13 ;;
		458973)
			f_G14 ;;
		458974) 
			f_G15 ;;
		458975)
			f_G16 ;;
		458984)
			f_G17 ;;
		458985)
			f_G18 ;;
		458993) 
			f_M1 ;;
		458994) 
			f_M2 ;;
		458995)
			f_M3 ;;
		458996)
			f_Lock ;;
		458997)
			f_Unlock ;;
		esac
	sleep $delay
	seconds=$((seconds+delay))
	done
fi
exit
##### If you like this script, please consider donating something to the Free Software Foundation, Debian, OpenBSD, ... or any other valuable open source project! Thanks ;)

