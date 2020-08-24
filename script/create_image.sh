#!/bin/bash

a=1   #image layer num
b=$1
c=1  #tag num of images
src=$2
dst=$3

for ((j=0; j<$c; j++))
do
    rm -rf DockerBuild
    mkdir -p DockerBuild
    cp sample  ./DockerBuild/sample -rf
    echo "FROM $src"  > ./DockerBuild/Dockerfile

    for ((i=$a; i<=$b; i++))
    do
        echo "ADD ./test"$i" /tmp/test"$i >> ./DockerBuild/Dockerfile
        cp ./DockerBuild/sample  ./DockerBuild/test$i
        head -c 32 /dev/urandom | base64 >> ./DockerBuild/test$i
    done
    rm ./DockerBuild/sample -f
    docker build  DockerBuild -t $dst
done

