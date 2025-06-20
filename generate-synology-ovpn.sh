#!/bin/bash

# === Variabel ===
CLIENT_CN="synology"
REMOTE_IP="217.15.165.61"
PORT="1194"
OUTPUT="synology.ovpn"
EASYRSA_DIR="/etc/openvpn/easy-rsa"

# === Lokasi File ===
CA="${EASYRSA_DIR}/pki/ca.crt"
CERT="${EASYRSA_DIR}/pki/issued/${CLIENT_CN}.crt"
KEY="${EASYRSA_DIR}/pki/private/${CLIENT_CN}.key"
TA="${EASYRSA_DIR}/ta.key"

# === Cek apakah semua file ada ===
for f in "$CA" "$CERT" "$KEY" "$TA"; do
    [ -f "$f" ] || { echo "❌ File tidak ditemukan: $f"; exit 1; }
done

# === Buat file .ovpn ===
cat > $OUTPUT <<EOF
client
dev tun
proto udp
remote $REMOTE_IP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
auth-nocache
remote-cert-tls server
comp-lzo
verb 3
key-direction 1

<ca>
$(cat "$CA")
</ca>

<cert>
$(cat "$CERT")
</cert>

<key>
$(cat "$KEY")
</key>

<tls-auth>
$(cat "$TA")
</tls-auth>
EOF

echo "✅ Berhasil membuat file: $OUTPUT"
