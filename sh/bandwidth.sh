#!/bin/sh
# Bandwidth Check: Check Real-Time WAN Bandwidth Usage
# by WaLLy3K 11APR15 (Updated 25NOV15) for Tomato Firmware
# Usage: "checkWAN <seconds>" (To check WAN over a period of X seconds and average the result)

wan_iface=`nvram get wan_iface`
calc(){ awk "BEGIN { print $*}"; }    # Calculate floating point arithmetic using AWK instead of BC

checkWAN () {
    [ -z $1 ] && sec="1" || sec="$1"

    netdev=`grep "$wan_iface" /proc/net/dev`
    pRX=$(echo $netdev | cut -d' ' -f2)
    pTX=$(echo $netdev | cut -d' ' -f10)
    sleep $sec
    netdev=`grep "$wan_iface" /proc/net/dev`
    cRX=$(echo $netdev | cut -d' ' -f2)
    cTX=$(echo $netdev | cut -d' ' -f10)

    [ $cRX \< $pRX ] && getRX=`calc "$cRX + (0xFFFFFFFF - $pRX)"` || getRX=`calc "($cRX - $pRX)"`
    [ $cTX \< $pTX ] && getTX=`calc "$cTX + (0xFFFFFFFF - $pTX)"` || getTX=`calc "($cTX - $pTX)"`
    dlBytes=$(($getRX/$sec)); ulBytes=$(($getTX/$sec))
    [ $dlBytes -le "12000" -a $ulBytes -le "4000" ] && wanStatus="idle" || wanStatus="busy"

    getDLKbit=$(printf "%.0f\n" `calc $dlBytes*0.008`);        getULKbit=$(printf "%.0f\n" `calc $ulBytes*0.008`)
    getDLMbit=$(printf "%.2f\n" `calc $dlBytes*0.000008`);    getULMbit=$(printf "%.2f\n" `calc $ulBytes*0.000008`)
}

seconds=$1
if [ -z $seconds ]
then
  seconds=5
fi

checkWAN $seconds # Check WAN port for x seconds
# [ $wanStatus = "idle" ] && echo "WAN: Idle" || echo "WAN: Busy (DL $getDLMbit Mbps / UL $getULMbit Mbps)"

ts=`date +'%Y-%m-%dT%T'`
echo "$ts dl=$getDLMbit up=$getULMbit"
