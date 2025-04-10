#! /bin/bash

## Bash Script to set up a second screen 

mirror() {
	xrandr --output HDMI-A-0 --auto --same-as eDP
	feh --bg-fill ~/.config/i3/wallpaper/endeavour_pillarsofcreation.png
}

secondary() {
	xrandr --output HDMI-A-0 --auto --primary
	xrandr --output eDP --off
	feh --bg-fill ~/.config/i3/wallpaper/endeavour_pillarsofcreation.png
}

secondary_right() {
	xrandr --output HDMI-A-0 --auto --right-of eDP
	feh --bg-fill ~/.config/i3/wallpaper/endeavour_pillarsofcreation.png
}

secondary_right_lr() {
	xrandr --output HDMI-A-0 --scale 1.25x1.25 --dpi 96 --right-of eDP
	feh --bg-fill ~/.config/i3/wallpaper/endeavour_pillarsofcreation.png
}

help() {
	echo "This bash script sets up a second screen. Options:"
	echo "mirror 		-- 		Set up the second screen as a mirror of the first."
	echo "right 		-- 		Set up the second screen to the right of the first."
	echo "right_lowres  --      Set up second screen to the right with low resolution."
}


case $1 in
	help)
	help
	;;	
	
	h)
	help
	;;

	mirror)
	# Set mirror
	mirror
	;;

	secondary)
	# Set only secondary
	secondary
	;;

	right)
	# Set to the right
	secondary_right
	;;

	right_lr)
	secondary_right_lr
esac
