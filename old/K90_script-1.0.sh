#!/bin/bash
layout=Admin
# If there is no line "layout=XXXXX" up here, then this is the skeleton config and you shouldn't edit it, rather use "K90_script.sh create NameOfNewLayout", and edit that one ;)
# In addtion of being a skeleton for new layouts, the blank can serve as safeguard when guests or kids ure your computer.
###########################
# I N T R O D U C T I O N #
###########################
# This little script is a dirty quickhack by me (JuPiTeR)-(really, 4 days of noobswork - it is literally the second script of more than 50 lines that I write), 
# and can certainly be enhanced in at least a 100 possible manners: if you can do better, please do so!

# It is its own readme, please read the file thoroughly, including comments; I tried to put as many as possible.
# If you ask a	question that is answered by comments in the code, you're question will fly to /dev/spam, else I will do what I can to answer questions sent at jupiter126[@t]gmail[dot]com (plz be patient)

# This script heavily relies on a slightly modified version of getscancodes (original code by Marvin Raaijmakers).
# "getscancodes", by Marvin Raaijmakers is available at http://keytouch.sourceforge.net/dl-getscancodes.html
# However, the actual code of getscancodes does not allow for redirection, it needed the following change (Credits to Badger for finding the bug, and to Kon for fixing it): 
# at line 92 of scancodes.c, replace 
#	printf("%d (0x%x)\n", ev[i].value, ev[i].value);
# with
#	char buf[8]; sprintf(buf, "%d\n", ev[i].value); write(1, buf, sizeof(buf)); fsync(1);

# This change is allready applied to the source I hereby provide, it allows to redirect it's output (changed the way it buffers), thus to collect the scancodes in a text file.

############
#F i l e s #
############
# Are included in this release: 
#	- K90-script-1.0.sh
#	- K90_conf
#	- K90_script-Blank.sh
#	- getscancodes-1.0-modified
#		- Makefile
#		- getscancodes.c
#		- getscancodes.o

#######################################################
# R I G H T S  A N D  R E S P O N S A B I L I T I E S #
#######################################################
# By using this program, you agree to all of the following
# - getscancodes is published under GPL V2 (Like Marvin Raaijmakers' original source).  
# - K90_Linux is released under BSD licence.
# - I assume no responsabilities whatsoever for the consequences of running this program on your computer, it runs on mine, I share it, and it is your sole reponsability to use it.

###########################
# D E P E N D A N C I E S #
###########################
# User Communication is done trough libnotify and also depends on x11-apps/xhost
#   - gentoo x11-libs/libnotify x11-apps/xhost
#   - debian/*buntu libnotify-bin
#   - redhat/fedora/centos libnotify
#   - Windows, it was a pleasure, have a nice day!

# make and GCC are required to compile getscancodes
# The rest of the dependencies depend of your scripts.


###########
# T O D O #
###########
#- Find how I emulate a sequence of keys? not sure (xmacro or xsendkeycode), and send it to a running game?
#- Redesign the app for game mode... 

###########
# B U G S #
###########
#- When catching the custom keys, 3 of the 18 make some noise on the primary channel: these are G9 G17 and G18.  There's not much I can think of to solve this issue, so the best option in my opinion is not to use them. (G17 does play/pause and G18 stop on Amarok)

#- When creating a kde shortcut for "f_switch" (system settings/shortcut & gestures/custom shortcuts) somehow the notification does not work.  I don't know why this happens, but you can bypass this bug by adjusting the following as shortcut:
# /home/jupiter/K90_Linux/K90_script.sh switch && notify-send -t 2000 "Keyboard switched to $(ls /home/jupiter/K90_Linux/|grep "K90_script-"|head -n "$(cat /home/jupiter/K90_Linux/tmp/switch.state)"|tail -n 1)"

#- I think sometimes the keyboard sends the lock/unlock signal without my hitting the key (I can see the OSD information)

#- Certainly many more bugs :p

#####################
# C h a n g e l o g #
#####################
#Day 1: 0.1 --> 0.5 - defining a logic, finding keycodes, testing stuff, ...
#Day 2: 0.6 -- core debugging + first functiunnalities implemented:
#		- Mute: switches the extended keyboard on/off
#	  	- G1: make a hard disk checkup
#		- G2: Launch all favourite apps
#		- G13: Launch most recent [avi,mkv,mp4] in /home/jupiter/Downloads/
#		- M1: update kernel
#		- M2: restart X
#		- M3: restart computer
#		- Lock/Unlock: stop/restart sshd
#Day 3: 0.7 --> 0.8 - core changes + more functiunnalities implemented
#		- added f_select_latest - that allows to select the most recent files of a certain type.
#		- Now G13 allows to launch the most recent movie between a choice of 4 folders.
#		- Remapped the keys
#		- Check periodic info (Test Website)
#		- Backup Server
#		- Flash Raspberry pi image on SD
#		- Sync Android microSD
#		- remount shm with exec
#		- f_notify and echo support
#		- Cleanups, cleanups, cleanups, ... 
#Day 4: 0.8--> 0.9999 	- Include the switch function in the script, to emulate original M1 M2 M3 behaviour
#			- Include Speedup factor to make responsivity better for games
#			- Include profile create option
#			- Switched to UTF8 (forgot to setup kate in new OS installation)
#			- Automatic compilation of getscancodes
#			- Cheatsheet
#			- Cleanups, cleanups, cleanups, and optimized code a bit (tnx again Kon)
#-----------------------------------------------
#	0.9999 RC3 --> 1.0 	Thanks to Hell4You for code review and improvement hints!
#			- Changed $directory from user determined variable to auto detection
#			- Changed $user from user determined variable to auto detection, though couldn't get the recommended ${USER} method to do the trick
#			- Got the variables in a external config file

# I think I found a way of enabling real time commands to be passed by the script, however this requires deep core changes of this script, rather than including this in the .9999RC, I decided to call this version 1.0 (it seems quite stable) - and to start right on the core changes, thus heading for version 1.5.

#############
# U S A G E #
#############
# I use this script mostly as a shortcut for common system administration, rather than as a gaming keyboard, I thus appreciate the possibility to cancel some strikes before they are executed.
# This is why I set the cron on a 15 seconds rather than per second.  If you plan to uss the "Reactivity Boost" option

# use "crontab -e" to add a job to cron (this script)
#Example:
# * * * * * /home/yourhome/K90_linux/K90_script.sh
# This runs the /home/yourhome/K90_linux/K90_script.sh script every minute
# NB: This should be done as root, else getscancodes will not have sufficient rights to access /dev/input/event[XX]
# - Modified getscancodes outputs the codes from /dev/input/event[XX] in a text file
# - Every time the script is run (cron)
#	- Checks the last line of text file
#	- For the associated key, parse the $isrunning and $confirm vars
#	- If conditions are met, launch corresponding script

# Options
# K90_script.sh create ProfileName : Create a blank profile named "ProfileName" (avoid spaces and special characters in profile name)
# K90_script.sh switch : Switch to next profile (we're not limited to 3 profiles, so create an extra profile rather than editing the blank one.)

###############################################
# S c r i p t  R E A C T I V I T Y  B O O S T #
###############################################
# cron allows to run the script once a minute, this section boosts that up by putting the whole script in a while loop
# define "delay", the script will then run every "x" $seconds
# When seconds are greater than 60, the script stops
# delay=1 would be better for gaming mode; while I feel comfortable with delay=15 for the actual config
# The reason of this is that some scripts require confirmations, and that a too short delay will catch confirmation codes
# And launch other scripts instead.
delay=15 # define delay: custom keys' results will be parsed every X seconds
seconds=1
while [ "$seconds" -le "60" ]
do
echo "Timer is at $seconds seconds and repeats every $delay until 60"
#The end of this function is at the bottom of the whole script.

#####################
# V A R I A B L E S #
#####################
# Variables should now be set in K90_conf
if [ -f K90_conf ]; then
	source K90_conf
else 
	echo "K90_conf not found, please set a conf file!"
fi

###############
# S C R I P T # Think twice before modyfing in this section
###############
#determine script $directory and the user that should be notified
directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#user="${SUDO_USER}" #name of the user that must be notified --> returns empty
#user="${USER}" #name of the user that must be notified --> returns root
user=$(echo $directory|cut -d"/" -f3) # Works as long as script is stored in /home/user/whatever/

#echo "dir is $directory"
#echo "user is $user"

if [ "x$libnotify" = "x1" ]; then
	#get DBUS_SESSION_BUS_ADDRESS
	if [ "$(xhost|grep LOCAL)" = "" ]; then
		xhost +local: #allows for local non-network connection on X (to send the notify)
	fi
	pid=$(pgrep -u $user $appli)
	dbus=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$pid/environ | sed 's/DBUS_SESSION_BUS_ADDRESS=//' )
	DBUS_SESSION_BUS_ADDRESS=$dbus
fi

#check for getscancodes binary - try to compile it if not found
cd $directory
if [ ! -f getscancodes ]; then
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

#extract the last line, and store it in $keycode
if [ "$(whoami)" = "root" ]; then # As the script is ran by root and controlled by $cachefile, it is a good idea to leave as chown 644 and owned by root!
	touch $cachefile
	chown root $cachefile
	chmod 644 $cachefile
fi
keycode=`tail -n 2 $cachefile`

#####################
# F U N C T I O N S # These two functions are called by all keys - check the 2 key options
#####################

# kill and restart the process (this resets the $cachefile)
# Be carefull, as this will kill all running instances of getscancodes running on the host.
# I guess this is kind'of OK on most systems
function f_initcache { #gets the scancodes - resets the filecache
if [ $(whoami) = "root" ]; then
	killall -q getscancodes
	./getscancodes $eventnbr > $cachefile &
fi
}
function f_is_running { # Check if a function is allready running (in order to prevent it to run twice at the same time)
if [ "$checkifrunning" = "1" ]; then
	if [ -f tmp/$1 ]; then
		f_libnotify 5000 'Corsair - K90' "Cancelled: $1 action allready running, and checkifrunning=1.  If not, remove $directory/tmp/$1 manually"
		exit
	else
		touch tmp/$fonction
		return 0
	fi
else
	return 0
fi
}
function f_confirm { # Confirm that you want to start a function (rsync, ...)
if [ "x$mustconfirm" = "x1" ]; then
	f_libnotify 5000 "Corsair K90 $layout - $fonction Confirmation Required" "You have 5 seconds to press G16 to confirm"
	sleep 5 
	keycode=`tail -n 2 $cachefile`
	f_initcache
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
	rm tmp/select
	DISPLAY=:0 notify-send -t 5000 "Choose target file:" "$(echo -e "G1 for HOME - $(ls -t /home/jupiter/|egrep -i "$1"|head -n 1)\n\nG2 for DATA $(ls -t /home/jupiter/data/|egrep -i "$1"|head -n 1)\n\nG3 for DOWNLOADS $(ls -t /home/jupiter/Downloads/|egrep -i "$1"|head -n 1)\n\nG4 for XCHAT $(ls -t /home/jupiter/.xchat2/downloads/|egrep -i "$1"|head -n 1)")"
	sleep 5
	keycode=`tail -n 2 $cachefile`
	f_initcache
	case $keycode in
	458960)
	echo "/home/jupiter/$(ls -t /home/jupiter/|egrep -i "$1"|head -n 1)" > tmp/select
	;;
	458961)
	echo "/home/jupiter/data/$(ls -t /home/jupiter/data/|egrep -i "$1"|head -n 1)" > tmp/select
	;;
	458962)
	echo "/home/jupiter/Downloads/$(ls -t /home/jupiter/Downloads/|egrep -i "$1"|head -n 1)" > tmp/select
	;;
	458963)
	echo "/home/jupiter/.xchat2/downloads/$(ls -t /home/jupiter/.xchat2/downloads/|egrep -i "$1"|head -n 1)" > tmp/select
	;;
	esac
	return 0
}
function f_libnotify { # manage user interaction through libnotify if enabled, else echoes its output
if [ "x$libnotify" = "x1" ]; then
	DISPLAY=:0 notify-send -t $1 "$2" "$3"
else
	echo "$2 - $3" 
fi
}
function f_switch { # Switch between keyboard layouts - use "./K90_script switch"
# You can have as much custom layouts as you wish, each one should be a copy of this script, with as filename "K90_script-[youchangethispart]"
# f_switch automatically detects them and parses them sequentially one by one.
if [ ! -f $directory/tmp/switch.state ]; then #create state file if it doesn't exist
	echo "1" > $directory/tmp/switch.state
fi
x=$(cat $directory/tmp/switch.state) # read current state from file
n=$(ls $directory/ |grep "K90_script-"|wc -l) # scans $directory for "K90_script-" --> count configs
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
if [ -f $directory/K90_script-$1.sh ]; then
	f_libnotify 5000 'Layout creation Cancelled' "$1 allready exists"
	exit
else
	cp $directory/K90_script-Blank.sh $directory/K90_script-$1.sh
	chmod 755 $directory/K90_script-$1.sh
	sed -i "2i layout=$1" $directory/K90_script-$1.sh
	f_libnotify 5000 'Layout creation Successull' "You can now modify and/or switch to $1"
	exit
fi
}
function f_cheatsheet { # Generates a list of the functions available in currently active config, based on _-_
f_libnotify 12000 "CheatSheet for $layout layout" "$(cat $(ls -al|grep lrwx |cut -f2 -d">")|grep "_-_"|grep -v cheatsheet|cut -f2 -d"=")"
}
f_initcache
#################
# A C T I O N S # Here is where you should configure the payload of each your keys.
#################
# End of function declaration, program "entry point"
if [ "x$1" = "x" ]; then # go to main menu if there are no args
	echo "No arguments detected, running normally"
elif [ $1 = "switch" ]; then
	f_switch
elif [ $1 = "create" ]; then
	f_create "$2"
elif [ $1 = "create" ]; then
	f_cheatsheet
elif [ $1 -ge 458960 ] && [ $1 -le 458985 ]; then
	echo "Run action script" #Todo
else
	echo 'argument not known, arg can be "switch", to switch between custom layouts'
fi
# For each other button, you should set $checkifrunning, $mustconfirm and put a script
# Explanation:
# If the bound script is for games, you may want to put them on 0 (tells the script to act without doublecheck) - note that in this case you might want to run cron per second instead of per minute
# If the bound script is a backup, you can set checkifrunning on 1 to avoid doing it twice at the same time
# If the bound script formats a hard drive, you can set $mustconfirm on 1 so that the system asks you to confirm (default: you have 3 seconds to push G16) before it proceeds
###################################   MR   ###################################
# The MR key is an exception, I don't bind any script to it but rather use it as a 'cancel' key.
# MR cancels the previous custom key (easy to remember, just above escape)
case $keycode in 
458998) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=MR_-_Cancel
	f_libnotify 6000 "Corsair K90 $layout - $fonction" "Payload aborted"
		exit  ;;
###################################   G1   ###################################
458960) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G01_-_HDD_INFO 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Generating Complete Hard Drive Report" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
# This example generates a report on the hard drives - customize to your needs !!!
	(echo "Report generated on $(date +%Y%m%d) at $(date +%R)";echo " ";echo "--------------------------------------------------------------------------------";echo " ") > $directory/$fonction.txt
	(df -h;echo " ";echo "--------------------------------------------------------------------------------";echo " ") >> $directory/$fonction.txt
	(cd /home/jupiter;du -h --max-depth=1;cd $directory;echo " ";echo "--------------------------------------------------------------------------------";echo " ") >> $directory/$fonction.txt
	(/usr/sbin/smartctl -a /dev/sda;echo " ";echo "--------------------------------------------------------------------------------";echo " ") >> $directory/$fonction.txt
	(/usr/sbin/smartctl -a /dev/sdb;echo " ";echo "--------------------------------------------------------------------------------";echo " ") >> $directory/$fonction.txt
	(/usr/sbin/smartctl -a /dev/sdc;echo " ";echo "--------------------------------------------------------------------------------";echo " ") >> $directory/$fonction.txt
	
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G2   ###################################	
458961) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G02_-_Restore_Fav
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=0  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Restoring Favourite Apps" # Set your notify message here
# Script
# This is the proper script that will be launched when G2 is hit - customize to your needs !!!
# For each app in the list provided that is not detected as running, the script launches it for my $user : adapt with your favourites
	for i in firefox yakuake filezilla dolphin xchat google-chrome amarok
	do
		pgrep $i || sudo -b -u $user env DISPLAY=:0 $i
	done
#######################################
	rm tmp/$fonction ;;  #Leave the rm, it is used by f_is_running

###################################   G3   ###################################
458962) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G03_-_Play_Movie
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=0  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Playing most recent Movies" # Set your notify message here
# Script
#This one calls f_select_latest with extensions avi, mkv and mp4 in order to choose out of most recent files, then plays the selected one.
	filetype="avi|mkv|mp4"
	f_select_latest $filetype
	if [ -f tmp/select ]; then
		sudo -b -u $user env DISPLAY=:0 mplayer $(cat tmp/select) # I use mplayer, but any movie player should do
	else
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "No movie selected - not playing"
	fi
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G4   ###################################
458963) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G04_-_Unused_So_Far
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Change this text" # Set your notify message here
# Script
	echo "put your script here"
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G5   ###################################
458964) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G05_-_Unused_So_Far
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Change this text" # Set your notify message here
# Script
	echo "your script comes here"
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G6   ###################################
458965) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G06_-_Unused_So_Far
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Change this text" # Set your notify message here
# Script
	echo "your script comes here"
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running
	
###################################   G7   ###################################
458966) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G07_-_Test_Websites
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Testing websites" # Set your notify message here
# Script
# This example checks if a list of sites respond as expected.  List is formatted as "address;checkstring"
	for i in "www.openskill.lu;Relooking et modernisation de sites existants" "www.adel-sprl.be;rassembler un maximum de savoir faire au service de nos clients afin"
	do
		address=$(echo "$i"|cut -f 1 -d";")
		checkstring=$(echo "$i"|cut -f 2 -d";")
		if [ "$(wget -q -O - "$address" | grep -E -o "$checkstring")" = "" ]; then
			f_libnotify "10000" "Corsair K90 $layout - $fonction" "$address seems down"
		fi
	done
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G8   ###################################
458967) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G08_-_Backup_Server
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Starting Server Backup" # Set your notify message here
# Script
	rsync -qaEz -e "ssh -i /root/.ssh/id_rsa" root@prod.openskill.lu:/home/.users/68/jupiter/ $directory/backup/
	f_libnotify 5000 "Corsair K90 $layout - $fonction" "Server Backup Complete"
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running
	
###################################   G9   ###################################
458968)
	#I expect unexpected bugs on this key due to noise data it sends on another event
	echo "I would try to avoid this key" ;;

###################################   G10  ###################################
458969) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
#This script flashes a .img file on an usb stick or sd card)
# Be very carefull with this one as a wrong setting can cause massive data loss!
# Again, be sure it's sdd you want to flash, inserting an extra device can easily change device name!
	fonction=G10_-_dd_flash_USB
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Searching img files" # Set your notify message here
# Script
	filetype="img"
	f_select_latest $filetype
	if [ -f tmp/select ]; then
		f_libnotify 5000 "!!! CONFIRMATION!!!" "Flash $(cat tmp/select) on /dev/sdd ???"
		f_confirm $fonction
		dd if=$(cat tmp/select) of=/dev/sdd
		f_libnotify 5000 "Corsair K90 $layout - $fonction" "/dev/sdd has been flashed with $(cat tmp/select)"
	fi
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G11  ###################################
458970) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G11_-_Android_Backup
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
# Script
# Backups android phones manages many phones if required
	mount /dev/sdd1 /mnt/usb
# This function can handle many mobiles, to avoid Errors, I create a file manually on my mobile's SD root like this (this needs to be done once per mobile):
# echo "Telephone_Model" > /mnt/usb/imyourmobile
# Avoid spaces and weird characters. In my case, I have 3 mobiles backed-up that way, they just need a different model name in that file!
	if [ "$(cat /mnt/usb/imyourmobile)" != "" ];then
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "Backupping phone and syncing music to phone" # Set your notify message here
		model="$(cat /mnt/usb/imyourmobile)" #get's the model you defined for the phone
		rsync -qa "/mnt/usb/dcim" "$directory/Android/$model" #Backs-up pictures
		rsync -qa "/mnt/usb/clockworkmod" "$directory/Android/$model" #Backs up clockworkmod
# Update The Music folder on your computer manually.  At the next sync, all that music will be synced to your android.  !!! Be sure to have enough space !!!
		#rsync -qa --delete $directory/Android/$model/Music /mnt/usb/Music
		umount /mnt/usb 
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "$model Backup Complete" # Set your notify message here
	else
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "$model Backup Canceled - Either your phone isn't the right device, or you didn't create imyourmobile on the SD's root!"
	fi
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G12  ###################################
458971) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G12_-_Burn_CD
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
# Script
# Burns a CD - Not thoroughly tested :s
	filetype="iso"
	f_select_latest $filetype
	if [ -f tmp/select ]; then
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "Burning $(cat tmp/select)"
		f_confirm $fonction
		cdrecord -dao dev=2,0,0 $(cat tmp/select) && f_libnotify 3000 "Corsair K90 $layout - $fonction" "CD Has been burned" # Please, find the correct device identifier (dev=X.Y.Z) with "cdrecord -scanbus"
	else
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "No iso detected, Not Burning"
	fi
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G13  ###################################
458972) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G13_-_Switch_shm_NaCl
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
# Script
#This one remounts /dev/shm with differnt rights, I need it to enable Native Client in Chrome
# cfr http://code.google.com/p/nativeclient/issues/detail?id=1883
	if [ "$(mount|grep shm|grep noexec)" != "" ]; then
		mount -o remount,exec /dev/shm
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "shm remounted in EXEC mode (NaCl should run)"
	else
		mount -o remount,rw,nosuid,nodev,noexec,relatime /dev/shm
		f_libnotify 3000 "Corsair K90 $layout - $fonction" "shm remounted in SECURE mode"
	fi
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running	

###################################   G14  ###################################
458973) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G14_-_sync_repositories
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 2000 "Corsair K90 $layout - $fonction" "Syncing repositories..." # Set your notify message here
# Script
# Depends of your distribution
emerge --sync && f_libnotify 2000 "Corsair K90 $layout - $fonction" "Repositories synced, ready for upgrade"
#apt-get update && f_libnotify 2000 "Corsair K90 $layout - $fonction" "Repositories synced, ready for upgrade"
#yum update && f_libnotify 2000 "Corsair K90 $layout - $fonction" "Repositories synced, ready for upgrade"
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running	

###################################   G15  ###################################
458974) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G15_-_unused_so_far
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=0  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 2000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
# Script
	echo "script goes here"
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running	

###################################   G16  ###################################
458975) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G16_-_Cheat_Sheet
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=0  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
# Script
	f_cheatsheet
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   G17  ###################################
458984)
	#USE WITH CAUTION... I experienced unexpected bugs on this key due to noise data sent on another event
	echo "I would try to avoid this key" ;;
	
###################################   G18  ###################################
458985)
	#USE WITH CAUTION... I experienced unexpected bugs on this key due to noise data sent on another event
	echo "I would try to avoid this key" ;;

###################################   M1  ####################################
458993) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=M1_-_Update_Kernel
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Checking Checksums" # Set your notify message here
# Script
#installs my new kernel (if different from the previous one
#depends on sha512 for checksum
	mount /boot && mount /boot/efi
	oldchecksum=$(/usr/bin/sha512sum /boot/efi/EFI/gentoo/vmlinuz_new.efi|cut -f 1 -d" " )
	newchecksum=$(/usr/bin/sha512sum /usr/src/linux/arch/x86_64/boot/bzImage|cut -f 1 -d" " )
	if [ "$newchecksum" != "$oldchecksum" ]; then
		echo "Checksums are different: updating"
		DISPLAY=:0 notify-send -t 5000 "Corsair K90 $layout - $fonction" "Checksums are different, updating kernel" # Set your notify message here 
		mv /boot/efi/EFI/gentoo/vmlinuz_new.efi /boot/efi/EFI/gentoo/vmlinuz_old.efi
		mv /boot/efi/EFI/gentoo/vmlinuz_old.efi /boot/efi/EFI/gentoo/vmlinuz_old2.efi
		cp /usr/src/linux/arch/x86_64/boot/bzImage /boot/efi/EFI/gentoo/vmlinuz_new.efi
	else
		
		DISPLAY=:0 notify-send -t 3000 "Corsair K90 $layout - $fonction" "Checksums match, skipping kernel update" # Set your notify message here
	fi
	umount /boot/efi && umount /boot
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running	
	
###################################   M2   ###################################
458994) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=M2_-_Restart_X
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify -t 3000 "Corsair K90 $layout - $fonction" "Restarting X" # Set your notify message here
# Script
	/etc/init.d/xdm restart
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

###################################   M3   ###################################
458995) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=M3_-_Reboot
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Restarting System" # Set your notify message here
	/sbin/shutdown -r now
#######################################
	rm tmp/$fonction ;;  #Leave the rm, it is used by f_is_running

###################################  LOCK  ###################################
458996) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=Lock_-_Stop_SSH
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=0  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "SSHD stopped" # Set your notify message here
# Script
	/etc/init.d/sshd stop
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running	

################################### UNLOCK ###################################
458997) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=Unlock_-_Start_SSH
	checkifrunning=0  #if set to 1, prevents this subscript from running twice at the same time
	mustconfirm=0     #if set to 1, this action will require you to push a key to confirm the action.
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "SSHD started" # Set custom notify message here
#script
	/etc/init.d/sshd restart
#######################################
	rm tmp/$fonction ;; #Leave the rm, it is used by f_is_running

esac
# End of Speed Boost loop comes here
sleep $delay
seconds=$((seconds+delay))
done
##### If you like this script, please considerate donate domething to the Free Software Foundation, Debian, OpenBSD, ... or any other valuable open source project! Thanks ;)
exit
