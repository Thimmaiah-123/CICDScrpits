#!/bin/bash
# rerun_last_workflow.sh
# rerun last run of the specified workflow
# command: rerun_last_workflow.sh [-t access token] [-r repo name: user/repo] [-o output] workflow name
token=''
workflow=''
repo=''

usage(){
    echo "Usage:"
    echo "rerun_last_workflow.sh [-t access token] [-r repo name: user/repo] [-o output] workflow name"
    exit -1
}
args="`getopt -u -q -o "ho:r:t:" -l "help" -- "$@"`" 
[ $? -ne 0 ] && usage
set -- ${args}

while [ -n "$1" ]; do
    case "$1" in
        -h|--help)
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


res=$(curl --request GET -s \
    https://api.github.com/repos/$repo/actions/workflows)
res=$(echo "$res" | egrep  "\"id\"|\"$workflow\""  )
n=$(echo "$res" | grep -n "$workflow" | cut -f1 -d:)
((n=n-1))
id=$(echo "$res" | sed -n "${n}p" | sed 's/.*id": \(.*\),/\1/g')
res=$(curl --request GET -s \
    https://api.github.com/repos/$repo/actions/workflows/$id/runs)
res=$(echo "$res" | grep "\"id\"")
run_id=$(echo "$res" | sed -n '1p' | sed 's/.*id": \(.*\),/\1/g')
status=$(curl --request GET -s \
    https://api.github.com/repos/$repo/actions/runs/$run_id)
status=$(echo "$status" | grep \"status\" | sed 's/.*status": "\(.*\)",/\1/g')

if [[ "completed" == "$status" ]]; then
    res=$(curl --request POST -s \
        --header "authorization: Bearer $token" \
        https://api.github.com/repos/$repo/actions/runs/$run_id/rerun
        )
    echo 1
else
    echo 0
fi
