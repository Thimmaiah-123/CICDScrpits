#!/bin/bash
# auto_run.sh
# run changed files automatically, the effective files can be pre-defined by a config file
# command auto_run.sh [-c config file] dirname

# set workspace
#cd `dirname $0`

# file_stats dict used to store the stat of checked files
declare -A file_stats
file_stats=()
_dir='.'
pos_list=()
neg_list=()
# config_file=$(cd $(dirname $0);pwd)'/ignore.conf'
config_file=""
do_something=$(cd $(dirname $0);pwd)'/do_something.sh'
rules=$(cd $(dirname $0);pwd)'/rules.json'
env_conf='env.conf'

usage(){
    echo "Usage:"
    echo "auto_run.sh [-c config file] [-r rules-json] [-e env config] dirname"
    exit -1
}
args="`getopt -u -q -o "c:e:hr:" -l "config,help" -- "$@"`" 
[ $? -ne 0 ] && usage

set -- ${args}

while [ -n "$1" ]; do
    case "$1" in
        -c|--config) config_file=$2
            shift;;

        -e) env_conf=$2
            shift;;

        -h|--help)
            usage
            shift;;

        -r) rule=$2
            shift;;

        --) shift
            break;;
        *) usage
    esac
    shift
done

# set dirname
for param in "$@"; do
    _dir=$param
    if [[ "${_dir:${#_dir}-1:1}" != "/" ]]; then 
        _dir=${_dir}/
    fi
done

# read out pos_list and neg_list
_dir0=$(pwd)
cd $_dir
if [[ -z "$config_file" ]]; then
    if [[ -e "ignore.conf" ]]; then
        config_file=$(pwd)"/ignore.conf"
    else
        config_file=$_dir0"/ignore.conf"
    fi
fi
while read line; do

    if [ "$line" == "positive" ]; then
        tag="pos"
        continue
    fi

    if [ "$line" == "negative" ]; then
        tag="neg"
        continue
    fi

    if [ "$tag" == "pos" ]; then
        pos_list+=($line)
        continue
    fi

    if [ "$tag" == "neg" ]; then
        neg_list+=($line)
        continue
    fi

done < $config_file

if [ -e $env_conf ]; then
    _env=$(cat $env_conf)
else
    _env="none"
fi
cd $_dir0

read_dir(){
    # find out the updated file        
    for f in `ls $1`; do
        #echo $1 $f
        if [ -d $1$f ]; then
            if echo "${neg_list[@]}" | grep -w "$f" &>/dev/null; then
                #echo $1$f
                continue
            fi
            read_dir $1$f/
            
        else
            #check if files changed here and do something more
            #_stat=`stat $1"/"$f|grep Modify:`
            # file_stats+=([$1"/"$f]="$_stat")
            # process the changed files
            # get the extension
            str=$1$f
            ext=${str##*.}
            # check if the file is in the neg_list
            if echo "${neg_list[@]}" | grep -w "$ext" &>/dev/null; then
                need_check=0
            elif echo "${neg_list[@]}" | grep -w "$f" &>/dev/null; then
                need_check=0
            else
                # if pos_list is empty
                if [ ${#pos_list[@]} -eq 0 ]; then
                    need_check=1
                else
                    # check if the file is in the pos_list
                    if echo "${pos_list[@]}" | grep -w "$ext" &>/dev/null; then
                        need_check=1
                    else
                        need_check=0
                    fi
                fi

            fi
            # if need check, do something here
            if [ $need_check -eq 1 ]; then
                tmp_name=$1$f
                tmp_stat=`stat $tmp_name|grep Modify:`
                if [ -z "${file_stats[$tmp_name]}" ]; then
                    file_stats[$tmp_name]=$tmp_stat
                else
                    if [ "${file_stats[$tmp_name]}" != "$tmp_stat" ]; then
                        _env_tmp=$_env
                        source $do_something $tmp_name $_env_tmp $rules $_dir
                        file_stats[$tmp_name]=$tmp_stat
                    fi
                fi
            fi

        fi
    done
}
while true; do
    need_check=0
    read_dir $_dir
    sleep 1
done
