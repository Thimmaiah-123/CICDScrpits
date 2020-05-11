#!/bin/bash
# define your actions and strategies here. Do something if the checked file is changed.

fn=$1
old_ws=`pwd`
ext=${fn##*.}
if [ "$ext" == "py" ]; then
    comment=("#" "\"" "'")
else
    comment=("#")
fi

# check if updated file is tracked
signed=$(cat $fn | grep '#@git' | head -n 1)
if [ -n "$signed" ]; then
    git ls-files --error-unmatch $fn &> /dev/null
    tracked=$?
    if [ $tracked -eq 1 ]; then
        tracked=0
    else
        tracked=1
    fi
else
    return
fi


cd `dirname $fn`
branch=`cat $fn | grep '#@git branch' | tail -1`
branch=${branch##*git branch}
branch=`eval echo $branch`
branches=`git branch`
checked_branch=`echo "$branches" | grep $branch &> /dev/null`

if [ -z "$branch" ]; then
    :
elif [ -z "$checked_branch" ]; then
    echo "branch '$branch' doesn't exist"
elif [ "${checked_branch:0:1}" == "*" ]; then
    :
else
    git checkout $branch
fi

# check git diff
txt=$(git diff $fn)
seg=($(echo "$txt" | grep -n "@@" | cut -d ":" -f 1))

# find out corresponding block in the updated file
block=()
i=0
len=${#seg[@]}
n_lines=$(echo "$txt" | wc -l)
seg[${#seg[@]}]=$n_lines
while [ $i -lt $len ]; do
    line0=${seg[$i]}
    line1=${seg[$(expr $i + 1)]}
    to1=$(expr $line1 - $line0)
    
    tmp=$(echo "$txt" | tail -n +$line0)
    tmp=$(echo "$tmp" | head -n $to1)
    block[$i]="$tmp"
    i=`expr $i + 1`
done
# generate commit info and commit
commit_info=''
for(( i=0; i<${#block[@]};i++ )); do
    info=''
    rest_info=''
    start=$(echo "${block[$i]}" | grep @@)
    start=${start#*,}
    start=${start%%,*}
    start=${start#*+}
    start=$(expr $start + 3)
    cnt=0

    tmp=$(echo "${block[$i]}" | head -n -2)
    tmp=$(echo "$tmp" | tail -n +5)
    
    origin=$tmp
    tmp=$(echo "$tmp" | grep -E '^(\+|\-)')
    echo "$tmp"|while read line; do
        line=${line:1}
        line=$(echo $line | sed 's/^[\t]*//g')
        if [ -z "$line" ]; then
            cnt=$(expr $cnt + 1)
            continue
        elif [ -n "$(echo $line | grep "#@git:")" ]; then
            break
        elif echo "${comment[@]}" | grep -w "${line:0:1}" &>/dev/null; then
            cnt=$(expr $cnt + 1)
            continue
        else 
            break
        fi
    done
    start=$(expr $start + $cnt)
    last_info=$(head -n $start $fn | grep "#@git:<" | tail -n 1)
    
    first_diff=$(echo "$tmp" | head -n 1)
    if [ -n "$(echo $first_diff | grep "#@git:")" ] && [ -z "$(echo $first_diff | grep "#@git:<")" ]; then
        info=$last_info"\n"$first_diff
        header_exists=0
    else
        info=$last_info
        header_exists=1
    fi
    echo "$origin"
    rest_info=$(echo "$origin" | tail -n +2 | grep "#@git:")
    info=$info"\n"$rest_info
    info=$(echo -e "$info" | sed 's/\+.*\#\@git:</add </g')
    info=$(echo "$info" | sed 's/\-.*\#\@git:</delete </g')
    info=$(echo "$info" | sed 's/.*\#\@git://g')
    info=$(echo "$info" | sed -e '/<.*>/ {h}' -e 's/.*\(<.*>\).*$/\1/g; /<.*>/ {x}; /[^<.*>]/ {G}; s/\n/ \|/')
    if [[ header_exists -eq 0 ]]; then
        echo here
        info=$(echo "$info" | tail -n +2)
    fi
    commit_info=$commit_info"\n"$info
done
commit_info=$(echo -e "$commit_info" | sed 's/^ *//g')

if [ $tracked -eq 0 ]; then
    commit_info="add $(basename $fn)"
    txt=filled
fi
# add and commit
if [ -n "$txt" ] && [ -n "$commit_info" ]; then
    git add $fn
    git commit -m "$commit_info" 
# check if squash the latest two commits
    logs=$(git log -n 2)
    logs=$(echo "$logs" | grep "^\ ")
    new_logs=$(echo "$logs" | sed 's/^ *//g' | sort -n| uniq)
    logs=$(echo "$logs" | sed 's/.*|\(<.*>\)/\1/g')
    logs=$(echo "$logs" | sort -n | uniq)
    n_lines=$(echo "$logs" | wc -l)
    if [[ $n_lines -eq 1 ]]; then
        git reset --soft HEAD~2
        git commit -m "$new_logs"
    fi
    
# check if push
    id=$(git log -n 4 | grep '^commit ')
    num_lines=$(echo "$id" | wc -l)
    if [[ $num_lines -eq 4 ]]; then
        id=$(echo "$id" | tail -n -1 | sed 's/^commit \(.*\)/\1/g')
        checked_label=$(git log --pretty=format:“%s” $id -1 |  sed 's/.*|\(<.*>\).*/\1/g' )
        rest_labels=$(git log -n 3 | grep '^\ ' | sed 's/.*|\(<.*>\).*/\1/g' | sort -n | uniq) 
        n1=$(echo "$rest_labels" | wc -l)
        labels=$checked_label"\n"$rest_labels
        n2=$(echo "$labels" | wc -l)
        if [[ $n1 -ne $n2 ]]; then
            git pull
            git push $id
        fi
        
    fi

fi
echo ---------
cd $old_ws
