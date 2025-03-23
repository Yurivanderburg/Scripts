#!/bin/zsh


for year in "2024" "2025" 
do
	# Update Sync_Android folder
	rsync -a --info=progress2 --no-inc-recursive ~/Pictures/Photography/$year/*/output/*.jpg ~/Pictures/Photography/Sync_Android/$year/

done

