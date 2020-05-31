#!/bin/bash
# check_last_workflow_status.sh
# check status of last run of the workflow
# command: check_last_workflow_status.sh [-r repo name: user/repo]  workflow name
workflow=''
repo=''
output="logs.zip"

usage(){
    echo "Usage:"
    echo "get_last_workflow_logs.sh [-r repo name: user/repo] workflow name"
    exit -1
}
args="`getopt -u -q -o "hr:" -l "help" -- "$@"`" 
[ $? -ne 0 ] && usage
set -- ${args}

while [ -n "$1" ]; do
    case "$1" in
        -h|--help)
            usage
            shift;;

        -r) repo=$2
            shift;;

        --) shift
            break;;

        *) echo $1;usage
    esac
    shift
done

for param in "$@"; do
    workflow=$workflow$param
    workflow="$workflow "
done
workflow=${workflow:0:${#workflow}-1}

old_dir=`pwd`
cd $(dirname $0)
id=$(bash get_last_workflow_id.sh "$workflow" $repo)
status=$(curl --request GET -s \
    https://api.github.com/repos/$repo/actions/runs/$id)
status=$(echo "$status" | grep \"status\" | sed 's/.*status": "\(.*\)",/\1/g')
cd $old_dir
echo $status
