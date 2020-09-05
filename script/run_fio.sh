pod_name=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].metadata.name}'`
node_ip=`kubectl get pods --selector app=perf-test-1 -o jsonpath='{.items[0].status.hostIP}'`
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /home/paas/fio -ioengine=libaio -group_reporting -direct=1 -rw=write -bs=1024k -iodepth=32 -size=50G -name=/tmp/evs0/kd4kqzfc/fiotest
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /home/paas/fio -ioengine=libaio -group_reporting -direct=1 -rw=randwrite -bs=4k -iodepth=32 -numjobs=1 -runtime=180  -time_based -size=50G -name=/tmp/evs0/kd4kqzfc/fiotest
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /home/paas/fio -ioengine=libaio -group_reporting -direct=1 -rw=randread -bs=4k -iodepth=32 -numjobs=1 -runtime=180 -time_based -size=50G -name=/tmp/evs0/kd4kqzfc/fiotest
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /home/paas/fio -ioengine=libaio -group_reporting -direct=1 -rw=write -bs=1024k -iodepth=32 -runtime=180 -time_based -size=50G -name=/tmp/evs0/kd4kqzfc/fiotest
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip
currentTimeStamp=`date +%s.%2N`
kubectl exec $pod_name -- /home/paas/fio -ioengine=libaio -group_reporting -direct=1 -rw=read -bs=1024k -iodepth=32 -runtime=180 -time_based -size=50G -name=/tmp/evs0/kd4kqzfc/fiotest
sleep 30
python query_csv.py $prometheus_url $currentTimeStamp $node_ip

