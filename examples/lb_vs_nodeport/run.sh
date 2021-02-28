
make CONNECT=256 svc_ip=http://192.168.32.110 server=lbv2-perf-1 out_invoke -f Makefile_network > logs/lb.log
make CONNECT=256 svc_ip=http://192.168.33.181:30522 server=lbv2-perf-1 out_invoke -f Makefile_network > logs/nodeport-same.log
make CONNECT=256 svc_ip=http://192.168.33.234:30522 server=lbv2-perf-1 out_invoke -f Makefile_network > logs/nodeport-diff.log
