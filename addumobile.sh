#!/bin/bash

#text,A=Merah,B=Hijau,C=Magenta,D=Cyan
A='\033[1;31m'
B='\033[1;32m'
C='\033[1;35m'
D='\033[1;36m'
#background,A1=Merah,B1=Hijau,C1=Magenta,D1=Cyan
A1='\033[1;41m'
B1='\033[1;42m'
C1='\033[1;45m'
D1='\033[1;46m'
#reset
R='\033[0m'

MYIP=$(wget -qO- ipinfo.io/ip);
IZIN=$( curl https://raw.githubusercontent.com/rewasu91/public/main/ipvps.sh | grep $MYIP | awk '{print $4}')
if [ $MYIP = $IZIN ]; then
clear
echo -e "${D}——————————————————————————————————————————${R}"
echo -e "${D1}         Proses Semakan IP Address        ${R}"
echo -e "${D}——————————————————————————————————————————${R}"
echo -e ""
clear
else
clear
echo -e "${D}——————————————————————————————————————————${R}"
echo -e "${D1}         Proses Semakan IP Address        ${R}"
echo -e "${D}——————————————————————————————————————————${R}"
echo -e ""
sleep 2
echo -e "${A} Maaf. IP address anda tidak berdaftar dengan admin! ${R}"
echo -e "${A} Sila hubungi admin di telegram KaizenVPN..${R}"
sleep 3
clear
exit 0
fi

ipadd=$(curl -s ipinfo.io/ip);
IP=$( curl -s ipinfo.io/ip );
clear
source /var/lib/Kaizen/ipvps.conf
if [[ "$IP" = "" ]]; then
domain=$(cat /etc/v2ray/domain)
else
domain=$(cat /etc/v2ray/domain)
fi

uuid=$(cat /proc/sys/kernel/random/uuid)

tls=$( cat /etc/v2ray/vless.json | grep port | sed 's/"//g' | sed 's/port//g' | sed 's/://g' | sed 's/,//g' | sed 's/       //g' );
none=$( cat /etc/v2ray/vnone.json | grep port | sed 's/"//g' | sed 's/port//g' | sed 's/://g' | sed 's/,//g' | sed 's/       //g');

    until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		clear
		echo -e ""
		echo -e "${D}——————————————————————————————————————————————————————————${R}"
		echo -e "${D1}              Membuat Akaun V2ray Vless                   ${R}"
		echo -e "${D}——————————————————————————————————————————————————————————${R}"
		echo -e ""
		read -rp "► Sila masukkan Username	       : " -e user
		CLIENT_EXISTS=$(grep -w $user /etc/v2ray/vless.json | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
			echo ""
			echo "► Username sudah berdaftar, sila pilih Username yang lain."
			exit 1
		fi
	done
read -p "► Sila masukkan Tempoh Aktif (hari)  : " masaaktif
hariini=`date -d "0 days" +"%Y-%m-%d"`
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#v2rayvlesstls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/v2ray/vless.json
sed -i '/#v2rayvlessnonetls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/v2ray/vnone.json
vlesslink1="vless://${uuid}@${domain}:$none?path=/v2ray&encryption=none&host=wap.u.com.my&type=ws#${user}"
vlesslink2="vless://${uuid}@${domain}:$none?path=/v2ray&encryption=none&host=mm.net.my&type=ws#${user}"
vlesslink3="vless://${uuid}@${domain}:$none?path=/v2ray&encryption=none&host=ulist.com.my&type=ws#${user}"
vlesslink4="vless://${uuid}@${domain}:$none?path=/v2ray&encryption=none&host=pay-dcb.u.com.my&type=ws#${user}"
vlesslink5="vless://${uuid}@${domain}:$none?path=/v2ray&encryption=none&host=um.gz.net.my&type=ws#${user}"
systemctl restart v2ray@vless
systemctl restart v2ray@vnone
clear
echo -e ""
echo -e "${D}——————————————————————————————————————————————————————————${R}"
echo -e "${D1}              Maklumat Akaun V2ray Vless                  ${R}"
echo -e "${D}——————————————————————————————————————————————————————————${R}"
echo -e "► Username             : ${user}"
echo -e "► Dibuat pada          : $hariini"
echo -e "► Expire pada          : $exp"
echo -e "${D}——————————————————————————————————————————————————————————${R}"
echo -e "► Link V2ray Vless Wap"
echo -e "► ${vlesslink1}"
echo -e ""
echo -e "► Link V2ray Vless Mm"
echo -e "► ${vlesslink2}"
echo -e ""
echo -e "► Link V2ray Vless Ulist"
echo -e "► ${vlesslink3}"
echo -e ""
echo -e "► Link V2ray Vless PayDCB"
echo -e "► ${vlesslink4}"
echo -e ""
echo -e "► Link V2ray Vless Umgz"
echo -e "► ${vlesslink5}"
echo -e ""
echo -e "${D}——————————————————————————————————————————————————————————${R}"
echo -e ""