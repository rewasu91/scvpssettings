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
export SCVERSION="$( cat /etc/kaizenvpn/version )";
export EDITION="$( cat /etc/kaizenvpn/edition )";
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

# ══════════════
# // PortDeclare
# ══════════════
domain=$( cat /etc/kaizenvpn/domain.txt );
openssh=$( cat /etc/ssh/sshd_config | grep -E Port | head -n1 | awk '{print $2}' );
dropbear1=$( cat /etc/default/dropbear | grep -E DROPBEAR_PORT | sed 's/DROPBEAR_PORT//g' | sed 's/=//g' | sed 's/"//g' |  tr -d '\r' );
dropbear2=$( cat /etc/default/dropbear | grep -E DROPBEAR_EXTRA_ARGS | sed 's/DROPBEAR_EXTRA_ARGS//g' | sed 's/=//g' | sed 's/"//g' | awk '{print $2}' |  tr -d '\r' );
ovpn_tcp="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)";
ovpn_udp="$(netstat -nlpu | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)";
stunnel_dropbear=$( cat /etc/stunnel/stunnel.conf | grep -i accept | head -n 4 | cut -d= -f2 | sed 's/ //g' | tr '\n' ' ' | awk '{print $2}' | tr -d '\r' );
stunnel_ovpn_tcp=$( cat /etc/stunnel/stunnel.conf | grep -i accept | head -n 4 | cut -d= -f2 | sed 's/ //g' | tr '\n' ' ' | awk '{print $3}' | tr -d '\r' );
ssh_ssl2=$( cat /lib/systemd/system/sslh.service | grep -w ExecStart | head -n1 | awk '{print $6}' | sed 's/0.0.0.0//g' | sed 's/://g' | tr '\n' ' ' | tr -d '\r' | sed 's/ //g' );
ssh_nontls=$( cat /etc/kaizenvpn/ws-epro.conf | grep -i listen_port |  head -n 4 | cut -d= -f2 | sed 's/ //g' | sed 's/listen_port//g' | sed 's/://g' | tr '\n' ' ' | awk '{print $1}' | tr -d '\r' );
ssh_ssl=$( cat /etc/kaizenvpn/ws-epro.conf | grep -i listen_port |  head -n 4 | cut -d= -f2 | sed 's/ //g' | sed 's/listen_port//g' | sed 's/://g' | tr '\n' ' ' | awk '{print $2}' | tr -d '\r' );
squid1=$( cat /etc/squid/squid.conf | grep http_port | head -n 3 | cut -d= -f2 | awk '{print $2}' | sed 's/ //g' | tr '\n' ' ' | awk '{print $1}' );
squid2=$( cat /etc/squid/squid.conf | grep http_port | head -n 3 | cut -d= -f2 | awk '{print $2}' | sed 's/ //g' | tr '\n' ' ' | awk '{print $2}' );
ohp_1="$( cat /etc/systemd/system/ohp-mini-1.service | grep -i Port | awk '{print $3}' | head -n1)";
ohp_2="$( cat /etc/systemd/system/ohp-mini-2.service | grep -i Port | awk '{print $3}' | head -n1)";
ohp_3="$( cat /etc/systemd/system/ohp-mini-3.service | grep -i Port | awk '{print $3}' | head -n1)";
ohp_4="$( cat /etc/systemd/system/ohp-mini-4.service | grep -i Port | awk '{print $3}' | head -n1)";
udp_1=$( cat /etc/systemd/system/udp-mini-1.service | grep -i listen-addr | awk '{print $3}' | head -n1 | sed 's/127.0.0.1//g' | sed 's/://g' | tr -d '\r' );
udp_2=$( cat /etc/systemd/system/udp-mini-2.service | grep -i listen-addr | awk '{print $3}' | head -n1 | sed 's/127.0.0.1//g' | sed 's/://g' | tr -d '\r' );
udp_3=$( cat /etc/systemd/system/udp-mini-3.service | grep -i listen-addr | awk '{print $3}' | head -n1 | sed 's/127.0.0.1//g' | sed 's/://g' | tr -d '\r' );
tls_port=$( cat /etc/xray-mini/tls.json | grep -w port | awk '{print $2}' | head -n1 | sed 's/,//g' | tr '\n' ' ' | tr -d '\r' | tr -d '\r\n' | sed 's/ //g' );
nontls_port=$( cat /etc/xray-mini/nontls.json | grep -w port | awk '{print $2}' | head -n1 | sed 's/,//g' | tr '\n' ' ' | tr -d '\r' | tr -d '\r\n' | sed 's/ //g' );
ssport=$( cat /etc/xray-mini/shadowsocks.json | grep -w port | awk '{print $2}' | head -n1 | sed 's/,//g' | tr '\n' ' ' | tr -d '\r' | tr -d '\r\n' | sed 's/ //g' );
ssrport=$(( $(cat /etc/kaizenvpn/ssr-server/mudb.json | grep '"port": ' | tail -n1 | awk '{print $2}' | cut -d "," -f 1 | cut -d ":" -f 1 ) + 1 ));
httpport=$( cat /etc/xray-mini/http.json | grep -w port | awk '{print $2}' | head -n1 | sed 's/,//g' | tr '\n' ' ' | tr -d '\r' | tr -d '\r\n' | sed 's/ //g' );
sockssport=$( cat /etc/xray-mini/socks.json | grep -w port | awk '{print $2}' | head -n1 | sed 's/,//g' | tr '\n' ' ' | tr -d '\r' | tr -d '\r\n' | sed 's/ //g' );

waktu_sekarang=$(date -d "0 days" +"%Y-%m-%d");
#expired_date="$EXPIRED";
now_in_s=$(date -d "$waktu_sekarang" +%s);
exp_in_s=$(date -d "$expired_date" +%s);
days_left=$(( ($exp_in_s - $now_in_s) / 86400 ));

# // Code for service
if [[ $(systemctl status nginx | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    NGINX_STT="${GREEN}Running${NC}";
else
    NGINX_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status stunnel4 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    STUNNEL4_STT="${GREEN}Running${NC}";
else
    STUNNEL4_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status stunnel4 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OVPNSTUNNEL4_STT="${GREEN}Running${NC}";
else
    OVPNSTUNNEL4_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ssh | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active grep" ]]; then
    SSH_STT="${GREEN}Running${NC}";
else
    SSH_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status dropbear | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    DROPBEAR_STT="${GREEN}Running${NC}";
else
    DROPBEAR_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ws-epro | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    WSEPRO_STT1="${GREEN}Running${NC}";
else
    WSEPRO_STT1="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ws-epro | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    WSEPRO_STT2="${GREEN}Running${NC}";
else
    WSEPRO_STT2="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ohp-mini-1 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OHP_1="${GREEN}Running${NC}";
else
    OHP_1="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ohp-mini-2 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OHP_2="${GREEN}Running${NC}";
else
    OHP_2="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ohp-mini-3 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OHP_3="${GREEN}Running${NC}";
else
    OHP_3="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ohp-mini-4 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OHP_4="${GREEN}Running${NC}";
else
    OHP_4="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ohp-mini-4 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OHP_4="${GREEN}Running${NC}";
else
    OHP_4="${RED}Not Running${NC}";
fi
if [[ $(systemctl status squid | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SQUID_STT="${GREEN}Running${NC}";
else
    SQUID_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status sslh | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SSLH_STT="${GREEN}Running${NC}";
else
    SSLH_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status sslh | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SSLH_STT="${GREEN}Running${NC}";
else
    SSLH_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status xray-mini@tls | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    XRAY_TCP="${GREEN}Running${NC}";
else
    XRAY_TCP="${RED}Not Running${NC}";
fi
if [[ $(systemctl status xray-mini@nontls | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    XRAY_NTLS="${GREEN}Running${NC}";
else
    XRAY_NTLS="${RED}Not Running${NC}";
fi
if [[ $(systemctl status xray-mini@shadowsocks | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SS_UDP="${GREEN}Running${NC}";
else
    SS_UDP="${RED}Not Running${NC}";
fi
if [[ $(systemctl status xray-mini@socks | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SOCKS_STT="${GREEN}Running${NC}";
else
    SOCKS_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status xray-mini@http | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    HTTP_STT="${GREEN}Running${NC}";
else
    HTTP_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status xray-mini@http | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    HTTP_STT="${GREEN}Running${NC}";
else
    HTTP_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ssr-server | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SSR_UDP="${GREEN}Running${NC}";
else
    SSR_UDP="${RED}Not Running${NC}";
fi
if [[ $(systemctl status wg-quick@wg0 | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    WG_STT="${GREEN}Running${NC}";
else
    WG_STT="${RED}Not Running${NC}";
fi
if [[ $(systemctl status openvpn@tcp | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OVPN_TCP="${GREEN}Running${NC}";
else
    OVPN_TCP="${RED}Not Running${NC}";
fi
if [[ $(systemctl status openvpn@udp | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    OVPN_UDP="${GREEN}Running${NC}";
else
    OVPN_UDP="${RED}Not Running${NC}";
fi
if [[ $(systemctl status vmess-kill | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    VMESS_KILL="${GREEN}Running${NC}";
else
    VMESS_KILL="${RED}Not Running${NC}";
fi
if [[ $(systemctl status vless-kill | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    VLESS_KILL="${GREEN}Running${NC}";
else
    VLESS_KILL="${RED}Not Running${NC}";
fi
if [[ $(systemctl status trojan-kill | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    TROJAN_KILL="${GREEN}Running${NC}";
else
    TROJAN_KILL="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ss-kill | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SS_KILL="${GREEN}Running${NC}";
else
    SS_KILL="${RED}Not Running${NC}";
fi
if [[ $(systemctl status ssh-kill | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SSH_KILL="${GREEN}Running${NC}";
else
    SSH_KILL="${RED}Not Running${NC}";
fi
if [[ $(systemctl status sslh | grep Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == "active" ]]; then
    SSLH_SST="${GREEN}Running${NC}";
else
    SSLH_SST="${RED}Not Running${NC}";
fi

# // Ram Information
while IFS=":" read -r a b; do
    case $a in
        "MemTotal") ((mem_used+=${b/kB})); mem_total="${b/kB}" ;;
        "Shmem") ((mem_used+=${b/kB}))  ;;
        "MemFree" | "Buffers" | "Cached" | "SReclaimable")
        mem_used="$((mem_used-=${b/kB}))"
    ;;
esac
done < /proc/meminfo
Ram_Usage="$((mem_used / 1024))";
Ram_Total="$((mem_total / 1024))";

if [[ -f /etc/cron.d/auto-backup ]]; then
    STT_EMM="${GREEN}Running${NC}"
else 
    STT_EMM="${RED}Not Running${NC}"
fi

#EXPIRED
expired=$(curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access | grep $MYIP | awk '{print $3}')
echo $expired > /root/expired.txt
today=$(date -d +1day +%Y-%m-%d)
while read expired
do
	exp=$(echo $expired | curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access | grep $MYIP | awk '{print $3}')
	if [[ $exp < $today ]]; then
		Exp2="\033[1;31mExpired\033[0m"
        else
        Exp2=$(curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access | grep $MYIP | awk '{print $3}')
	fi
done < /root/expired.txt
rm /root/expired.txt
name=$(curl -sS https://raw.githubusercontent.com/rewasu91/scvpssettings/main/access | grep $MYIP | awk '{print $2}')

domain=$(cat /etc/kaizenvpn/domain.txt)

# // Status certificate
modifyTime=$(stat $HOME/.acme.sh/${domain}_ecc/${domain}.key | sed -n '7,6p' | awk '{print $2" "$3" "$4" "$5}')
modifyTime1=$(date +%s -d "${modifyTime}")
currentTime=$(date +%s)
stampDiff=$(expr ${currentTime} - ${modifyTime1})
days=$(expr ${stampDiff} / 86400)
remainingDays=$(expr 90 - ${days})
tlsStatus=${remainingDays}
if [[ ${remainingDays} -le 0 ]]; then
	tlsStatus="expired"
fi

source /etc/os-release
OS=$ID
ver=$VERSION_ID
jenis="$(ip a | grep "2:" | awk '{print $2}' | sed 's/://g')"

# // OS Uptime
uptime="$(uptime -p | cut -d " " -f 2-10)"

# //Download
# // Download/Upload today
dtoday="$(vnstat -i $jenis | grep "today" | awk '{print $2" "substr ($3, 1, 1)}')"
utoday="$(vnstat -i $jenis | grep "today" | awk '{print $5" "substr ($6, 1, 1)}')"
ttoday="$(vnstat -i $jenis | grep "today" | awk '{print $8" "substr ($9, 1, 1)}')"

# // Download/Upload yesterday
dyest="$(vnstat -i $jenis | grep "yesterday" | awk '{print $2" "substr ($3, 1, 1)}')"
uyest="$(vnstat -i $jenis | grep "yesterday" | awk '{print $5" "substr ($6, 1, 1)}')"
tyest="$(vnstat -i $jenis | grep "yesterday" | awk '{print $8" "substr ($9, 1, 1)}')"

Check_python()
{
if [[ $ver == '9' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $3" "substr ($4, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $6" "substr ($7, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $9" "substr ($10, 1, 1)}')"

elif [[ $ver == '10' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $3" "substr ($4, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $6" "substr ($7, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $9" "substr ($10, 1, 1)}')"

elif [[ $ver == '11' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $2" "substr ($3, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $5" "substr ($6, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $8" "substr ($9, 1, 1)}')"

elif [[ $ver == '12' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $2" "substr ($3, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $5" "substr ($6, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $8" "substr ($9, 1, 1)}')"

elif [[ $ver == '18.04' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $3" "substr ($4, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $6" "substr ($7, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $9" "substr ($10, 1, 1)}')"

elif [[ $ver == '20.04' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $3" "substr ($4, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $6" "substr ($7, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%b '%y"`" | awk '{print $9" "substr ($10, 1, 1)}')"

elif [[ $ver == '21.04' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $2" "substr ($3, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $5" "substr ($6, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $8" "substr ($9, 1, 1)}')"

elif [[ $ver == '21.10' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $2" "substr ($3, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $5" "substr ($6, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $8" "substr ($9, 1, 1)}')"

elif [[ $ver == '22.04' ]]; then
dmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $2" "substr ($3, 1, 1)}')"
umon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $5" "substr ($6, 1, 1)}')"
tmon="$(vnstat -i $jenis -m | grep "`date +"%Y-%m"`" | awk '{print $8" "substr ($9, 1, 1)}')"

else
echo -e "  Harap maaf. Version Debian ini tidak support!"
fi
}
Check_python

# // Getting CPU Information
ISP=$(curl -s ipinfo.io/org | cut -d " " -f 2-10 )
CITY=$(curl -s ipinfo.io/city )
JAM=$(date +%r)
DAY=$(date +%A)
DATE=$(date +%d.%m.%Y)
IPVPS=$(curl -s ipinfo.io/ip )

# // Ver Xray & V2ray
verxray="$(/usr/local/bin/xray -version | awk 'NR==1 {print $2}')"                                                                                                                                                                                                    

# // Bash
shellversion+=" ${BASH_VERSION/-*}" 
versibash=$shellversion

clear;
echo -e ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}";
echo -e "${WBBG}                   [ Maklumat Sistem ]                     ${NC}";
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}";
echo -e "  Server Uptime      ► $( uptime -p  | cut -d " " -f 2-10000 ) ";
echo -e "  Waktu Sekarang     ► $( date -d "0 days" +"%d-%m-%Y | %X" )";
echo -e "  Nama ISP           ► $ISP";
echo -e "  Operating Sistem   ► $( cat /etc/os-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME//g' | sed 's/=//g' | sed 's/"//g' )";
echo -e "  Bandar             ► $CITY";
echo -e "  Ip Vps             ► $IPVPS";
echo -e "  Domain             ► $domain";
echo -e "  Versi Xray         ► Xray-Mini 1.5.5";
echo -e "  Versi Skrip        ► $SCVERSION ($EDITION)";
echo -e "  Certificate status ► Expire pada ${tlsStatus} hari";
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}";
echo -e "${WBBG}                  [ Maklumat Bandwith ]                    ${NC}";
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}";
echo -e "  ${GREEN}Traffic       Hari Ini       Kelmarin        Bulan Ini${NC}   ";
echo -e "  Download      $dtoday         $dyest          $dmon      ";
echo -e "  Upload        $utoday         $uyest          $umon      ";
echo -e "  Total         $ttoday         $tyest          $tmon      ";
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WBBG}             [ Servis Status & Maklumat Port ]             ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "  ${CYAN}ServiS SSH, Dropbear, Stunnel4, OpenVPN, Squid & Nginx${NC}";
echo -e "  SSH                 ► ${SSH_STT}	Port ► ${GREEN}${openssh}${NC}";
echo -e "  Dropbear            ► ${DROPBEAR_STT}	Port ► ${GREEN}${dropbear1},${dropbear2}${NC}";	
echo -e "  Stunnel4            ► ${STUNNEL4_STT}	Port ► ${GREEN}${stunnel_dropbear}${NC}";
echo -e "  OpenVPN TCP         ► ${OVPN_TCP}	Port ► ${GREEN}${ovpn_tcp}${NC}";
echo -e "  OpenVPN UDP         ► ${OVPN_UDP}	Port ► ${GREEN}${ovpn_udp}${NC}";
echo -e "  OpenVPN SSL         ► ${OVPNSTUNNEL4_STT}	Port ► ${GREEN}${stunnel_ovpn_tcp}${NC}";
echo -e "  Squid Proxy         ► ${SQUID_STT}	Port ► ${GREEN}${squid1},${squid2}${NC}";
echo -e "  Nginx               ► ${NGINX_STT}	Port ► ${GREEN}85${NC}";
echo -e "  ${CYAN}Servis OHP${NC}";
echo -e "  OHP OpenSSH         ► ${OHP_1}	Port ► ${GREEN}${ohp_1}${NC}";
echo -e "  OHP Dropbear        ► ${OHP_2}	Port ► ${GREEN}${ohp_2}${NC}";
echo -e "  OHP OpenVPN         ► ${OHP_3}	Port ► ${GREEN}${ohp_3}${NC}";
echo -e "  OHP Universal       ► ${OHP_4}	Port ► ${GREEN}${ohp_4}${NC}";
echo -e "  ${CYAN}Servis Websocket${NC}";
echo -e "  SSH WS CDN          ► ${SSLH_SST}	Port ► ${GREEN}${ssh_ssl2}${NC}";
echo -e "  SSH WS TLS          ► ${WSEPRO_STT2}	Port ► ${GREEN}${ssh_ssl}${NC}";
echo -e "  SSH WS None TLS     ► ${WSEPRO_STT1}	Port ► ${GREEN}${ssh_nontls}${NC}";
echo -e "  ${CYAN}Servis Shadowsock,ShadowsockR & Wireguard${NC}";
echo -e "  Shadowsocks UDP     ► ${SS_UDP}	Port ► ${GREEN}${ssport}${NC}";
echo -e "  ShadowsocksR        ► ${SSR_UDP}	Port ► ${GREEN}${ssrport}${NC}";
echo -e "  WireGuard           ► ${WG_STT}	Port ► ${GREEN}2048${NC}";
echo -e "  ${CYAN}Servis HTTP & Socks 4/5${NC}";
echo -e "  HTTP Proxy          ► ${HTTP_STT}	Port ► ${GREEN}${httpport}${NC}";
echo -e "  Socks 4/5 Proxy     ► ${SOCKS_STT}	Port ► ${GREEN}${sockssport}${NC}";
echo -e "  ${CYAN}Servis Xray${NC}";
echo -e "  Vmess WS TLS        ► ${XRAY_TCP}	Port ► ${GREEN}${tls_port}${NC}";
echo -e "  Vmess WS None TLS   ► ${XRAY_NTLS}	Port ► ${GREEN}${nontls_port}${NC}";
echo -e "  Vmess GRPC WS TLS   ► ${XRAY_TCP}	Port ► ${GREEN}${tls_port}${NC}";
echo -e "  Vless WS TLS        ► ${XRAY_TCP}	Port ► ${GREEN}${tls_port}${NC}";
echo -e "  Vless WS None TLS   ► ${XRAY_NTLS}	Port ► ${GREEN}${nontls_port}${NC}";
echo -e "  Vless GRPC WS TLS   ► ${XRAY_TCP}	Port ► ${GREEN}${tls_port}${NC}";
echo -e "  ${CYAN}Servis Trojan${NC}";
echo -e "  Trojan WS TLS       ► ${XRAY_TCP}	Port ► ${GREEN}${tls_port}${NC}";
echo -e "  Trojan TCP TLS      ► ${XRAY_TCP}	Port ► ${GREEN}${tls_port}${NC}";
echo -e "  Trojan GRPC WS TLS  ► ${XRAY_TCP}	Port ► ${GREEN}${tls_port}${NC}";
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WBBG}        [ Status Autokill Multilogin & Autobackup]         ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "  Vmess AutoKill      ► ${VMESS_KILL}";
echo -e "  Vless AutoKill      ► ${VLESS_KILL}";
echo -e "  Trojan AutoKill     ► ${TROJAN_KILL}";
echo -e "  SS AutoKill         ► ${SS_KILL}";
echo -e "  SSH AutoKill        ► ${SSH_KILL}";
echo -e "  Autobackup          ► ${STT_EMM}";
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
