fortio_image=$1
node_image=$2
process_image=$3
host=$4

ifconfig eth1 $host/18 up
yum install -y docker
service docker restart
docker run -d -v /sys:/host/sys -v /proc:/host/proc --network host $node_image --web.listen-address=0.0.0.0:19101 --path.procfs=/host/proc --path.sysfs=/host/sys --collector.filesystem.ignored-mount-points='^/(dev|proc|sys|var/lib/docker/.+)($|/)' --collector.filesystem.ignored-fs-types='^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$'

docker run -d -v /proc:/host/proc --network host $process_image --path.procfs=/host/proc --web.listen-address=0.0.0.0:9256
docker run --name=fortio -d $fortio_image
docker cp fortio:usr/bin/fortio ./
