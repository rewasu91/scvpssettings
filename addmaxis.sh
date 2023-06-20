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
export VERSION="2.5";
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
    curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/specialaccess > /root/tmp
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
# https://raw.githubusercontent.com/rewasu91/scvpssettings/main/specialaccess
MYIP=$(curl -sS ipv4.icanhazip.com)
Name=$(curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/specialaccess | grep $MYIP | awk '{print $2}')
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
    IZIN=$(curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/specialaccess | awk '{print $4}' | grep $MYIP)
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

# ════════════════
# // Membuat Akaun
# ════════════════
clear;
echo -e "";
echo -e "";
cowsay -f ghostbusters "SELAMAT DATANG BOSKU.";
echo -e "";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "${WBBG}          [ Membuat Akaun Vless ]           ${NC}";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "";
read -p "  ► Sila masukkan Username            : " Username;
Username="$(echo ${Username} | sed 's/ //g' | tr -d '\r' | tr -d '\r\n' )";

# // Validate Input
if [[ $Username == "" ]]; then
    clear;
    echo -e "  ${EROR} Sila masukkan Username !";
    exit 1;
fi

# // Creating User database file
touch /etc/xray-mini/client.conf;

# // Checking User already on vps or no
if [[ "$( cat /etc/xray-mini/client.conf | grep -w ${Username})" == "" ]]; then
    Do=Nothing;
else
    clear;
    echo -e "  ${EROR} User ( ${YELLOW}$Username${NC} ) sudah dipakai !";
    exit 1;
fi

# // Expired Date
read -p "  ► Sila masukkan Tempoh Aktif (hari) : " Jumlah_Hari;
exp=`date -d "$Jumlah_Hari days" +"%Y-%m-%d"`;
hariini=`date -d "0 days" +"%Y-%m-%d"`;

# // Generate New UUID & Domain
uuid=$( cat /proc/sys/kernel/random/uuid );
domain=$( cat /etc/kaizenvpn/domain.txt );

# // Force create folder for fixing account wasted
mkdir -p /etc/kaizenvpn/cache/;
mkdir -p /etc/xray-mini/;
mkdir -p /etc/kaizenvpn/xray-mini-tls/;
mkdir -p /etc/kaizenvpn/xray-mini-nontls/;

# // Getting vless port using grep from config
tls_port=$( cat /etc/xray-mini/tls.json | grep -w port | awk '{print $2}' | head -n1 | sed 's/,//g' | tr '\n' ' ' | tr -d '\r' | tr -d '\r\n' | sed 's/ //g' );
nontls_port=$( cat /etc/xray-mini/nontls.json | grep -w port | awk '{print $2}' | head -n1 | sed 's/,//g' | tr '\n' ' ' | tr -d '\r' | tr -d '\r\n' | sed 's/ //g' );

export CHK=$( cat /etc/xray-mini/tls.json );
if [[ $CHK == "" ]]; then
    clear;
    echo -e "  ${ERROR} Terdapat masalah teknikal didalam VPS anda. Sila hubungi admin untuk fixkan VPS anda !";
    exit 1;
fi

# // Input Your Data to server
cp /etc/xray-mini/tls.json /etc/kaizenvpn/xray-mini-utils/tls-backup.json;
cat /etc/kaizenvpn/xray-mini-utils/tls-backup.json | jq '.inbounds[3].settings.clients += [{"id": "'${uuid}'","email": "'${Username}'"}]' > /etc/kaizenvpn/xray-mini-cache.json;
cat /etc/kaizenvpn/xray-mini-cache.json | jq '.inbounds[6].settings.clients += [{"id": "'${uuid}'","email": "'${Username}'"}]' > /etc/xray-mini/tls.json;
cp /etc/xray-mini/nontls.json /etc/kaizenvpn/xray-mini-utils/nontls-backup.json;
cat /etc/kaizenvpn/xray-mini-utils/nontls-backup.json | jq '.inbounds[1].settings.clients += [{"id": "'${uuid}'","email": "'${Username}'"}]' > /etc/xray-mini/nontls.json;
echo -e "Vless $Username $exp" >> /etc/xray-mini/client.conf;

# // Make Config Link
#vless_nontls="vless://${uuid}@${domain}:${nontls_port}?path=%2Fvless&security=none&encryption=none&type=ws#${Username}";
#vless_tls1="vless://${uuid}@172.67.9.227:${tls_port}?path=wss%3A//italeem.iium.edu.my/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=italeem.iium.edu.my#${Username}";
#vless_tls2="vless://${uuid}@172.67.43.120:${tls_port}?path=wss%3A//ufuture.uitm.edu.my/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=ufuture.uitm.edu.my#${Username}";
#vless_tls6="vless://${uuid}@italeem.iium.edu.my.${domain}:${tls_port}?path=/vless&security=tls&encryption=none&host=italeem.iium.edu.my&type=ws&sni=italeem.iium.edu.my#${Username}";
#vless_tls3="vless://${uuid}@www.speedtest.net:${tls_port}?path=CF-RAY%3Ahttp%3A//www.speedtest.net/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=www.speedtest.net#${Username}";
vless_tls4="vless://${uuid}@hq.viu.com.${domain}:${tls_port}?path=/vless&security=tls&encryption=none&type=ws#${Username}";
vless_tls5="vless://${uuid}@www.unisza.edu.my.${domain}:${tls_port}?path=/vless&security=tls&encryption=none&type=ws&sni=mycampus.upnm.edu.my#${Username}";
vless_nontls1="vless://${uuid}@www.unisza.edu.my.${domain}:${nontls_port}?path=/vless&security=none&encryption=none&host=mycampus.upnm.edu.my&type=ws#${Username}";
vless_tls6="vless://${uuid}@www.viu.com.${domain}:${tls_port}?path=/vless&security=tls&encryption=none&type=ws#${Username}";
vless_tls7="vless://${uuid}@sub.viu.com.www.viu.com.${domain}:${tls_port}?path=/vless&security=tls&encryption=none&type=ws#${Username}";
vless_tls8="vless://${uuid}@sub.viu.com.www.viu.com.${domain}:${tls_port}?path=/vless&security=tls&encryption=none&type=ws&sni=sub.viu.com.www.viu.com#${Username}";
#vless_grpc="vless://${uuid}@${domain}:${tls_port}?mode=gun&security=tls&encryption=none&type=grpc&serviceName=Vless-GRPC#${Username}";

# // Restarting XRay Service
systemctl enable xray-mini@tls;
systemctl enable xray-mini@nontls;
systemctl start xray-mini@tls;
systemctl start xray-mini@nontls;
systemctl restart xray-mini@tls;
systemctl restart xray-mini@nontls;

# // Make Client Folder for save the configuration
mkdir -p /etc/kaizenvpn/vless/;
mkdir -p /etc/kaizenvpn/vless/${Username};
rm -f /etc/kaizenvpn/vless/${Username}/config.log;

# ═══════════════════════
# // Maklumat Akaun Vless
# ═══════════════════════
clear; 
echo "" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e "${CYAN}════════════════════════════════════════════${NC}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e "${WBBG}          [ Maklumat Akaun Vless ]          ${NC}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e "${CYAN}════════════════════════════════════════════${NC}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " Username    ► ${Username}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " Dibuat Pada ► ${hariini}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " Expire Pada ► ${exp}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " IP          ► ${IP_NYA}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " Address     ► ${domain}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " Port TLS    ► ${tls_port}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " Port NTLS   ► ${nontls_port}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " User ID     ► ${uuid}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e "${CYAN}════════════════════════════════════════════${NC}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " LINK CONFIG MAXIS TV SUB WWW" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " ${vless_tls7}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e "${CYAN}════════════════════════════════════════════${NC}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " LINK CONFIG MAXIS TV SUB WWW WITH SNI" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " ${vless_tls8}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e "${CYAN}════════════════════════════════════════════${NC}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " LINK CONFIG MAXIS UNLIMITED HUNTIP" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e " ${vless_tls5}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;
echo -e "${CYAN}════════════════════════════════════════════${NC}" | tee -a /etc/kaizenvpn/vless/${Username}/config.log;