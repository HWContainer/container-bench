#!/bin/bash

ip=${1}

for i in {0..60}
do
    if ping -c1 -w1 "${ip}" &>/dev/null; then
        echo "Check connection to ${ip} success."
        exit
    fi
done
echo "Check connection to ${ip} failed."