workflow=$1
repo=$2
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
echo $run_id

