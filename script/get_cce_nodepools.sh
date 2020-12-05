pools=`curl -s -k -H 'Content-Type:application/json' -H "X-Auth-Token: $token" -X GET $cce/api/v3/projects/${project_id}/clusters/${cluster_id}/nodepools | python -m json.tool`

mkdir -p doc
echo "$pools" > doc/pools.json

echo "$pools" |grep -A 3 'NodePool'|grep -e "name" -e "id"
