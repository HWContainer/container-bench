clusters=`curl -k -H 'Content-Type:application/json' -H "X-Auth-Token: $token" -X GET $cce/api/v3/projects/${project_id}/clusters?status=Available 2>/dev/null |python -m json.tool`

mkdir -p doc
echo $clusters > doc/clusters.json

cluster_id=`echo "$clusters"|grep -A 1 $1 |grep uid | awk -F '"' '{print $4}'`

echo clusterid: $cluster_id
export cluster_id=${cluster_id}

