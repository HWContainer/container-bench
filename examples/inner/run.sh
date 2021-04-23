#make PINGSERVER=192.168.214.133 namespace=network deploy.perf-fortio.test-fortio.client:true.1.1 -f Makefile_network
#make PINGSERVER=192.168.214.133 namespace=network deploy.perf-l4.test-client.client:true.1.1 -f Makefile_network
#make PINGSERVER=192.168.214.133 namespace=network deploy.perf-nginx.test-server.server:true.1.8 -f Makefile_network
#make namespace=network svc.svc.test-server.server.1.1 -f Makefile_network
#for i in $(seq 1 11); do curl http://$pod_ip:80 -o /dev/null -s  -w %{time_namelookup}---%{time_pretransfer}---%{time_total}"\n"; done|tail -n 10|awk -F '---' '{namelookup+=$1; connect+=($2-$1);tans+=($3-$2)}; END {print namelookup*100" "connect*100" "tans*100}'

#make namespace=network service=server-1 client=test-fortio-1 server=test-server-1 CONNECT=64 QPS=2000 shortsvc.invoke  -f Makefile_network > logs/shortsvc.log
make FAST=true namespace=network service=server-1 client=test-fortio-1 server=test-server-1 CONNECT=256 QPS=10000 shortsvc.invoke  -f Makefile_network > logs/shortsvc.log

