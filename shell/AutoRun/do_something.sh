#!/bin/bash
# do something if the checked file is changed
str=$1
ext=${str##*.}
if [ "$ext" == "py" ]; then
    python $1
fi
