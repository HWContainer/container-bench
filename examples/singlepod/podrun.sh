#make servers=perf CONNECT=256 l7_pod.pod.container.perf -f Makefile_network
make server=server-perf-1 service=server-perf-1 CONNECT=256 l7_pod.invoke -f Makefile_network > logs/runpod.log
