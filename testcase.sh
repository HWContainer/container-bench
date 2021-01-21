bash script/prometheus_register.sh

mkdir -p logs
make PODS=1 l7test servers=c6-64u-centos clients=c6-64u-centos
mv logs logs_01
mkdir -p logs
make PODS=2 l4test servers=c6-64u-centos clients=c6-64u-centos
mv logs logs_02
mkdir -p logs
make PODS=1 l7test servers=c6-64u-centos clients=c6-64u-centos
mv logs logs_03
mkdir -p logs
make PODS=10 l7test servers=c6-64u-centos clients=c6-64u-centos
mv logs logs_04
mkdir -p logs
make PODS=1 outtest servers=c6-64u-centos -f Makefile_network
mv logs logs_05
mkdir -p logs
make PODS=10 outtest servers=c6-64u-centos -f Makefile_network
mv logs logs_06

