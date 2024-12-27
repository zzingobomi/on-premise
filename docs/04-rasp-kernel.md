### Raspberry Pi 커널 컴파일

- firstrun.sh (고정아이피 세팅)
- 아직 테스트는 못해봄

```bash
cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""

KBEOF
   dpkg-reconfigure -f noninteractive keyboard-configuration
fi

nmcli con add type ethernet con-name "static-eth0" ifname eth0 ip4 192.168.0.103/24 gw4 192.168.0.1
nmcli con mod "static-eth0" ipv4.dns "164.124.107.9,8.8.4.4"
nmcli con up "static-eth0"

rm -f /boot/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
exit 0
```

```bash
apt-get install git bc bison flex libssl-dev

git clone --depth=1 https://github.com/raspberrypi/linux
```
