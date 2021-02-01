set -x
nodes=`kubectl get pods -l app=$server -ojsonpath="{range .items[*]}{..hostIP}{' '}{end}"|tr ' ' '\n'|sort|uniq`

currentTimeStamp=`date +%s.%2N`
sleep 60
for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done

for nodec in $nodec_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodec
done
# invoke 
currentTimeStamp=`date +%s.%2N`
for nodec in $nodec_ip; do
{
ssh -i key.pem -oStrictHostKeyChecking=no root@$nodec >$nodec.log 2>&1 ./fortio load -k -qps $qps -c $connect -t 120s --keepalive=false $svc_ip
} &
done
wait 

for nodec in $nodec_ip; do
cat $nodec.log
done

# get metrics
for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done

for nodec in $nodec_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodec
done
sleep 60

currentTimeStamp=`date +%s.%2N`
if [[ "$nodec_ip" == "127.0.0.1" ]]; then
fortio load -qps $qps -c $connect -t 120s $svc_ip
else
for nodec in $nodec_ip; do
{
ssh -i key.pem -oStrictHostKeyChecking=no root@$nodec >$nodec.log 2>&1 ./fortio load -k -qps $qps -c $connect -t 120s $svc_ip
} &
done
wait
for nodec in $nodec_ip; do
cat $nodec.log
done
fi

for node in $nodes; do
python query_csv.py $prometheus_url $currentTimeStamp $node
done

for nodec in $nodec_ip; do
python query_csv.py $prometheus_url $currentTimeStamp $nodec
done
