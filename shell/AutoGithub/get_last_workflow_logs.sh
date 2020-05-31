#!/bin/bash
# get_last_workflow_logs.sh
# download last run logs of the specified workflow
# command: get_last_workflow_logs.sh [-t access token] [-r repo name: user/repo] [-o output] workflow name
token=''
workflow=''
repo=''
output="logs.zip"

usage(){
    echo "Usage:"
    echo "get_last_workflow_logs.sh [-t access token] [-r repo name: user/repo] [-o output] workflow name"
    exit -1
}
args="`getopt -u -q -o "ho:r:t:" -l "help" -- "$@"`" 
[ $? -ne 0 ] && usage
set -- ${args}

while [ -n "$1" ]; do
    case "$1" in
        -h|--help)
            echo $1
            usage
            shift;;

        -o) output=$2
            shift;;

        -r) repo=$2
            shift;;

        -t) token=$2
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
cd $old_dir
res=$(curl --request GET -s \
    --header "authorization: Bearer $token" \
    -o $output -L \
    https://api.github.com/repos/$repo/actions/runs/$id/logs)
