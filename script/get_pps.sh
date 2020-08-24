#!/bin/bash
INTERVAL="10"  # update interval in seconds
while true
do
        R1=`cat /sys/class/net/$1/statistics/rx_packets`
        T1=`cat /sys/class/net/$1/statistics/tx_packets`
        sleep $INTERVAL
        R2=`cat /sys/class/net/$1/statistics/rx_packets`
        T2=`cat /sys/class/net/$1/statistics/tx_packets`
        TXPPS=`expr $T2 - $T1`
        RXPPS=`expr $R2 - $R1`
    #
    TPS=`expr $TXPPS / 10`
    RPS=`expr $RXPPS / 10`
        echo "TX: $TPS pps  RX: $RPS pps"
        echo "TX: $TPS pps  RX: $RPS pps" >> /tmp/pps.log
done
