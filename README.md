# Linux Custom Control Device (LCCD)
==================================

This little scripts objective is to support of some custom keyboards and mouses in linux.
A 100 enhancements are certainly possible, if you have ideas, please push patches ;)
It is its own readme, please read the file thoroughly, including comments; I tried to put as many as possible.
You might want to try the wiki for more example ^^

## Rights and responsabilities 

By using this program, you agree to all of the following
- getscancodes is published under GPL V2 (Like Marvin Raaijmakers' original source).  
- It is released under BSD licence
- I assume no responsabilities whatsoever for the consequences of running this program on your computer, it runs on mine, I share it, and it is your sole reponsability to use it.

## Required Files
LCCD_core.sh : the core script<br />
LCCD_conf: The base configuration file<br />
LCCD_Layout_K90_Blank: A blank layout (used by create function*)<br />
LCCD_Layout_K90_Admin: An example admin config<br />
LCCD_Triggers_K90 - file with the triggers that bind K90 keys<br />
getscancodes.c - getscancodes sources<br />
getscancodes.o - getscancodes sources<br />
Makefile - getscancodes makefile<br />

## Dependancies

  - To simulate keypresses, use either xmacro or xsendkeycodes, depending on your distribution.
  
User Communication is done trough libnotify and also depends on x11-apps/xhost
  - gentoo x11-libs/libnotify x11-apps/xhost
  - debian/*buntu libnotify-bin
  - redhat/fedora/centos libnotify
  - Windows, it was a pleasure, have a nice day!

make and GCC are required to compile getscancodes
The rest of the dependencies depend of your scripts.

This script heavily relies on a slightly modified version of getscancodes (original code by Marvin Raaijmakers).
"getscancodes", by Marvin Raaijmakers is available at http://keytouch.sourceforge.net/dl-getscancodes.html
However, the actual code of getscancodes does not allow for redirection, it needed the following change (Credits to Badger for finding the bug, and to Kon for fixing it): 
at line 92 of scancodes.c, replace 
	printf("%d (0x%x)\n", ev[i].value, ev[i].value);
with
	char buf[8]; sprintf(buf, "%d\n", ev[i].value); write(1, buf, sizeof(buf)); fsync(1);
This change is allready applied to the source I hereby provide, it allows to redirect it's output (changed the way it buffers), thus to collect the scancodes in a text file.

## Changelog
A line means it is incompatible with previous versions
-----------------------------------------------
	0.1 --> 0.5  	- Defining a logic, finding keycodes, testing stuff, ...
	0.6 -->		- Core debugging + first functiunnalities implemented:
			- Mute: switches the extended keyboard on/off
	  		- G1: make a hard disk checkup
			- G2: Launch all favourite apps
			- G13: Launch most recent [avi,mkv,mp4] in /home/jupiter/Downloads/
			- M1: update kernel
			- M2: restart X
			- M3: restart computer
			- Lock/Unlock: stop/restart sshd
	0.7 --> 0.8 	- core changes + more functiunnalities implemented
			- added f_select_latest - that allows to select the most recent files of a certain type.
			- Now G13 allows to launch the most recent movie between a choice of 4 folders.
			- Remapped the keys
			- Check periodic info (Test Website)
			- Backup Server
			- Flash Raspberry pi image on SD
			- Sync Android microSD
			- remount shm with exec
			- f_notify and echo support
			- Cleanups, cleanups, cleanups, ... 
	0.8--> 0.9999 	- Include the switch function in the script, to emulate original M1 M2 M3 behaviour
			- Include Speedup factor to make responsivity better for games
			- Include profile create option
			- Switched to UTF8 (forgot to setup kate in new OS installation)
			- Automatic compilation of getscancodes
			- Cheatsheet
			- Cleanups, cleanups, cleanups, and optimized code a bit (tnx again Kon)
-----------------------------------------------
	0.9999 --> 1.0	- Thanks to Hell4You for code review and improvement hints!
			- Changed $directory from user determined variable to auto detection
			- Changed $user from user determined variable to auto detection, though couldn't get the recommended 
			  ${USER} method to do the trick
			- Got the variables in a external config file

	1.0 --> 1.5	- Got the layouts in functions and put them in a separate file
			- Added debug mode for tracing issues

	1.5 --> 1.6	- cleaen up the code & comments (again :s)
			- added some functions with tee, making it easier to get the input
	1.6 --> 1.7     - Thanks to Nuxien for code review!
			- renamed $layout to $keybmode to avoid confusion - $keybmode is defined in the layout file itself.
			- cleaning and coherence checking for all the changes made so far since 1.0, corrected a few typos
			- removed .sh extension to avoid potential issues
			- Made a blank layout
			- Corrected some egrep functions
			- Fixed $user issues
			- 
			- adapt create and switch functions to new layout system
	1.7 --> 1.8	- corrected create and switch functions to new layout system for real this time!
			- added "list" argument to get list of layouts
			- corrected a few checks in the getscancodes compilation process
	1.8 --> 1.9	- Fixed an issue with initcache, and implemented f_initcache reset
			- Tested xsendkeycode so emulate keystrokes - it works great 
			- Thanks to r2d290 for constructive feedback - fixed a few bugs
-----------------------------------------------
	1.9 --> 3.0	- Changed getscancodes.c buffer (finally) - this version is not compatible with the previous ones
			- Thanks to nuxien for the c fix ;)
			- Cleaned github
			- Cleaned the code a lot
			- Renamed from K90 to Linux Custom Control Device
			- Remade readme a bit
	3.0 --> 3.1	- Added support for various devices
	3.1 --> 3.1.1   - Corrected a bug by load layout one extra time
## Todo 


## Bugs 

- When catching the custom keys, 3 of the 18 make some noise on the primary channel: these are G9 G17 and G18.  There's not much I can think of to solve this issue, so the best option in my opinion is not to use them. (G17 does play/pause and G18 stop on Amarok)
- I think sometimes the keyboard sends the lock/unlock signal without my hitting the key (I can see the OSD information)
- Certainly many more bugs :p

## Usage 

./getscancodes /dev/event/inputXX

## Options

./LCCD_core.sh create ProfileName 
Create a blank profile named "ProfileName" (avoid spaces and special characters in profile name)

./LCCD_core.sh switch# 
Switch to next profile (we're not limited to 3 profiles, so create an extra profile rather than editing the blank one.)
