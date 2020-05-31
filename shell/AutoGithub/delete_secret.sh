token=$1
key=$2
repo=$3

curl --request DELETE \
     --header "authorization: Bearer $token" \
     https://api.github.com/repos/$repo/actions/secrets/$key
