#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# (C) Copyright 2022 Oleh KaizenVPN
# ═══════════════════════════════════════════════════════════════════
# Nama        : Autoskrip VPN
# Info        : Memasang pelbagai jenis servis vpn didalam satu skrip
# Dibuat Pada : 30-08-2022 ( 30 Ogos 2022 )
# OS Support  : Ubuntu & Debian
# Owner       : KaizenVPN
# Telegram    : https://t.me/KaizenA
# Github      : github.com/rewasu91
# ═══════════════════════════════════════════════════════════════════

dateFromServer=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
biji=`date +"%Y-%m-%d" -d "$dateFromServer"`
#########################

# ══════════════════════════
# // Export Warna & Maklumat
# ══════════════════════════
export RED='\033[1;91m';
export GREEN='\033[1;92m';
export YELLOW='\033[1;93m';
export BLUE='\033[1;94m';
export PURPLE='\033[1;95m';
export CYAN='\033[1;96m';
export LIGHT='\033[1;97m';
export NC='\033[0m';

# ════════════════════════════════
# // Export Maklumat Status Banner
# ════════════════════════════════
export ERROR="[${RED} ERROR ${NC}]";
export INFO="[${YELLOW} INFO ${NC}]";
export OKEY="[${GREEN} OKEY ${NC}]";
export PENDING="[${YELLOW} PENDING ${NC}]";
export SEND="[${YELLOW} SEND ${NC}]";
export RECEIVE="[${YELLOW} RECEIVE ${NC}]";
export REDBG='\e[41m';
export WBBG='\e[1;47;30m';

# ═══════════════
# // Export Align
# ═══════════════
export BOLD="\e[1m";
export WARNING="${RED}\e[5m";
export UNDERLINE="\e[4m";

# ════════════════════════════
# // Export Maklumat Sistem OS
# ════════════════════════════
export OS_ID=$( cat /etc/os-release | grep -w ID | sed 's/ID//g' | sed 's/=//g' | sed 's/ //g' );
export OS_VERSION=$( cat /etc/os-release | grep -w VERSION_ID | sed 's/VERSION_ID//g' | sed 's/=//g' | sed 's/ //g' | sed 's/"//g' );
export OS_NAME=$( cat /etc/os-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME//g' | sed 's/=//g' | sed 's/"//g' );
export OS_KERNEL=$( uname -r );
export OS_ARCH=$( uname -m );

# ═══════════════════════════════════
# // String Untuk Membantu Pemasangan
# ═══════════════════════════════════
export VERSION="2.0";
export EDITION="Multiport Edition";
export AUTHER="KaizenVPN";
export ROOT_DIRECTORY="/etc/kaizenvpn";
export CORE_DIRECTORY="/usr/local/kaizenvpn";
export SERVICE_DIRECTORY="/etc/systemd/system";
export SCRIPT_SETUP_URL="https://raw.githubusercontent.com/rewasu91/scvps/main/setup.sh";
export REPO_URL="https://github.com/rewasu91/scvps";

# ═══════════════
# // Allow Access
# ═══════════════
BURIQ () {
    curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access > /root/tmp
    data=( `cat /root/tmp | grep -E "^### " | awk '{print $2}'` )
    for user in "${data[@]}"
    do
    exp=( `grep -E "^### $user" "/root/tmp" | awk '{print $3}'` )
    d1=(`date -d "$exp" +%s`)
    d2=(`date -d "$biji" +%s`)
    exp2=$(( (d1 - d2) / 86400 ))
    if [[ "$exp2" -le "0" ]]; then
    echo $user > /etc/.$user.ini
    else
    rm -f  /etc/.$user.ini > /dev/null 2>&1
    fi
    done
    rm -f  /root/tmp
}
# https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access
MYIP=$(curl -sS ipv4.icanhazip.com)
Name=$(curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access | grep $MYIP | awk '{print $2}')
echo $Name > /usr/local/etc/.$Name.ini
CekOne=$(cat /usr/local/etc/.$Name.ini)
Bloman () {
if [ -f "/etc/.$Name.ini" ]; then
CekTwo=$(cat /etc/.$Name.ini)
    if [ "$CekOne" = "$CekTwo" ]; then
        res="Expired"
    fi
else
res="Permission Accepted..."
fi
}
PERMISSION () {
    MYIP=$(curl -sS ipv4.icanhazip.com)
    IZIN=$(curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access | awk '{print $4}' | grep $MYIP)
    if [ "$MYIP" = "$IZIN" ]; then
    Bloman
    else
    res="Permission Denied!"
    fi
    BURIQ
}
PERMISSION
if [ "$res" = "Permission Accepted..." ]; then
echo -ne
else
echo -e "${ERROR} Permission Denied!";
exit 0
fi

# ═════════════════════════════════════════════════════════
# // Semak kalau anda sudah running sebagai root atau belum
# ═════════════════════════════════════════════════════════
if [[ "${EUID}" -ne 0 ]]; then
		echo -e " ${ERROR} Sila jalankan skrip ini sebagai root user";
		exit 1
fi

# ════════════════════════════════════════════════════════════
# // Menyemak sistem sekiranya terdapat pemasangan yang kurang
# ════════════════════════════════════════════════════════════
if ! which jq > /dev/null; then
    clear;
    echo -e "${ERROR} JQ Packages Not installed";
    exit 1;
fi

# ═══════════════════════════════
# // Exporting maklumat rangkaian
# ═══════════════════════════════
wget -qO- --inet4-only 'https://raw.githubusercontent.com/rewasu91/scvpssettings/main/get-ip_sh' | bash;
source /root/ip-detail.txt;
export IP_NYA="$IP";
export ASN_NYA="$ASN";
export ISP_NYA="$ISP";
export REGION_NYA="$REGION";
export CITY_NYA="$CITY";
export COUNTRY_NYA="$COUNTRY";
export TIME_NYA="$TIMEZONE";

# ═════════════
# // Clear Data
# ═════════════
clear;

# ══════════════════════════════════
# // Senarai akaun yang sedang login
# ══════════════════════════════════
clear;
echo -n > /tmp/other.txt;
echo -n > /etc/kaizenvpn/cache/vmess_temp.txt;
echo -n > /etc/kaizenvpn/cache/vmess_temp2.txt;
data=(`cat /etc/xray-mini/client.conf | grep '^Vmess' | cut -d " " -f 2`);
echo "";
echo -e "";
for akun in "${data[@]}"
do
if [[ -z "$akun" ]]; then
akun="tidakada";
fi
echo -n > /etc/kaizenvpn/cache/vmess_temp.txt;
data2=( `netstat -anp | grep ESTABLISHED | grep 'tcp6\|udp6' | grep xray-mini | awk '{print $5}' | cut -d: -f1 | sort | uniq`);
for ip in "${data2[@]}"
do
jum=$(cat /etc/kaizenvpn/xray-mini-tls/access.log | grep -w $akun | awk '{print $3}' | cut -d: -f1 | grep -w $ip | sort | uniq);
if [[ "$jum" = "$ip" ]]; then
echo "$jum" >> /etc/kaizenvpn/cache/vmess_temp.txt;
else
echo "$ip" >> /etc/kaizenvpn/cache/vmess_temp2.txt;
fi
jum2=$(cat /etc/kaizenvpn/cache/vmess_temp.txt);
sed -i "/$jum2/d" /etc/kaizenvpn/cache/vmess_temp2.txt > /dev/null 2>&1;
done
jum=$(cat /etc/kaizenvpn/cache/vmess_temp.txt);
if [[ -z "$jum" ]]; then
echo > /dev/null;
else
jum2=$(cat /etc/kaizenvpn/cache/vmess_temp.txt | nl);
hariini=`date -d "0 days" +"%Y-%m-%d"`;
echo "Username : $akun";
echo "$jum2";
echo "";
fi
done

clear;
echo -e "";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "${WBBG}     [ Senarai Login Vmess WS None TLS ]    ${NC}";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -n > /etc/kaizenvpn/cache/vmess_temp3.txt;
data=(`cat /etc/xray-mini/client.conf | grep '^Vmess' | cut -d " " -f 2`);
for akun in "${data[@]}"
do
if [[ -z "$akun" ]]; then
akun="tidakada";
fi
ip=$( cat /etc/kaizenvpn/xray-mini-nontls/access.log | grep "$(date -d "0 days" +"%H:%M" )" | grep -w $akun | tail -n100 | awk '{print $3}' | cut -d: -f1 | sort | uniq );
if [[ -z "$ip" ]]; then
echo > /dev/null
else
jum5=$(echo $ip | nl);
hariini=`date -d "0 days" +"%Y-%m-%d"`;
echo "Username : $akun";
echo "$jum5";
echo "";
fi
done

echo -e "";
echo -e "";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "${WBBG}       [ Senarai Login Vmess WS TLS ]       ${NC}";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -n > /etc/kaizenvpn/cache/vmess_temp3.txt;
data=(`cat /etc/xray-mini/client.conf | grep '^Vmess' | cut -d " " -f 2`);
for akun in "${data[@]}"
do
if [[ -z "$akun" ]]; then
akun="tidakada";
fi
ip=$( cat /etc/kaizenvpn/xray-mini-tls/access.log | grep "$(date -d "0 days" +"%H:%M" )" | grep -w $akun | tail -n100 | awk '{print $3}' | cut -d: -f1 | sort | uniq );
if [[ -z "$ip" ]]; then
echo > /dev/null
else
jum5=$(echo $ip | nl);
hariini=`date -d "0 days" +"%Y-%m-%d"`;
echo "Username : $akun";
echo "$jum5";
echo "";
fi
done

echo -e "";
echo -e "";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "${WBBG}    [ Senarai Login Akaun GRPC Vmess ]      ${NC}";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
oth=$(cat /etc/kaizenvpn/cache/vmess_temp2.txt | sort | uniq | nl )
echo "GRPC IP : All User IP";
echo "$oth";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo "";
rm -rf /etc/kaizenvpn/cache/vmess_temp2.txt;
rm -rf /etc/kaizenvpn/cache/vmess_temp.txt;
rm -rf /etc/kaizenvpn/cache/vmess_temp3.txt;
