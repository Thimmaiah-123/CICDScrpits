token=$1
key=$2
value=$3
repo=$4
echo $token

res=$(curl --request GET \
     --header "authorization: Bearer $token" \
     https://api.github.com/repos/$repo/actions/secrets/public-key)
echo "$res"
pub_key=$(echo "$res" | grep \"key\" | sed 's/.*"key": "\(.*\)"/\1/g')
key_id=$(echo "$res" | grep key_id | sed 's/.*"key_id": "\(.*\)",/\1/g')
echo $key_id
encrypted=$(python3 gen_encrypted.py $pub_key $value)
echo $encrypted
curl --request PUT \
     --header "authorization: Bearer $token" \
     --header 'content-type: application/json' \
     --data "{\"encrypted_value\":\"$encrypted\", \"key_id\": \"$key_id\"}" \
     https://api.github.com/repos/$repo/actions/secrets/$key

