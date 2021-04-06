kubectl create ns example
make namespace=example server
#make namespace=example deploy.perf-l4.server-az3-lat.az3:true.1.1 -f Makefile_network
#make namespace=example deployhost.perf-l4.serverhost-az3-lat.az3:true.1.2 -f Makefile_network
#make namespace=example deploy.perf-l4.client-az3-lat.az3:true.1.2 -f Makefile_network

make namespace=example deploy.perf-l4.server-az7-lat.az7-lat-server:true.1.1 -f Makefile_network
make namespace=example deployhost.perf-l4.serverhost-az7-lat.az7-lat-server:true.1.2 -f Makefile_network
make namespace=example deploy.perf-l4.client-az7-lat.az7-lat-client:true.1.2 -f Makefile_network
make namespace=example deploy.perf-l4.client-az7-lat2.az7-lat2-client:true.1.2 -f Makefile_network
make namespace=example deployhost.perf-l4.clienthost-az7-lat.az7-lat-client:true.1.2 -f Makefile_network
