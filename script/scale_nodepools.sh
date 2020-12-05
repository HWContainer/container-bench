function scaleup(){
nodepool_id=$1
replicas=$2

nodepool=`curl -s -k -H 'Content-Type:application/json' -H "X-Auth-Token: $token" -X GET $cce/api/v3/projects/${project_id}/clusters/${cluster_id}/nodepools/${nodepool_id}|python -m json.tool`
mkdir -p doc
echo "$nodepool" > doc/nodepool-$nodepool_id.json

echo "`date +%Y-%m-%d' '%H:%M:%S.%N`  begin scale: $nodepool_id"
echo "$nodepool" |grep -e '"name"' -e initialNodeCount

nodepool=`sed 's/"initialNodeCount":.*,/"initialNodeCount": '$replicas',/g' doc/nodepool-$nodepool_id.json`
ret=`curl -s -k -H 'Content-Type:application/json' -H "X-Auth-Token: $token" -X PUT $cce/api/v3/projects/${project_id}/clusters/${cluster_id}/nodepools/${nodepool_id} -d "$nodepool" |python -m json.tool`
echo "$ret" > doc/ret-$nodepool_id.json

echo "`date +%Y-%m-%d' '%H:%M:%S.%N`  end   scale: $nodepool_id"
echo "$ret" |grep -e '"name"' -e initialNodeCount
}

count=$1
pool1=$2
pool2=$3
pool3=$4
pool4=$5

echo count:    $count
echo poo11:    $pool1
echo poo12:    $pool2
echo poo13:    $pool3
echo poo14:    $pool4

scaleup $pool1 $count
sleep 15
scaleup $pool2 $count
sleep 46
scaleup $pool3 $count
sleep 15
scaleup $pool4 $count
