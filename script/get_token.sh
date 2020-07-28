token=`curl -i -k -H 'Accept:application/json' -H 'Content-Type:application/json' -X POST -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'$user'","password":"'$password'","domain":{"name":"'$domain'"}}}},"scope":{"project":{"name":"'$project'"}}}}' $iam/v3/auth/tokens | grep X-Subject-Token | awk '{print $2}'`

export token=${token%?}
