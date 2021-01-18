mkdir -p logs
{
currentTimeStamp=`date +%s.%2N`

prometheus_url=http://`kubectl get svc prometheus-server-1 -ojsonpath="{..ip}"`:9090
node1=`kubectl get pods -l app=node-exporter-1 -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"`
#node2=`KUBECONFIG=/root/.kube/config.c kubectl get pods -l app=node-exporter-1 -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"`

#prometheus_url=http://172.16.17.175:9090
#node1="10.252.2.114 10.252.2.13 172.16.123.164 172.16.242.184 172.16.250.75"
node2=""
for node in $node1 $node2; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done
} > logs/e-`date +%Y-%m-%d'_'%H:%M:%S`.log
