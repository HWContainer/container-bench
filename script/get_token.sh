echo input: $user $domain $password $project
token=`curl -s -i -k -H 'Accept:application/json' -H 'Content-Type:application/json' -X POST -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'$user'","password":"'$password'","domain":{"name":"'$domain'"}}}},"scope":{"project":{"name":"'$project'"}}}}' $iam/v3/auth/tokens | grep X-Subject-Token | awk '{print $2}'`

mkdir -p doc
echo "$token" > doc/token.json
export token=${token%?}

session=`curl -s -k -H 'Accept:application/json' -H 'Content-Type:application/json' -X POST -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'$user'","password":"'$password'","domain":{"name":"'$domain'"}}}},"scope":{"project":{"name":"'$project'"}}}}' $iam/v3/auth/tokens |python -m json.tool`

mkdir -p doc
echo "$session" > doc/session.json

project_id=`echo "$session"|grep -A 6 '"project":'|grep '"id":'|grep -n id |grep 2:|awk -F '"' '{print $4}'`
cce_ep=`echo "$session"|grep '//cce'`
echo project_id: $project_id
echo cce: $cce_ep

export project_id=${project_id}
