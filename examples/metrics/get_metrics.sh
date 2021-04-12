
prometheus_url=${prometheus_url:-http://`kubectl get svc prometheus-server-1 -ojsonpath="{..ip}"`:9090} 
nodes=`kubectl get pods -l app=$server -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

currentTimeStamp=`date -d '-60 minute' +%s.%2N`
for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done

for nodec in $nodec_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodec
done
