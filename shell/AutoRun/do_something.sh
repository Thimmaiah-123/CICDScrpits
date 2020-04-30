#!/bin/bash
# do something if the checked file is changed
fn=$1
_env_tmp=$2
rules=$3
ws=$4
ext=${fn##*.}
# set env in file
tmp=$(cat $fn | grep "#@env: " | tail -n 1)
tmp=$(echo "$tmp" | sed 's/#@env: \(.*\)/\1/g')
if [ -n "$tmp" ]; then
    _env_tmp=$tmp
fi
# read rules
if [ "$_env_tmp" == "none" ]; then
    keys=$(cat $rules | jq 'keys')
    keys=$(echo $keys | sed 's/\[//g' | sed 's/\]//g')
    keys=$(echo $keys | sed 's/ //g' | sed 's/\"//g')
else 
    keys=$_env_tmp
fi
IFS_OLD=$IFS
IFS=$'\,'
for key in $keys; do
    full=$(cat $rules | jq ".$key.full" | sed 's/\"//g')
    rule_ext=$(cat $rules | jq ".$key.ext" | sed 's/\"//g')
    cmd=$(cat $rules | jq ".$key.cmd" | sed 's/\"//g')
    if [[ "$full" == "$(basename $fn)" ]] || [[ "$ext" == "$rule_ext" ]] || [[ "$full" == "all" ]]; then
        eval $cmd
        sleep 30
        break
    fi

done
IFS=$IFS_OLD

