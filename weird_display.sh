#!/bin/zsh

xrandr --newmode "1280x720_60.00"  74.48  1280 1336 1472 1664  720 721 724 746  -HSync +Vsync

xrandr --addmode HDMI-A-0 1280x720_60.00

xrandr --output HDMI-A-0 --mode 1280x720_60.00
