#make server
#make metrics
make servers=perf clients=perf CONNECT=256 QPS=20000 shortpod.container.perf.perf.1.3 -f Makefile_network
sleep 10
make servers=perf clients=perf CONNECT=256 QPS=20000 shortsvc.container.perf.perf.1.3 -f Makefile_network
