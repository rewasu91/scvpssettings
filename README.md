<h2 align="center">
Autoskrip KaizenVPN
<img src="https://img.shields.io/badge/Version-2.0 (Xray Multiport Edition)-blue.svg"></h2>

</p> 
<p align="center"><img src="https://d33wubrfki0l68.cloudfront.net/5911c43be3b1da526ed609e9c55783d9d0f6b066/9858b/assets/img/debian-ubuntu-hover.png"></p> 
<p align="center"><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=debian&label=Debian%209&message=Stretch&color=purple"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=debian&label=Debian%2010&message=Buster&color=purple"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=debian&label=Debian%2011&message=Bulsseye&color=purple"> </p><p align="center"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2018&message=Lts&color=red"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2020&message=Lts&color=red"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2021&message=Lts&color=red">
</p>

## ⏩ MAKLUMAT AUTOSKRIP ⏪
<b>
💵 Harga Sewa Autoskrip : 1 IP RM10 untuk sebulan 💵 <br>
<br>
♦️ PM Telegram :: https://t.me/KaizenA <br>
 <br>

### STEP PERTAMA
Sila copy skrip dibawah dan paste kedalam VPS anda. Selepas selesai, sistem akan reboot sebentar. Sila tunggu sistem reboot, kemudian sambung step kedua dibawah.

```
apt update && apt upgrade -y --fix-missing && update-grub && sleep 2 && reboot
```

### STEP KEDUA
Sila copy skrip dibawah dan paste kedalam VPS anda. Sekiranya keluar pertanyaan untuk pertama kalinya, sila taip okey. Kemudian, sila tekan ENTER sahaja untuk semua pertanyaan yang berikutnya. Selepas selesai, sistem akan reboot sebentar. Sila tunggu sistem reboot, kemudian sambung step ketiga dibawah.

```
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl && wget https://raw.githubusercontent.com/rewasu91/scvps/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

### STEP KETIGA
Masuk kedalam VPS anda, dan taip Menu. Sila semak status sistem menggunakan Menu nombor 23. Sekiranya terdapat error pada Dropbear/Stunnel (Not Running), sila copy script dibawah dan paste kedalam VPS anda (sekiranya tiada error, sila abaikan step ketiga ini dan anda boleh mula menggunakan VPS anda!). Sila tekan ENTER sahaja untuk semua pertanyaan yang berikutnya. Selepas selesai, sistem akan reboot sebentar. Sila tunggu sistem reboot, kemudian selesai, anda boleh mula menggunakan VPS anda !

```
./ssh-ssl.sh
```
