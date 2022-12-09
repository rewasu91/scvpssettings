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

# ══════════════════════════════
# // Mendapatkan maklumat Domain
# ══════════════════════════════
export domain=$( cat /etc/kaizenvpn/domain.txt );

#V2.6
mv /usr/local/kaizenvpn/xray-mini /root/.backupxray
wget -q -O /usr/local/kaizenvpn/xray-mini "https://raw.githubusercontent.com/rewasu91/scvps/main/Resource/Core/xray-mini";
chmod 755 /usr/local/kaizenvpn/xray-mini
systemctl restart xray-mini@tls;
systemctl restart xray-mini@nontls;
systemctl restart xray-mini@socks;
systemctl restart xray-mini@shadowsocks;
systemctl restart xray-mini@http;
systemctl restart nginx;
systemctl restart fail2ban;
systemctl restart ssr-server;
systemctl restart dropbear;
systemctl restart ssh;
systemctl restart stunnel4;
systemctl restart sslh;

#V2.5
rm /usr/local/kaizenvpn/vmess-auto-kill
rm /usr/local/kaizenvpn/ssh-auto-kill
rm /usr/local/kaizenvpn/vless-auto-kill
rm /usr/local/kaizenvpn/trojan-auto-kill
rm /usr/local/kaizenvpn/ss-auto-kill
rm /usr/local/sbin/autokill-menu
rm /usr/local/sbin/listmulti
rm /usr/local/sbin/vpnscript
wget -q -O /usr/local/kaizenvpn/vmess-auto-kill "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/Pro/Autokill/vmess-kill.sh"; chmod +x /usr/local/kaizenvpn/vmess-auto-kill;
wget -q -O /usr/local/kaizenvpn/ssh-auto-kill "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/Pro/Autokill/ssh-kill.sh"; chmod +x /usr/local/kaizenvpn/ssh-auto-kill;
wget -q -O /usr/local/kaizenvpn/vless-auto-kill "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/Pro/Autokill/vless-kill.sh"; chmod +x /usr/local/kaizenvpn/vless-auto-kill;
wget -q -O /usr/local/kaizenvpn/trojan-auto-kill "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/Pro/Autokill/trojan-kill.sh"; chmod +x /usr/local/kaizenvpn/trojan-auto-kill;
wget -q -O /usr/local/kaizenvpn/ss-auto-kill "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/Pro/Autokill/ss-kill.sh"; chmod +x /usr/local/kaizenvpn/ss-auto-kill;
wget -q -O /usr/local/sbin/autokill-menu "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/Pro/Autokill/menu.sh"; chmod +x /usr/local/sbin/autokill-menu;
wget -q -O /usr/local/sbin/listmulti "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/Pro/Autokill/listmulti.sh"; chmod +x /usr/local/sbin/listmulti;
wget -q -O /usr/local/sbin/vpnscript "https://raw.githubusercontent.com/rewasu91/scvps/main/Setup/script-version.sh"; chmod +x /usr/local/sbin/vpnscript;
systemctl enable vmess-kill;
systemctl enable ssh-kill;
systemctl enable vless-kill;
systemctl enable trojan-kill;
systemctl enable ss-kill;
systemctl start vmess-kill;
systemctl start ssh-kill;
systemctl start vless-kill;
systemctl start trojan-kill;
systemctl start ss-kill;
systemctl restart vmess-kill;
systemctl restart ssh-kill;
systemctl restart vless-kill;
systemctl restart trojan-kill;
systemctl restart ss-kill;

#V2.4
cd /usr/local/sbin
rm vmessexp
rm vlessexp
rm trojanexp
rm httpexp
rm socksexp
rm ssexp
rm sshexp
rm ssrexp
rm wgexp
wget -q -O /usr/local/sbin/vmessexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/vmess/vmessexp.sh"; chmod +x /usr/local/sbin/vmessexp;
wget -q -O /usr/local/sbin/vlessexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/vless/vlessexp.sh"; chmod +x /usr/local/sbin/vlessexp;
wget -q -O /usr/local/sbin/trojanexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/trojan/trojanexp.sh"; chmod +x /usr/local/sbin/trojanexp;
wget -q -O /usr/local/sbin/httpexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/http/httpexp.sh"; chmod +x /usr/local/sbin/httpexp;
wget -q -O /usr/local/sbin/socksexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/socks/socksexp.sh"; chmod +x /usr/local/sbin/socksexp;
wget -q -O /usr/local/sbin/ssexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/ss/ssexp.sh"; chmod +x /usr/local/sbin/ssexp;
wget -q -O /usr/local/sbin/sshexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/ssh/sshexp.sh"; chmod +x /usr/local/sbin/sshexp;
wget -q -O /usr/local/sbin/ssrexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/ssr/ssrexp.sh"; chmod +x /usr/local/sbin/ssrexp;
wget -q -O /usr/local/sbin/wgexp "https://raw.githubusercontent.com/rewasu91/scvps/main/Menu/wg/wgexp.sh"; chmod +x /usr/local/sbin/wgexp;

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

systemctl enable xray-mini@shadowsocks;
systemctl enable xray-mini@tls;
systemctl enable xray-mini@nontls;
systemctl enable xray-mini@socks;
systemctl enable xray-mini@http;
systemctl start xray-mini@shadowsocks;
systemctl start xray-mini@tls;
systemctl start xray-mini@nontls;
systemctl start xray-mini@socks;
systemctl start xray-mini@http;
systemctl restart xray-mini@shadowsocks;
systemctl restart xray-mini@nontls
systemctl restart xray-mini@tls
systemctl restart xray-mini@socks
systemctl restart xray-mini@http

rm /etc/kaizenvpn/version;
rm /etc/kaizenvpn/edition
export SCVERSION="V2.6";
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

# // Make Folder for save the changelog
mkdir -p /etc/kaizenvpn/changelog/;
rm -f /etc/kaizenvpn/changelog/ch.log;

clear
echo -e "";
echo -e "";
cowsay -f ghostbusters "SELAMAT DATANG BOSKU.";
echo -e "";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "${WBBG}               [ VERSI SKRIP ]              ${NC}";
echo -e "${CYAN}════════════════════════════════════════════${NC}";
echo -e "";
echo -e "  [Changelog]" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V2.6 : Update Xray Core (Support CF-RAY)" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V2.5 : Fix fungsi Autokill Multilogin" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "       : Tambah Changelog dalam menu "Cek versi skrip"" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V2.4 : Fix fungsi Autoexpire" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V2.3 : Tambah menu "Memasang Webmin"" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V2.2 : Tambah menu "Set Autoreboot"" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "       : Fix fungsi Autoreboot" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "       : Membuang menu "Update skrip". Sistem akan update secara automatik selepas ini" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V2.1 : Fix error yang terdapat di menu "Memadam Akaun" untuk servis SSH & OpenVPN" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "       : Membuang menu "Update skrip". Sistem akan update secara automatik selepas ini" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V2.0 : Update sistem ke Multiport Edition" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "  V1.0 : Skrip lama versi V2ray & Xray" | tee -a /etc/kaizenvpn/changelog/ch.log;
echo -e "";
echo -e "  Selesai! Anda sedang menggunakan skrip versi terkini !";
echo -e "  KaizenVPN skrip ${SCVERSION} ${EDITION} | Ubuntu - Debian";
echo -e "  (C) Copyright 2022 By KaizenVPN";
echo -e "";
sleep 10
