#!/bin/zsh

# Remove latex extenion files that bloat the directory

for file in main.aux main.bbl main.fdb_latexmk main.fls main.log main.nav main.out main.snm main.synctex.gz main.toc 
do
	[ ! -e $file ] || rm $file

done
