#!/bin/bash
using=2

if [[ $using == "1" ]]; then
# // 1 is using ip-api
export IP_INFO_API=$( curl -s http://ip-api.com/json );
cat > /root/ip-detail.txt << END
IP='$( echo ${IP_INFO_API} | jq -r '.query' )'
ASN='$( echo ${IP_INFO_API} | jq -r '.as' | cut -d " " -f 1 )'
ISP='$( echo ${IP_INFO_API} | jq -r '.as' | cut -d " " -f 2-100 )'
REGION='$( echo ${IP_INFO_API} | jq -r '.regionName' )'
CITY='$( echo ${IP_INFO_API} | jq -r '.city' )'
COUNTRY='$( echo ${IP_INFO_API} | jq -r '.country' )'
TIMEZONE='$( echo ${IP_INFO_API} | jq -r '.timezone' )'
END
elif [[ $using == "2" ]]; then
# // 2 is using ipinfo.io
export IP_INFO_API=$( curl -s https://ipinfo.io/json );
cat > /root/ip-detail.txt << END
IP='$( echo ${IP_INFO_API} | jq -r '.ip' )'
ASN='$( echo ${IP_INFO_API} | jq -r '.org' | cut -d " " -f 1 )'
ISP='$( echo ${IP_INFO_API} | jq -r '.org' | cut -d " " -f 2-100 )'
REGION='$( echo ${IP_INFO_API} | jq -r '.region' )'
CITY='$( echo ${IP_INFO_API} | jq -r '.city' )'
COUNTRY='$( echo ${IP_INFO_API} | jq -r '.country' )'
TIMEZONE='$( echo ${IP_INFO_API} | jq -r '.timezone' )'
END
fi
