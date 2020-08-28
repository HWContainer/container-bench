#!/bin/bash

ip=${1}

function timediff() 
{
    start_time=$1
    end_time=$2
   
    start_s=${start_time%.*}
    start_nanos=${start_time#*.}
    end_s=${end_time%.*}
    end_nanos=${end_time#*.}
   
    if [ "$end_nanos" -lt "$start_nanos" ];then
        end_s=$(( 10#$end_s - 1 ))
        end_nanos=$(( 10#$end_nanos + 10**9 ))
    fi
   
    time=$(( 10#$end_s - 10#$start_s )).$(( (10#$end_nanos - 10#$start_nanos)/10**6 ))
    
    >&2 echo $time
}

timer_start=`date +%Y-%m-%d' '%H:%M:%S`
start=$(date +"%s.%N")
while true
do
    if ping -c1 -w1 "${ip}" &>/dev/null; then
        timer_end=`date "+%Y-%m-%d %H:%M:%S"`
        end=$(date +"%s.%N")

        >&2 echo -n "$timer_start $timer_end Check $MYPODNAME connection to ${ip} success take: "
        timediff $start $end
        exit 0
    fi
    sleep 0.01
    ping -c1 -w1 "${ip}"
done
echo "Check connection to ${ip} failed."
exit 1
