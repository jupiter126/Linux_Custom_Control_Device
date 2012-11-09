#!/bin/bash

# If there is no line "layout=XXXXX" up here, then this is the skeleton config and you shouldn't edit it, rather use "K90_script.sh create NameOfNewLayout", and edit that one ;)
# In addtion of being a skeleton for new layouts, the blank can serve as safeguard when guests or kids ure your computer.
###########################
# I N T R O D U C T I O N #
###########################
# This little script is a dirty quickhack by me (JuPiTeR)-(really, 4 days of noobswork - it is literally the second script of more than 50 lines that I write, 
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
#	- K90-script-0.9999-RC1.sh
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
# User Communication is done trough libnotify
#   - gentoo x11-libs/libnotify
#   - debian/*buntu libnotify-bin
#   - redhat/fedora/centos libnotify
#   - Windows, it was a pleasure, have a nice day!

# make and GCC are required to compile getscancodes
# The rest of the dependencies depend of your scripts.

###########
# T O D O #
###########
#- Go on Holliday \o/
#- Find how I emulate a sequence of keys? not sure (xmacro or xsendkeycode), and send it to a running game? --> the missing link to version 1.0

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
while [ "$seconds" -le "60"  ]
do
echo "Timer is at $seconds seconds and repeats every $delay until 60"
#The end of this function is at the bottom of the whole script.

#####################
# V A R I A B L E S #
#####################

# Tell the script where it is (there must be some smarter way :s)
# Con't put a trailing / or f_create will fail!
directory="/home/jupiter/K90_Linux"

#Where is the cache file to be placed (I put it in RAM to avoid excessive HDD IO access)
cachefile="/tmp/corsair_k90_getscancodes"

#Which device event is your keyboard?  This might require a bit of trial and error to find out.
#here's how I did, 
#1. Look in /dev/input/by-path to find which events link to your keyboard (event-kbd)
# ls -al /dev/input/by-path/
#   	lrwxrwxrwx 1 root root  10 Sep  3 02:22 pci-0000:00:1a.0-usb-0:1.4:1.0-event-mouse -> ../event11
#	lrwxrwxrwx 1 root root   9 Sep  3 02:22 pci-0000:00:1a.0-usb-0:1.4:1.0-mouse -> ../mouse0
#	lrwxrwxrwx 1 root root  10 Sep  3 02:22 pci-0000:00:1a.0-usb-0:1.4:1.1-event-kbd -> ../event12
#	lrwxrwxrwx 1 root root  10 Sep  3 02:22 pci-0000:00:1d.0-usb-0:1.8:1.0-event-kbd -> ../event13
#	lrwxrwxrwx 1 root root  10 Sep  3 02:22 pci-0000:00:1d.0-usb-0:1.8:1.1-event -> ../event14
#	lrwxrwxrwx 1 root root  10 Sep  3 02:22 pci-0000:00:1d.0-usb-0:1.8:1.2-event-kbd -> ../event15
#2. Use getscancodes to try the different event interfaces and while it runs, hit some Gx buttons.
#   Once you're on the right event, you should see some nice control codes (on Gx keys, not standard), corresponding to your keys like this:
#	./getscancodes /dev/input/event13
#	Input driver version is 1.0.1
#	Input device ID: bus 0x3 vendor 0x1b1c product 0x1b02 version 0x111
#	Input device name: "Corsair Corsair Vengeance K90 Keyboard"
#	458960				#--> This is the code you're supposed to get for G1
#	458960
#	458961				#--> This is the code you're supposed to get for G2
#	458961
#If not, try another event ^^ - 
#Once you found your correct event device, set this variable to the right value:
eventnbr="/dev/input/event13"

# Libnotify ?
# If set on 1, the script will try to set DBUS_SESSION_BUS_ADDRESS, so that notifications are pushed trough OSD to the right user.
# If set on 0, I should code some echo feedback for console use.
# For this to work, you need to specify the username AND an application that that user is running in X.
libnotify="1" # 1 for yes, 0 for no - Use it to get informed trough OSD (depends on libnotify)
user="jupiter" #name of the user that must be notified
appli="firefox" #name of the application he is supposed to be running (is used to get DBUS_SESSION_BUS_ADDRESS)

###############
# S C R I P T # Think twice before modyfing in this section
###############
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
	fonction=G01_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G2   ###################################	
458961) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G02_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G3   ###################################
458962) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G03_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G4   ###################################
458963) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G04_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G5   ###################################
458964) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G05_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G6   ###################################
458965) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G06_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G7   ###################################
458966) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G07_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G8   ###################################
458967) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G01_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G9   ###################################
458968)
	#I expect unexpected bugs on this key due to noise data it sends on another event
	echo "I would try to avoid this key" ;;

###################################   G10  ###################################
458969) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G10_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G11  ###################################
458970) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G11_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G12  ###################################
458971) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G12_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G13  ###################################
458972) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G13_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G14  ###################################
458973) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G14_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G15  ###################################
458974) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G15_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G16  ###################################
458975) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=G16_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   G17  ###################################
458984)
	#USE WITH CAUTION... I experienced unexpected bugs on this key due to noise data sent on another event
	echo "I would try to avoid this key" ;;
	
###################################   G18  ###################################
458985)
	#USE WITH CAUTION... I experienced unexpected bugs on this key due to noise data sent on another event
	echo "I would try to avoid this key" ;;

###################################   M1  ####################################
458993)  # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=M1_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   M2   ###################################
458994) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=M2_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################   M3   ###################################
458995) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=M3_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

###################################  LOCK  ###################################
458996)  # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=Lock_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

################################### UNLOCK ###################################
458997) # give $fonction an understandable name and use "_-_" --> This is used for "cheatsheet"
	fonction=Unlock_-_Unused_So_Far 
	# Start of options  ------------------>  FILL THESE TWO LINES FOR EACH KEY !!!
	checkifrunning=1  #if set to 1, prevents this script from running twice at the same time
	mustconfirm=1     #if set to 1, this action will require you to push a key to confirm the action.
	# End of Options
	f_is_running $fonction
	f_confirm $fonction
	f_libnotify 3000 "Corsair K90 $layout - $fonction" "Your text here" # Set your notify message here
############################  Start of G1 script
# This is the proper script that will be launched when G1 is hit.
	  echo "awesome code"
	  f_libnotify 3000 "Corsair K90 $layout - $fonction" "Awesome code executed" # Set your notify message here
############################  End of G1 script
	rm tmp/$fonction ;; #Leave this rm, it is used by f_is_running

esac
# End of Speed Boost loop comes here
sleep $delay
seconds=$((seconds+delay))
done
##### If you like this script, please considerate donate domething to the Free Software Foundation, Debian, OpenBSD, ... or any other valuable open source project! Thanks ;)
exit