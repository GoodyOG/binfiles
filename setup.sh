#!/bin/bash
# ==========================================
#  TheTechSavage Universal Auto-Installer
#  Premium Edition - v3.5 (Verified Stable)
# ==========================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BORDER="${CYAN}════════════════════════════════════════════════════${NC}"

# --- HELPER FUNCTIONS ---
print_title() {
    clear
    echo -e "$BORDER"
    local text="$1"
    local width=54
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${CYAN}║${YELLOW}%*s%s%*s${CYAN}║${NC}\n" $padding "" "$text" $padding ""
    echo -e "$BORDER"
    sleep 1
}

print_success() { echo -e "${GREEN} [OK]   $1${NC}"; }
print_info()    { echo -e "${BLUE} [INFO] $1${NC}"; }
print_error()   { echo -e "${RED} [ERR]  $1${NC}"; }

# ======================================================
# STEP 1 — PRIVATE VAULT URL
# ======================================================
REPO_URL="http://vault.thetechsavage.org.ng/premium"


# ======================================================
# STEP 2 — SYSTEM PREPARATION
# ======================================================
print_title "SYSTEM PREPARATION"

print_info "Creating system directories..."
mkdir -p /etc/xray/limit/{vmess,vless,trojan}
mkdir -p /usr/local/etc/xray
mkdir -p /etc/openvpn

print_info "Installing essential packages..."
systemctl stop    apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1

apt update -y && apt upgrade -y
apt install -y wget curl jq socat cron zip unzip net-tools git \
    build-essential python3 python3-pip vnstat dropbear nginx \
    dnsutils dante-server stunnel4 cmake

print_info "Installing Rclone..."
curl https://rclone.org/install.sh | sudo bash > /dev/null 2>&1

# Ubuntu 24.04 compatibility patches
source /etc/os-release
if [[ "$VERSION_ID" == "24.04" ]]; then
    print_info "Ubuntu 24.04 detected — applying compatibility patches..."
    apt-get install -y iptables iptables-nft > /dev/null 2>&1
    systemctl disable --now ssh.socket  > /dev/null 2>&1
    systemctl enable  --now ssh.service > /dev/null 2>&1
    systemctl restart ssh               > /dev/null 2>&1
fi

# ======================================================
# STEP 3 — DOMAIN & NAMESERVER SETUP
# ======================================================
print_title "DOMAIN CONFIGURATION"

MYIP=$(curl -sS -4 ifconfig.me)

# --- Main Domain ---
while true; do
    echo -e "\n$BORDER"
    echo -e "${YELLOW}           ENTER YOUR DOMAIN / SUBDOMAIN            ${NC}"
    echo -e "$BORDER"
    echo -e " ${CYAN}>${NC} Create an 'A Record' pointing to: ${GREEN}$MYIP${NC}"
    echo -e " ${CYAN}>${NC} Then enter that subdomain below (e.g., vpn.mysite.com)."
    read -rp " Input SubDomain : " domain

    if [[ -z "$domain" ]]; then
        print_error "Domain cannot be empty!"
        continue
    fi

    echo -e " ${BLUE}[...] Verifying DNS for $domain...${NC}"
    DOMAIN_IP=$(dig +short "$domain" | head -n1)

    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        print_success "Verified! Domain points to this VPS."
    else
        print_error "Domain resolves to $DOMAIN_IP (expected $MYIP). Continuing anyway..."
    fi

    echo "$domain" > /etc/xray/domain
    break
done

# --- Nameserver Domain ---
echo -e "\n$BORDER"
echo -e "${YELLOW}             ENTER YOUR NAMESERVER (NS)             ${NC}"
echo -e "$BORDER"
echo -e " ${CYAN}>${NC} Required for SlowDNS (e.g., ns.vpn.mysite.com)."
echo -e " ${CYAN}>${NC} Press ENTER to use the default: ns.$domain"
read -rp " Input NS Domain : " nsdomain

if [[ -z "$nsdomain" ]]; then
    nsdomain="ns.$domain"
    print_info "Using default NS: $nsdomain"
fi
echo "$nsdomain" > /etc/xray/nsdomain
print_success "NS Domain saved: $nsdomain"

# ======================================================
# STEP 4 — CONFIGURE DROPBEAR
# ======================================================
print_title "CONFIGURING DROPBEAR SSH"

echo "/bin/false"       >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

cat > /etc/issue.net <<'EOF'
<html>
<body>
<h3 style="text-align:center;">
  <span style="color:#0000FF;">
    <strong>Premium Server — @THETECHSAVAGE &amp; @TheTechSavageFreebie</strong>
  </span>
</h3>
<p><font color="red"><b>Terms Of Service (TOS)</b></font></p>
<ul>
  <li>NO Multi Login</li>
  <li>NO DDoS</li>
  <li>NO Carding / Hacking / Illegal Use</li>
  <li>NO Torrenting</li>
  <li>NO SPAM</li>
</ul>
<p><font color="red">Violations result in permanent suspension without warning.</font></p>
<p style="text-align:center;">
  Support: <a href="https://t.me/TheTechSavageSupport">Telegram</a> |
  <a href="https://t.me/TheTechSavageTelegram">Channel</a> |
  <a href="https://thetechsavage.org.ng">Website</a>
</p>
</body>
</html>
EOF

# OpenSSH banner (24.04-safe method)
mkdir -p /etc/ssh/sshd_config.d
echo "Banner /etc/issue.net" > /etc/ssh/sshd_config.d/99-custom-banner.conf
sed -i 's/^Banner/#Banner/g' /etc/ssh/sshd_config 2>/dev/null

# Keep-alive settings
echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config.d/99-keepalive.conf
echo "ClientAliveCountMax 2"  >> /etc/ssh/sshd_config.d/99-keepalive.conf

# Dropbear: banner + aggressive keep-alive
sed -i 's/^DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-b \/etc\/issue.net -K 35 -I 60"/' /etc/default/dropbear
grep -q "^DROPBEAR_EXTRA_ARGS=" /etc/default/dropbear || \
    echo 'DROPBEAR_EXTRA_ARGS="-b /etc/issue.net -K 35 -I 60"' >> /etc/default/dropbear

systemctl restart ssh dropbear
print_success "Dropbear & SSH configured with anti-ghost keep-alive settings."

# ======================================================
# STEP 5 — INSTALL XRAY CORE
# ======================================================
print_title "INSTALLING XRAY CORE"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# ======================================================
# STEP 6 — GENERATE SSL/TLS CERTIFICATE
# ======================================================
print_title "GENERATING SSL CERTIFICATE"

systemctl stop nginx
mkdir -p /root/.acme.sh

curl -s https://get.acme.sh | sh -s email=admin@"$domain"
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
/root/.acme.sh/acme.sh --installcert -d "$domain" \
    --fullchainpath /etc/xray/xray.crt \
    --keypath      /etc/xray/xray.key \
    --ecc

# Fallback: self-signed cert if Let's Encrypt failed
if [[ ! -s /etc/xray/xray.crt || ! -s /etc/xray/xray.key ]]; then
    print_info "Let's Encrypt failed or returned empty. Generating self-signed fallback..."
    rm -f /etc/xray/xray.crt /etc/xray/xray.key
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/xray/xray.key \
        -out    /etc/xray/xray.crt \
        -subj "/C=US/ST=State/L=City/O=TheTechSavage/CN=$domain" 2>/dev/null
fi

chmod 644 /etc/xray/xray.key /etc/xray/xray.crt
print_success "SSL certificate installed."

# ======================================================
# STEP 6.5 — CONFIGURE STUNNEL4
# ======================================================
print_title "CONFIGURING STUNNEL4"

cat /etc/xray/xray.key /etc/xray/xray.crt > /etc/stunnel/stunnel.pem

cat > /etc/stunnel/stunnel.conf <<EOF
pid  = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear_tls_1]
accept  = 447
connect = 127.0.0.1:109

[dropbear_tls_2]
accept  = 777
connect = 127.0.0.1:109
EOF

sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl enable stunnel4
systemctl restart stunnel4
print_success "Stunnel4 configured (ports 447, 777)."

# ======================================================
# STEP 7 — INSTALL BADVPN UDPGW
# ======================================================
print_title "INSTALLING BADVPN UDPGW"

git clone https://github.com/ambrop72/badvpn.git /tmp/badvpn > /dev/null 2>&1
mkdir -p /tmp/badvpn/build
cd /tmp/badvpn/build || exit 1
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
make install > /dev/null 2>&1
cd ~ || exit 1
rm -rf /tmp/badvpn

cat > /etc/systemd/system/udpgw.service <<EOF
[Unit]
Description=BadVPN UDPGW
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw \
    --listen-addr 127.0.0.1:7300 \
    --max-clients 1000 \
    --max-connections-for-client 10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udpgw
systemctl start  udpgw
print_success "UDPGW installed and running on port 7300."

# ======================================================
# STEP 7.5 — CONFIGURE NGINX PROXY/MULTIPLEXER
# ======================================================
print_title "CONFIGURING NGINX PROXY"

fuser -k 80/tcp  > /dev/null 2>&1
fuser -k 81/tcp  > /dev/null 2>&1
fuser -k 443/tcp > /dev/null 2>&1

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

cat > /etc/nginx/conf.d/vps.conf <<EOF
server {
    listen 81;
    listen 443 ssl;
    server_name $domain;

    ssl_certificate     /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols       TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers         EECDH+CHACHA20:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:!MD5;

    location / {
        proxy_pass         http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_redirect     off;
    }
    location /vless {
        proxy_pass         http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_redirect     off;
    }
    location /vless-hu {
        proxy_pass         http://127.0.0.1:10004;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_redirect     off;
    }
    location /vmess {
        proxy_pass         http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_redirect     off;
    }
    location /vmess-hu {
        proxy_pass         http://127.0.0.1:10005;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_redirect     off;
    }
    location /trojan-ws {
        proxy_pass         http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_redirect     off;
    }
}
EOF

nginx -t && systemctl restart nginx
print_success "Nginx multiplexer configured."

# ======================================================
# STEP 7.6 — INSTALL SLOWDNS (DNSTT)
# ======================================================
print_title "INSTALLING SLOWDNS"

mkdir -p /etc/slowdns

print_info "Downloading SlowDNS binary..."
wget -q -O /etc/slowdns/dnstt-server "${REPO_URL}/core/dnstt-server"
chmod +x /etc/slowdns/dnstt-server

print_info "Writing static keys..."
echo "a0946ee29693f2394e60b251b6c9e8d5b2f3bc8d753deebf8ce778773dbe10bc" > /etc/slowdns/server.key
echo "68a93ff4e08ea51657ede89c8dcc6534088d8461c1209743c11b96399beb1408" > /etc/slowdns/server.pub
chmod 600 /etc/slowdns/server.key
chmod 644 /etc/slowdns/server.pub

nsdomain=$(cat /etc/xray/nsdomain)

cat > /etc/systemd/system/client-slow.service <<EOF
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sh -c 'iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true'
ExecStart=/etc/slowdns/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $nsdomain 127.0.0.1:109
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true
systemctl daemon-reload
systemctl enable client-slow
systemctl restart client-slow
print_success "SlowDNS configured (static mode)."

# ======================================================
# STEP 7.7 — INSTALL OPENVPN
# ======================================================
print_title "INSTALLING OPENVPN"

wget -q -O /tmp/openvpn.sh "${REPO_URL}/core/openvpn.sh"
chmod +x /tmp/openvpn.sh
/tmp/openvpn.sh
rm -f /tmp/openvpn.sh

# ======================================================
# STEP 8 — DOWNLOAD SCRIPTS & BINARIES
# ======================================================
print_title "DOWNLOADING SCRIPTS"

download_bin() {
    local folder="$1"
    local file="$2"
    wget -q -O "/usr/bin/$file" "${REPO_URL}/$folder/$file"
    chmod +x "/usr/bin/$file"
    print_success "Installed: $file"
}

# Core configs
wget -q -O /usr/local/etc/xray/config.json     "${REPO_URL}/core/config.json.template"
wget -q -O /etc/systemd/system/xray.service    "${REPO_URL}/core/xray.service"
wget -q -O /etc/xray/ohp.py                    "${REPO_URL}/core/ohp.py"
wget -q -O /etc/xray/proxy.py                  "${REPO_URL}/core/proxy.py"
wget -q -O /etc/xray/proxy-8880.py             "${REPO_URL}/core/proxy-8880.py"
download_bin "core" "auth.sh"

# Rclone / Google Drive auth
print_info "Fetching cloud auth config (Rclone)..."
mkdir -p /root/.config/rclone
wget -q -O /root/.config/rclone/rclone.conf "${REPO_URL}/core/rclone.conf"

# SSH-WebSocket proxy (port 80)
print_info "Creating SSH-WS proxy service (port 80)..."
cat > /etc/systemd/system/ws-proxy.service <<EOF
[Unit]
Description=Python SSH-WS Proxy
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xray
ExecStart=/usr/bin/python3 /etc/xray/proxy.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-proxy
systemctl restart ws-proxy
print_success "SSH-WS proxy service configured."

# SSH proxy (port 8880)
print_info "Creating SSH proxy service (port 8880)..."
cat > /etc/systemd/system/ws-8880.service <<EOF
[Unit]
Description=Python SSH Proxy (Port 8880)
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xray
ExecStart=/usr/bin/python3 /etc/xray/proxy-8880.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-8880
systemctl restart ws-8880
print_success "SSH proxy (port 8880) configured."

# Menu scripts
for f in menu menu-domain.sh menu-set.sh menu-ssh.sh menu-trojan.sh menu-vless.sh menu-vmess.sh running.sh; do
    download_bin "menu" "$f"
done

# SSH management scripts
for f in usernew trial renew hapus member delete autokill cek tendang xp backup restore \
         cleaner health-check show-conf ceklim speedtest api-ssh locker limit user-timed; do
    download_bin "ssh" "$f"
done

mv /usr/bin/backup  /usr/bin/backup.sh  2>/dev/null
mv /usr/bin/restore /usr/bin/restore.sh 2>/dev/null

# Xray management scripts
for f in add-ws del-ws renew-ws cek-ws trial-ws member-ws \
         add-vless del-vless renew-vless cek-vless trial-vless member-vless \
         add-tr del-tr renew-tr cek-tr trial-tr member-tr; do
    download_bin "xray" "$f"
done

# ======================================================
# STEP 8.5 — CONFIGURE SOCKS5 (DANTE)
# ======================================================
print_info "Configuring SOCKS5 proxy (port 1080)..."

NIC=$(ip -o -4 route show to default | head -n1 | awk '{print $5}')

cat > /etc/danted.conf <<EOF
logoutput: syslog
user.privileged:   root
user.unprivileged: nobody

internal: 0.0.0.0 port = 1080
external: $NIC

socksmethod: username
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
EOF

systemctl enable danted
systemctl restart danted
print_success "SOCKS5 configured."

# ======================================================
# STEP 9 — FIREWALL (UFW)
# ======================================================
print_info "Configuring UFW firewall..."

apt-get install -y ufw > /dev/null 2>&1

for port in 22 80 81 109 143 443 447 777 1080 7300 8880; do
    ufw allow "$port"/tcp > /dev/null 2>&1
done
ufw allow 53/udp > /dev/null 2>&1

ufw --force enable
print_success "Firewall configured."

# ======================================================
# DONE
# ======================================================
echo -e "\n$BORDER"
echo -e "${GREEN}   Installation complete! Run 'menu' to manage your VPS.${NC}"
echo -e "$BORDER\n"
