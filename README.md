k90-test
========
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
#-----------------------------------------------
#	0.9999 RC3 --> 1.0	Thanks to Hell4You for code review and improvement hints!
#			- Changed $directory from user determined variable to auto detection
#			- Changed $user from user determined variable to auto detection, though couldn't get the recommended ${USER} method to do the trick
#			- Got the variables in a external config file

#	1.0 --> 1.5	- Got the layouts in functions and put them in a separate file
#			- Added debug mode for tracing issues

#	1.5 --> 1.6	- cleaen up the code & comments (again :s)
#			- added some functions with tee, making it easier to get the input

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
