#!/bin/bash
dir="$1"
GREEN="\033[32m"
YELLOW="\033[33m"
NORMAL="\033[0;39m"
# No directory has been provided, use current
if [ -z "$dir" ]
then
    dir="`dirname $0`/../apps/"
fi
# Make sure directory ends with "/"
if [[ $dir != */ ]]
then
	dir="$dir/*"
else
	dir="$dir*"
fi
for item in $dir
do
	if [ -d $item ] && [ -d "${item}/.git" ]; then
		(
			cd $item;
			repo=$(basename `git rev-parse --show-toplevel`)
			branch=$(git rev-parse --abbrev-ref HEAD)
			if [ $branch == "master" ];
			then
				branch_colour=$NORMAL
			else
				branch_colour=$YELLOW
			fi
			echo -e "${GREEN} ${repo} ${NORMAL} -> ${branch_colour} ${branch}"
		);
	fi
done
