#!/bin/bash

# === Konfigurasi ===
PUB_IP_SERVER="109.199.103.201"
PUB_IP_CLIENT="109.199.103.206"
NETMASK="255.255.240.0"
DEV="eth0"
VPN_IF="tun0"
VPN_SUBNET="10.8.0.0"
VPN_MASK="255.255.255.0"
CLIENT_NAME="client1"

# === Aktifkan IP Forwarding dan Proxy ARP ===
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.$DEV.proxy_arp=1" >> /etc/sysctl.conf
sysctl -p

# === Tambahkan IP Publik Klien ke Interface ===
ip addr add $PUB_IP_CLIENT/20 dev $DEV

# === Tambahkan Routing ke Interface VPN ===
ip route add $PUB_IP_CLIENT dev $VPN_IF

# === Install OpenVPN ===
apt update && apt install openvpn easy-rsa -y

# === Setup Easy-RSA ===
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
echo | ./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey --secret ta.key
./easyrsa gen-req $CLIENT_NAME nopass
./easyrsa sign-req client $CLIENT_NAME

# === Salin Sertifikat ===
cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem ta.key /etc/openvpn

# === Konfigurasi Server ===
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev $VPN_IF
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server $VPN_SUBNET $VPN_MASK
client-config-dir /etc/openvpn/ccd
ifconfig-pool-persist ipp.txt
keepalive 10 120
tls-auth ta.key 0
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

# === Konfigurasi CCD ===
mkdir -p /etc/openvpn/ccd
cat > /etc/openvpn/ccd/$CLIENT_NAME <<EOF
ifconfig-push $PUB_IP_CLIENT $NETMASK
EOF

# === Aturan iptables ===
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -A FORWARD -i $VPN_IF -o $DEV -j ACCEPT
iptables -A FORWARD -i $DEV -o $VPN_IF -j ACCEPT

# === Enable dan Start OpenVPN ===
systemctl enable openvpn@server
systemctl start openvpn@server

echo -e "\n✅ OpenVPN dengan IP publik $PUB_IP_CLIENT telah dikonfigurasi!"
