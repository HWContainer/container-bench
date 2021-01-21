bash script/prometheus_register.sh
#make l7test servers=c6ne-16u-centos clients=c6ne-16u-centos
#make l7test servers=c6ne-32u-centos clients=c6ne-32u-centos
make PODS=2 l7test servers=c6ne-64u-centos clients=c6ne-64u-centos

#make outtest servers=c6ne-16u-centos -f Makefile_network
#make outtest servers=c6ne-32u-centos -f Makefile_network
make PODS=10 outtest servers=c6ne-64u-centos -f Makefile_network
