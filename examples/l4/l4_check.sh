az3_sc=server-az3-lat-1
az3_sh=serverhost-az3-lat-1
az7_sc=server-az7-lat-1
az7_sh=serverhost-az7-lat-1

az3_ch=clienthost-az3-lat-1
az3_cc=client-az3-lat-1
az3_ch_local=clienthost-az3-local-1
az3_cc_local=client-az3-local-1
az7_ch=clienthost-az7-lat-1
az7_cc=client-az7-lat-1
az7_ch_local=clienthost-az7-local-1
az7_cc_local=client-az7-local-1

function kill_servers(){
    local server=$1
    kubectl exec $server -nexample -- bash -c 'pkill -9 qperf; pkill -9 iperf; pkill -9 netperf'
    echo "$server process:"
    kubectl exec $server -nexample -- bash -c 'ps -ef|grep -e qperf -e iperf -e netperf'
}

function start_servers(){
    local server=$1
    # lat
    kubectl exec $server -nexample -- bash -c 'cd /home/paas/; ./qperf &'
    # throughput
    kubectl exec $server -nexample -- bash -c 'cd /home/paas/; for ((i=6000; i<'$((10+6000))';i++)); do { /home/paas/netserver -p $i >/log.$i 2>&1; }& done'
    # pps
    kubectl exec $server -nexample -- bash -c 'cd /home/paas/; for ((i=5000;i<5096;i++)) do ./iperf -s -p $i & done'
    # connect 
    kubectl exec $server -nexample -- bash -c 'cd /home/paas/; for ((i=40000; i<'$((256+40000))';i++)); do { /home/paas/netserver -p $i >/log.$i 2>&1; }& done'
    echo "$i process:"
    kubectl exec $server -nexample -- bash -c 'ps -ef|grep -e qperf -e iperf -e netperf'
}

function lat(){
   from=`kubectl get pods -nexample --selector app=$1 -o jsonpath='{.items[0].metadata.name}'`
   to=`kubectl get pods -nexample --selector app=$2 -o jsonpath='{.items[0].status.podIP}'`
   echo "begin $1 $2 1 lat:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $from -nexample -- bash -c 'cd /home/paas; ./qperf '$to' -t 60 -m 64 -vvs tcp_lat udp_lat'
}

function bw(){
   from=`kubectl get pods -nexample --selector app=$1 -o jsonpath='{.items[0].metadata.name}'`
   to=`kubectl get pods -nexample --selector app=$2 -o jsonpath='{.items[0].status.podIP}'`
   echo "begin $1 $2 2 bw:         `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $from -nexample -- bash -c 'cd /home/paas; for ((i=6000; i<'$((10+6000))';i++)); do { ./netperf -t TCP_STREAM -H '$to' -l 180 -p $i -- -r 1024 > /thoughput.$i 2>&1; }& done; wait;'
   kubectl exec $from -nexample -- bash -c 'cat /thoughput.*'|grep 180.0|awk '{print $5}'|awk '{sum+=$1}; END {print sum}'
}

function pps(){
   from1=`kubectl get pods -nexample --selector app=$1 -o jsonpath='{.items[0].metadata.name}'`
   from2=`kubectl get pods -nexample --selector app=$1 -o jsonpath='{.items[1].metadata.name}'`
   server=`kubectl get pods -nexample --selector app=$2 -o jsonpath='{.items[0].metadata.name}'`
   to=`kubectl get pods -nexample --selector app=$2 -o jsonpath='{.items[0].status.podIP}'`
   echo "begin from $from1 $from2 to $server 3 pps:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $server -nexample -- bash -c 'cd /home/paas/; bash ./get_pps.sh eth0 1>/pps.log 2>&1 &'
   kubectl exec $server -nexample -- bash -c 'ps -ef|grep get_pps|grep -v grep'
   kubectl exec $from1 -nexample -- bash -c 'cd /home/paas; for ((i=5000;i<5048;i++)) do { ./iperf -c '$to' -b 100M -u -t 180 --pacing-timer 10000 -l 64 -p $i >> /pps.$i 2>&1; }& done; wait;' &
   kubectl exec $from2 -nexample -- bash -c 'cd /home/paas; for ((i=5048;i<5096;i++)) do { ./iperf -c '$to' -b 100M -u -t 180 --pacing-timer 10000 -l 64 -p $i >> /pps.$i 2>&1; }& done; wait;' &
   wait
   kubectl exec $server -nexample -- bash -c 'ps -ef|grep get_pps.sh|grep -v grep|awk "{print \$2}"|xargs -i sh -c "kill {}"; cat /pps.log'
}

function cps(){
   from1=`kubectl get pods -nexample --selector app=$1 -o jsonpath='{.items[0].metadata.name}'`
   from2=`kubectl get pods -nexample --selector app=$1 -o jsonpath='{.items[1].metadata.name}'`
   server=`kubectl get pods -nexample --selector app=$2 -o jsonpath='{.items[0].metadata.name}'`
   to=`kubectl get pods -nexample --selector app=$2 -o jsonpath='{.items[0].status.podIP}'`
   echo "begin from $from1 $from2 to $server 3 cps:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $from1 -nexample -- bash -c 'cd /home/paas; for ((i='40000'; i<'40128';i++)); do { ./netperf -t TCP_CRR -H '$to' -l 20 -p $i -- -r 64 > /cps.$i 2>&1; }& done; wait;' &
   kubectl exec $from2 -nexample -- bash -c 'cd /home/paas; for ((i='40128'; i<'40256';i++)); do { ./netperf -t TCP_CRR -H '$to' -l 20 -p $i -- -r 64 > /cps.$i 2>&1; }& done; wait;' &
   wait
   kubectl exec $from1 -nexample -- bash -c 'cat /cps.*'|grep 20.0|awk '{print $6}'|awk '{sum+=$1}; END {print sum}'
   kubectl exec $from2 -nexample -- bash -c 'cat /cps.*'|grep 20.0|awk '{print $6}'|awk '{sum+=$1}; END {print sum}'
}

function check(){
   from_app=$1
   server_app=$2
   lat $from_app $server_app
   bw $from_app $server_app
   pps $from_app $server_app
   cps $from_app $server_app
   sleep 10
   echo "end   $from $to:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

for s in $az3_sc $az3_sh $az7_sc $az7_sh; do 
   server=`kubectl get pods -nexample --selector app=$s -o jsonpath='{.items[0].metadata.name}'`
   kill_servers $server
done
for s in $az3_sc $az3_sh $az7_sc $az7_sh; do 
   server=`kubectl get pods -nexample --selector app=$s -o jsonpath='{.items[0].metadata.name}'`
   start_servers $server
done
sleep 1

{
check $az3_ch $az3_sc
check $az3_ch_local $az3_sc

check $az3_cc $az3_sc
check $az3_cc_local $az3_sc

check $az3_cc $az3_sh
check $az3_cc_local $az3_sh

check $az3_ch $az3_sh
check $az3_ch_local $az3_sh

check $az7_ch $az3_sc
check $az7_cc $az3_sc
check $az7_cc $az3_sh
check $az7_ch $az3_sh
}>to_az3.log &

{
check $az7_ch $az7_sc
check $az7_ch_local $az7_sc

check $az7_cc $az7_sc
check $az7_cc_local $az7_sc

check $az7_cc $az7_sh
check $az7_cc_local $az7_sh

check $az7_ch $az7_sh
check $az7_ch_local $az7_sh

check $az3_ch $az7_sc
check $az3_cc $az7_sc
check $az3_cc $az7_sh
check $az3_ch $az7_sh
}>to_az7.log &
wait
