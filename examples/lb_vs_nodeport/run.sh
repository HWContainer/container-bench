
make CONNECT=256 svc_ip=http://192.168.32.46 server=lbv2-perf-1 out_invoke -f Makefile_network > logs/lb.log
make CONNECT=256 svc_ip=http://192.168.33.172:32685 server=lbv2-perf-1 out_invoke -f Makefile_network > logs/nodeport-same.log
make CONNECT=256 svc_ip=http://192.168.33.240:32685 server=lbv2-perf-1 out_invoke -f Makefile_network > logs/nodeport-diff.log
