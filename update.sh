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

rm -f /root/version.sh
rm -f /root/update.sh
clear;

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

#V2.3
cd /usr/local/sbin
rm menu
rm menuautoreboot
rm autoexp
rm clearlog
rm infonya
wget -q -O /usr/local/sbin/menu "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/menu.sh"; chmod +x /usr/local/sbin/menu;
wget -q -O /usr/local/sbin/menuautoreboot "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/other/menuautoreboot.sh"; chmod +x /usr/local/sbin/menuautoreboot;
wget -q -O /usr/local/sbin/autoexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/other/autoexp.sh"; chmod +x /usr/local/sbin/autoexp;
wget -q -O /usr/local/sbin/clearlog "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/other/clearlog.sh"; chmod +x /usr/local/sbin/clearlog;
wget -q -O /usr/local/sbin/menuwebmin "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/other/menuwebmin.sh"; chmod +x /usr/local/sbin/menuwebmin;
wget -q -O /usr/local/sbin/infonya "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/other/info.sh"; chmod +x /usr/local/sbin/infonya;
rm /etc/cron.d/autoexp
rm /etc/cron.d/clearlog
rm /etc/cron.d/reboot
echo "0 0 * * * root /usr/local/sbin/autoexp" > /etc/cron.d/autoexp
echo "0 * * * * root /usr/local/sbin/clearlog" > /etc/cron.d/clearlog
echo "0 5 * * * root /usr/sbin/reboot" > /etc/cron.d/reboot
systemctl restart cron

rm /etc/kaizenvpn/version;
rm /etc/kaizenvpn/edition
export SCVERSION="V2.3";
export EDITION="Multiport Edition";
echo "$SCVERSION" > /etc/kaizenvpn/version;
echo "$EDITION" > /etc/kaizenvpn/edition;

clear
echo -e ""
echo -e ""
cowsay -f ghostbusters "SELAMAT DATANG BOSKU."
echo -e ""
figlet -k '         KAIZEN'
echo -e ""
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "${WBBG}           [ Menu Update Skrip ]            ${NC}";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e ""
echo -e "  ► Sila tunggu, sistem sedang disemak.."
sleep 2

clear
echo -e "";
echo -e "";
cowsay -f ghostbusters "SELAMAT DATANG BOSKU.";
echo -e "";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "${WBBG}               [ VERSI SKRIP ]              ${NC}";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "";
echo -e "  [Changelog]";
echo -e "  V2.3 : Tambah menu "Memasang Webmin"";
echo -e "       : Fix fungsi Autoexpire";
echo -e "  V2.2 : Tambah menu "Set Autoreboot"";
echo -e "       : Fix fungsi Autoreboot";
echo -e "       : Membuang menu "Update skrip". Sistem akan update secara automatik selepas ini";
echo -e "  V2.1 : Fix error yang terdapat di menu "Memadam Akaun" untuk servis SSH & OpenVPN";
echo -e "       : Membuang menu "Update skrip". Sistem akan update secara automatik selepas ini";
echo -e "  V2.0 : Update sistem ke Multiport Edition";
echo -e "  V1.0 : Skrip lama versi V2ray & Xray";
echo -e "";
echo -e "  Selesai! Anda sedang menggunakan skrip versi terkini !";
echo -e "  KaizenVPN skrip ${SCVERSION} ${EDITION} | Ubuntu - Debian";
echo -e "  (C) Copyright 2022 By KaizenVPN";
echo -e "";
sleep 10
