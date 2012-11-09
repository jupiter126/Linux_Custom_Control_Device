#!/bin/bash
if [ "x$1" = "x" ]; then # Launch with arguments if any
        echo "No arguments detected, exiting"
        exit 0
elif [ $1 = "switch" ]; then
        f_switch
elif [ $1 = "create" ]; then
        f_create "$2"
elif [ $1 = "list" ]; then
        f_list
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
        echo "Unknown Argument: $1"
fi
