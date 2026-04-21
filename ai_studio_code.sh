#!/bin/bash
# ==========================================
#  TheTechSavage Universal Auto-Installer (Refined & Unlocked)
#  Premium Edition - v3.5 (Verified Stable)
#  Cleaned and Structured by goodyog
# ==========================================

# --- CONFIGURATION ---
# IMPORTANT: Change this URL to point to your own GitHub repository where you will store the script files.
# The structure should be: YourRepo/main/FOLDER/SCRIPT_NAME
REPO_URL="https://raw.githubusercontent.com/goodyog/AIO-Autoscript/main"

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper for "Futuristic" Headers (FIXED WIDTH = 54 Chars)
function print_title() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    # Center text manually for perfect alignment
    local text="$1"
    local width=54
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${CYAN}│${YELLOW}%*s%s%*s${CYAN}│${NC}\n" $padding "" "$text" $padding ""
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    sleep 1
}

function print_success() {
    echo -e "${GREEN} [OK] $1${NC}"
}

function print_info() {
    echo -e "${BLUE} [INFO] $1${NC}"
}

# ==========================================
# 1. INITIAL BANNER & PREPARATION
# ==========================================
clear
echo -e "\033[0;36m┌────────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[0;36m│\033[0m           \033[0;32mTHETECHSAVAGE AUTOSCRIPT INSTALLER\033[0m           \033[0;36m│\033[0m"
echo -e "\033[0;36m│\033[0m  \033[0;33m      Unlocked & Refined by @goodyog            \033[0;36m│\033[0m"
echo -e "\033[0;36m└────────────────────────────────────────────────────────┘\033[0m"
sleep 2

# ==========================================
# 2. SYSTEM PREPARATION
# ==========================================
print_title "SYSTEM PREPARATION"
print_info "Creating System Directories..."
mkdir -p /etc/xray /etc/xray/limit/{vmess,vless,trojan} /usr/local/etc/xray /etc/openvpn

print_info "Installing Essential Packages..."
# Stop Apache if it exists to prevent port conflicts with Nginx
systemctl stop apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1

apt update -y && apt upgrade -y
apt install -y wget curl jq socat cron zip unzip net-tools git build-essential python3 python3-pip vnstat dropbear nginx dnsutils dante-server stunnel4 cmake

print_info "Installing Rclone for backup utilities..."
curl https://rclone.org/install.sh | sudo bash > /dev/null 2>&1

# --- OS DETECTOR & UBUNTU 24.04 COMPATIBILITY PATCH ---
source /etc/os-release
if [[ "$VERSION_ID" == "24.04" ]]; then
    print_info "Ubuntu 24.04 Detected: Applying Network & SSH Patches..."
    apt-get install -y iptables iptables-nft > /dev/null 2>&1
    systemctl disable --now ssh.socket > /dev/null 2>&1
    systemctl enable --now ssh.service > /dev/null 2>&1
    systemctl restart ssh > /dev/null 2>&1
fi
print_success "System Preparation Complete!"

# ==========================================
# 3. DOMAIN & NS SETUP
# ==========================================
print_title "DOMAIN CONFIGURATION"
MYIP=$(curl -sS -4 ifconfig.me)

# --- A. Main Domain ---
while true; do
    echo -e ""
    echo -e " ${CYAN}>${NC} Please create an 'A Record' in your DNS pointing to: ${GREEN}$MYIP${NC}"
    read -p "   Input your Subdomain (e.g., vpn.mysite.com): " domain
    
    if [[ -z "$domain" ]]; then
        echo -e " ${RED}[!] Domain cannot be empty!${NC}"
        continue
    fi
    
    echo -e " ${BLUE}[...] Verifying IP pointing for $domain...${NC}"
    DOMAIN_IP=$(dig +short "$domain" | head -n 1)
    
    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        echo -e " ${GREEN}[OK] Verified! Domain points to this VPS.${NC}"
        echo "$domain" > /etc/xray/domain
        break
    else
        echo -e " ${RED}[!] Domain points to ${DOMAIN_IP:-'(not found)'} (Expected $MYIP)${NC}"
        read -p "      Continue anyway? [y/n]: " continue_anyway
        if [[ "$continue_anyway" == "y" || "$continue_anyway" == "Y" ]]; then
            echo "$domain" > /etc/xray/domain
            break
        fi
    fi
done

# --- B. NameServer (NS) ---
echo -e ""
echo -e " ${CYAN}>${NC} Enter NameServer for SlowDNS (e.g., ns.yourdomain.com)."
read -p "   Input NS Domain (or press ENTER to use default): " nsdomain
if [[ -z "$nsdomain" ]]; then
    echo "ns.$domain" > /etc/xray/nsdomain
    print_info "Using default NS: ns.$domain"
else
    echo "$nsdomain" > /etc/xray/nsdomain
    print_success "NS Domain Saved!"
fi

# ==========================================
# 4. SERVICE CONFIGURATION
# ==========================================
print_title "CONFIGURING SERVICES"

# --- Configure Dropbear & SSH ---
print_info "Configuring Dropbear & SSH..."
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

# Inject Custom SSH/Dropbear Banner
cat > /etc/issue.net << 'EOF'
<html><body><h3>Premium Server By @TheTechSavageTelegram</h3><b>Terms:</b> NO Multi-Login, NO DDoS, NO Torrenting. Violation = BAN.</body></html>
EOF

mkdir -p /etc/ssh/sshd_config.d
echo "Banner /etc/issue.net" > /etc/ssh/sshd_config.d/99-custom-banner.conf
sed -i 's/^Banner/#Banner/g' /etc/ssh/sshd_config 2>/dev/null
echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config.d/99-keepalive.conf
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config.d/99-keepalive.conf
systemctl restart ssh sshd 2>/dev/null
systemctl restart dropbear
print_success "Dropbear & SSH configured."

# --- Install Xray Core ---
print_info "Installing Xray Core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
print_success "Xray Core installed."

# --- Install SSL/TLS ---
print_info "Generating SSL Certificate..."
systemctl stop nginx
mkdir -p /root/.acme.sh
curl -s https://get.acme.sh | sh -s email=admin@$domain > /dev/null 2>&1
/root/.acme.sh/acme.sh --upgrade --auto-upgrade > /dev/null 2>&1
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt > /dev/null 2>&1
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force > /dev/null 2>&1
/root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc > /dev/null 2>&1
# Failsafe: Generate self-signed cert if Let's Encrypt fails
if [[ ! -s /etc/xray/xray.crt ]]; then
    print_info "Let's Encrypt failed. Generating Fallback SSL..."
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -subj "/CN=$domain" 2>/dev/null
fi
chmod 644 /etc/xray/xray.key /etc/xray/xray.crt
print_success "SSL Certificate Installed."

# --- Configure Stunnel4 ---
print_info "Configuring Stunnel4..."
cat /etc/xray/xray.key /etc/xray/xray.crt > /etc/stunnel/stunnel.pem
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
[dropbear_tls_1]
accept = 447
connect = 127.0.0.1:109
[dropbear_tls_2]
accept = 777
connect = 127.0.0.1:109
EOF
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl enable stunnel4 && systemctl restart stunnel4
print_success "Stunnel4 configured (Ports 447, 777)."

# --- Install BadVPN UDPGW ---
print_info "Installing UDPGW for gaming/VoIP (Port 7300)..."
git clone https://github.com/ambrop72/badvpn.git /tmp/badvpn > /dev/null 2>&1
(cd /tmp/badvpn && mkdir build && cd build && cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1 && make install > /dev/null 2>&1)
cat > /etc/systemd/system/udpgw.service <<EOF
[Unit]
Description=BadVPN UDPGW
[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable udpgw && systemctl start udpgw
rm -rf /tmp/badvpn
print_success "UDPGW installed."

# --- Configure Nginx ---
print_info "Configuring Nginx reverse proxy..."
fuser -k 80/tcp > /dev/null 2>&1 && fuser -k 443/tcp > /dev/null 2>&1
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/conf.d/vps.conf <<EOF
server {
    listen 81;
    listen 443 ssl;
    server_name $domain;
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / { proxy_pass http://127.0.0.1:80; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$http_host; }
    location /vless { proxy_pass http://127.0.0.1:10001; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$http_host; }
    location /vmess { proxy_pass http://127.0.0.1:10002; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$http_host; }
    location /trojan-ws { proxy_pass http://127.0.0.1:10003; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$http_host; }
}
EOF
print_success "Nginx configured."

# --- Install SlowDNS ---
print_info "Installing SlowDNS..."
mkdir -p /etc/slowdns
wget -q -O /etc/slowdns/dnstt-server "${REPO_URL}/core/dnstt-server"
chmod +x /etc/slowdns/dnstt-server
echo "a0946ee29693f2394e60b251b6c9e8d5b2f3bc8d753deebf8ce778773dbe10bc" > /etc/slowdns/server.key
echo "68a93ff4e08ea51657ede89c8dcc6534088d8461c1209743c11b96399beb1408" > /etc/slowdns/server.pub
chmod 600 /etc/slowdns/server.key
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
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable client-slow && systemctl start client-slow
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true
print_success "SlowDNS configured."

# --- Install OpenVPN ---
print_info "Installing OpenVPN..."
wget -q -O /tmp/openvpn.sh "${REPO_URL}/core/openvpn.sh"
chmod +x /tmp/openvpn.sh && /tmp/openvpn.sh > /dev/null 2>&1
rm -f /tmp/openvpn.sh
print_success "OpenVPN installed."

# --- Configure SOCKS5 (Dante) ---
print_info "Configuring SOCKS5 Proxy (Port 1080)..."
NIC=$(ip -o -4 route show to default | head -n1 | awk '{print $5}')
cat > /etc/danted.conf <<EOF
logoutput: syslog
user.privileged: root
user.unprivileged: nobody
internal: 0.0.0.0 port = 1080
external: $NIC
socksmethod: username
clientmethod: none
client pass { from: 0.0.0.0/0 to: 0.0.0.0/0; log: error }
socks pass { from: 0.0.0.0/0 to: 0.0.0.0/0; log: error }
EOF
systemctl enable danted && systemctl restart danted
print_success "SOCKS5 configured."

# ==========================================
# 5. DOWNLOAD MANAGEMENT SCRIPTS
# ==========================================
print_title "DOWNLOADING MANAGEMENT SCRIPTS"

# Function to download and set permissions for a script
download_bin() {
    local folder=$1
    local file=$2
    wget -q -O /usr/bin/$file "${REPO_URL}/$folder/$file"
    chmod +x /usr/bin/$file
}

# --- Download Core Configs & Python Proxies ---
wget -q -O /usr/local/etc/xray/config.json "${REPO_URL}/core/config.json"
wget -q -O /etc/systemd/system/xray.service "${REPO_URL}/core/xray.service"
wget -q -O /etc/xray/proxy.py "${REPO_URL}/core/proxy.py"
wget -q -O /etc/xray/proxy-8880.py "${REPO_URL}/core/proxy-8880.py"

# --- Create Python Proxy Services ---
print_info "Creating Python Websocket Proxy services..."
# Service for Port 80
cat > /etc/systemd/system/ws-proxy.service <<EOF
[Unit]
Description=Python Proxy SSH-WS
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/xray/proxy.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF
# Service for Port 8880
cat > /etc/systemd/system/ws-8880.service <<EOF
[Unit]
Description=Python Proxy SSH-WS (Port 8880)
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/xray/proxy-8880.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF
print_success "Proxy services created."

# --- Download Menu Scripts ---
print_info "Downloading menu scripts..."
menu_files=(menu menu-domain.sh menu-set.sh menu-ssh.sh menu-trojan.sh menu-vless.sh menu-vmess.sh running.sh)
for file in "${menu_files[@]}"; do
    download_bin "menu" "$file"
done

# --- Download SSH User Management Scripts ---
print_info "Downloading SSH user scripts..."
files_ssh=(usernew trial renew hapus member delete autokill cek tendang xp backup restore cleaner health-check show-conf ceklim speedtest api-ssh locker limit user-timed)
for file in "${files_ssh[@]}"; do
    download_bin "ssh" "$file"
done
mv /usr/bin/backup /usr/bin/backup.sh 2>/dev/null
mv /usr/bin/restore /usr/bin/restore.sh 2>/dev/null

# --- Download Xray User Management Scripts ---
print_info "Downloading Xray user scripts..."
files_xray=(add-ws del-ws renew-ws cek-ws trial-ws member-ws add-vless del-vless renew-vless cek-vless trial-vless member-vless add-tr del-tr renew-tr cek-tr trial-tr member-tr)
for file in "${files_xray[@]}"; do
    download_bin "xray" "$file"
done
print_success "All management scripts downloaded."

# ==========================================
# 6. FINALIZING SETUP
# ==========================================
print_title "FINALIZING SETUP"

# --- Configure Firewall ---
print_info "Configuring UFW Firewall..."
ufw allow 22/tcp > /dev/null
ufw allow 80/tcp > /dev/null
ufw allow 81/tcp > /dev/null
ufw allow 109/tcp > /dev/null
ufw allow 143/tcp > /dev/null
ufw allow 443/tcp > /dev/null
ufw allow 447/tcp > /dev/null
ufw allow 777/tcp > /dev/null
ufw allow 8880/tcp > /dev/null
echo "y" | ufw enable
print_success "Firewall is active."

# --- Start all services ---
print_info "Starting all services..."
systemctl daemon-reload
systemctl enable nginx xray dropbear stunnel4 ws-proxy ws-8880 client-slow &>/dev/null
systemctl restart nginx xray dropbear stunnel4 ws-proxy ws-8880 client-slow &>/dev/null

# --- Final Summary ---
clear
echo -e "${GREEN}================================================================${NC}"
echo -e "${YELLOW}           TheTechSavage Script Installation Complete!          ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e " VPS IP: ${CYAN}$MYIP${NC}"
echo -e " Domain: ${CYAN}$domain${NC}"
echo -e ""
echo -e " Type ${YELLOW}menu${NC} to access the management panel."
echo -e ""
echo -e " The server will now reboot to apply all settings."
echo -e " Please wait 1-2 minutes before logging back in."
echo -e "${GREEN}================================================================${NC}"

# Cleanup and Reboot
rm -f /root/install.sh
sleep 5
reboot