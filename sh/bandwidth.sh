#!/bin/sh
# Send real-time bandwidth data to Splunk HTTP Event Collector
# Bandwidth calculations based on script by WaLLy3K (see https://www.linksysinfo.org/index.php?threads/how-to-monitor-the-ip-traffic-and-bandwidth-with-cli.71998/)
# For running on Tomato USB or Advanced Tomato routers

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

if [ -z $SPLUNK_AUTH ]
then
  echo "SPLUNK_AUTH environment must be set"
  exit 1
fi

splunkUrl="http://fantom:8088/services/collector/event"

while :
do
  checkWAN 5
  curl -s -o /dev/null $splunkUrl -H "Authorization: Splunk $SPLUNK_AUTH" -d "{\"event\": \"code=bandwidth dl=$getDLMbit ul=$getULMbit\"}"
done
