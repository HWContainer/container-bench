
az3_sc=`kubectl get pods -nexample --selector app=server-az3-lat-1 -o jsonpath='{.items[0].metadata.name}'`
az3_sh=`kubectl get pods -nexample --selector app=serverhost-az3-lat-1 -o jsonpath='{.items[0].metadata.name}'`
az7_sc=`kubectl get pods -nexample --selector app=server-az7-lat-1 -o jsonpath='{.items[0].metadata.name}'`
az7_sh=`kubectl get pods -nexample --selector app=serverhost-az7-lat-1 -o jsonpath='{.items[0].metadata.name}'`

az3_ch=clienthost-az3-lat-1
az3_cc=client-az3-lat-1
az3_ch_local=clienthost-az3-local-1
az3_cc_local=client-az3-local-1
az7_ch=clienthost-az7-lat-1
az7_cc=client-az7-lat-1
az7_ch_local=clienthost-az7-local-1
az7_cc_local=client-az7-local-1

az3_sc_ip=server-az3-lat-1
az3_sh_ip=serverhost-az3-lat-1
az7_sc_ip=server-az7-lat-1
az7_sh_ip=serverhost-az7-lat-1

function kill_qperf(){
  for i in $az3_sc $az3_sh $az7_sc $az7_sh; do
    kubectl exec $i -nexample -- bash -c 'pkill -9 qperf'
  done
}

function start_qperf(){
  for i in $az3_sc $az3_sh $az7_sc $az7_sh; do
    kubectl exec $i -nexample -- bash -c 'cd /home/paas/; ./qperf &'
  done
}
kill_qperf
start_qperf
sleep 1

function check(){
   client=$1
   server=$2
   from=`kubectl get pods -nexample --selector app=$client -o jsonpath='{.items[0].metadata.name}'`
   to=`kubectl get pods -nexample --selector app=$server -o jsonpath='{.items[0].status.podIP}'`
   echo "begin $client $server 1:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $from -nexample -- bash -c 'cd /home/paas; ./qperf '$to' -t 100 -vvu tcp_bw tcp_lat'
   echo "begin $client $server 2:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $from -nexample -- bash -c 'cd /home/paas; ./qperf '$to' -t 100 -vvu udp_bw udp_lat'
   echo "begin $client $server 3:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $from -nexample -- bash -c 'cd /home/paas; ./qperf '$to' -oo msg_size:1:64K:*4 -vu tcp_bw'
   echo "begin $client $server 4:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
   kubectl exec $from -nexample -- bash -c 'cd /home/paas; ./qperf '$to' -oo msg_size:1:64K:*4 -vu tcp_lat'
   echo "end   $from $to:        `date +%Y-%m-%d' '%H:%M:%S.%N`"
}

{
check $az3_ch $az3_sc_ip
check $az3_ch_local $az3_sc_ip

check $az3_cc $az3_sc_ip
check $az3_cc_local $az3_sc_ip

check $az3_cc $az3_sh_ip
check $az3_cc_local $az3_sh_ip

check $az3_ch $az3_sh_ip
check $az3_ch_local $az3_sh_ip

check $az7_ch $az3_sc_ip
check $az7_cc $az3_sc_ip
check $az7_cc $az3_sh_ip
check $az7_ch $az3_sh_ip
}>az3.log &

{
check $az7_ch $az7_sc_ip
check $az7_ch_local $az7_sc_ip

check $az7_cc $az7_sc_ip
check $az7_cc_local $az7_sc_ip

check $az7_cc $az7_sh_ip
check $az7_cc_local $az7_sh_ip

check $az7_ch $az7_sh_ip
check $az7_ch_local $az7_sh_ip

check $az3_ch $az7_sc_ip
check $az3_cc $az7_sc_ip
check $az3_cc $az7_sh_ip
check $az3_ch $az7_sh_ip
}>az7.log &

wait
