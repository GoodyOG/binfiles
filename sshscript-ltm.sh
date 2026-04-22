#!/bin/bash
# ═══════════════════════════════════════════════════════
#   SSHFREE LTM — VPN/SSH Services Manager
#   Original by DarkZFull • @DarkZFull
#   Modified and Translated Version
#   Ubuntu 22/24/25
# ═══════════════════════════════════════════════════════

SCRIPT_VERSION="3.1-Mod-EN"
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;96m'
W='\033[1;97m'
B='\033[0;34m'
P='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
NEON='\033[1;96m'
DIM='\033[2;37m'
LINE='◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆'
LINE2='◇─────────────────────────────────────────────◇'
DIR_SCRIPTS="/etc/sshfreeltm"
DIR_SERVICES="/etc/systemd/system"
mkdir -p $DIR_SCRIPTS

# Disable PAM password restrictions
sed -i 's/pam_unix.so obscure/pam_unix.so/' /etc/pam.d/common-password 2>/dev/null
sed -i 's/use_authtok //' /etc/pam.d/common-password 2>/dev/null
sed -i '/pam_pwquality/d' /etc/pam.d/common-password 2>/dev/null
sed -i '/pam_cracklib/d' /etc/pam.d/common-password 2>/dev/null

# Configure UFW if active
if command -v ufw > /dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw allow 8080/tcp > /dev/null 2>&1
    ufw allow 8388/tcp > /dev/null 2>&1
    ufw allow 8388/udp > /dev/null 2>&1
    ufw allow 7200/tcp > /dev/null 2>&1
    ufw allow 7300/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 36712/udp > /dev/null 2>&1
    ufw allow 90/tcp > /dev/null 2>&1
    ufw reload > /dev/null 2>&1
fi

# ══════════════════════════════════════════
# INITIAL DEPENDENCY INSTALLATION
# ══════════════════════════════════════════
if [ ! -f /etc/sshfreeltm/.installed ]; then
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    echo -e "  \033[1;97m⚡ First time run: Installing system dependencies...\033[0m"
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    echo -e "  \033[0;36m⏳ Updating repositories...\033[0m"
    DEBIAN_FRONTEND=noninteractive apt update -y -o Acquire::ForceIPv4=true > /dev/null 2>&1
    echo -e "  \033[1;32m✓ Repositories updated\033[0m"
    install_dep() {
        PKG=$1
        LABEL=${2:-$1}
        echo -ne "  \033[1;96m◈\033[0m \033[1;97m$LABEL\033[0m \033[0;36m...\033[0m"
        DEBIAN_FRONTEND=noninteractive apt install -y -qq $PKG > /dev/null 2>&1
        if dpkg -l $PKG 2>/dev/null | grep -q "^ii"; then
            echo -e "\r  \033[1;96m◈\033[0m \033[1;97m$LABEL\033[0m \033[1;32m✓ OK\033[0m          "
        else
            echo -e "\r  \033[1;96m◈\033[0m \033[1;97m$LABEL\033[0m \033[1;31m✗ Error\033[0m       "
        fi
    }
    install_dep curl "curl"
    install_dep wget "wget"
    install_dep figlet "figlet (ASCII art)"
    install_dep python3 "python3"
    install_dep sqlite3 "sqlite3"
    install_dep net-tools "net-tools"
    install_dep iptables "iptables"
    install_dep openssl "openssl"
    install_dep unzip "unzip"
    install_dep screen "screen"
    install_dep cmake "cmake"
    install_dep make "make"
    install_dep gcc "gcc"
    install_dep g++ "g++"
    install_dep git "git"
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    echo -e "  \033[1;32m✅ System ready\033[0m"
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    touch /etc/sshfreeltm/.installed
    sleep 2
fi


# Disable Ubuntu welcome messages
touch ~/.hushlogin 2>/dev/null
chmod -x /etc/update-motd.d/* 2>/dev/null
> /etc/motd 2>/dev/null

# Set permissions for letsencrypt certificates
if [ -d /etc/letsencrypt ]; then
    chmod 755 /etc/letsencrypt/live/ /etc/letsencrypt/archive/ 2>/dev/null
    find /etc/letsencrypt -name "*.pem" -exec chmod 644 {} \; 2>/dev/null
fi

# Ask for ASCII name on first install
if [ ! -f /etc/sshfreeltm/server_name ]; then
    mkdir -p /etc/sshfreeltm
    apt install -y figlet > /dev/null 2>&1
    echo ""
    echo -e "\033[1;33mEnter the name that will appear in the menu:\033[0m"
    read -p "Name: " INSTALL_NAME
    INSTALL_NAME=${INSTALL_NAME:-"SSHFREE LTM"}
    echo "$INSTALL_NAME" > /etc/sshfreeltm/server_name
    echo "$(date +%d-%m-%Y)" > /etc/sshfreeltm/install_date
fi

# Install MOTD automatically
cat > /etc/profile.d/sshfree-motd.sh << 'MOTDSCRIPT'
#!/bin/bash
PURPLE='\033[0;35m' CYAN='\033[0;36m' GREEN='\033[0;32m'
YELLOW='\033[1;33m' WHITE='\033[1;37m' NC='\033[0m'
INSTALL_DATE=$(cat /etc/sshfreeltm/install_date 2>/dev/null || echo "N/A")
SRV_NAME=$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
CURRENT_DATE=$(date +%d-%m-%Y)
CURRENT_TIME=$(date +%H:%M:%S)
UPTIME=$(uptime -p | sed 's/up //')
RAM_FREE=$(free -h | awk '/^Mem:/{print $4}')
echo -e "${PURPLE}"
figlet -f small "$SRV_NAME" 2>/dev/null || echo "  $SRV_NAME"
echo -e "${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}SERVER INSTALLED ON${NC}    : ${WHITE}$INSTALL_DATE${NC}"
echo -e "  ${YELLOW}CURRENT DATE/TIME${NC}      : ${WHITE}$CURRENT_DATE - $CURRENT_TIME${NC}"
echo -e "  ${YELLOW}SERVER NAME${NC}            : ${WHITE}$(hostname)${NC}"
echo -e "  ${YELLOW}UPTIME${NC}                 : ${WHITE}$UPTIME${NC}"
echo -e "  ${YELLOW}INSTALLED VERSION${NC}      : ${WHITE}V1.0.0${NC}"
echo -e "  ${YELLOW}FREE RAM${NC}               : ${WHITE}$RAM_FREE${NC}"
echo -e "  ${YELLOW}SCRIPT CREATOR${NC}         : ${PURPLE}@DarkZFull ❴LTM❵${NC}"
echo -e "  ${GREEN}WELCOME BACK!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Type ${YELLOW}menu${NC} to see the LTM MENU"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
MOTDSCRIPT
chmod +x /etc/profile.d/sshfree-motd.sh
[ -f /etc/motd ] && > /etc/motd

banner() {
    clear
    SRV_NAME=$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
    echo -e "${NEON}"
    figlet -f small "$SRV_NAME" 2>/dev/null || echo "  $SRV_NAME"
    echo -e "${NC}"
    echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
    echo -e "  ${W}⚡ VPN/SSH Manager${NC} ${DIM}by${NC} ${NEON}@DarkZFull${NC}  ${Y}❖ v${SCRIPT_VERSION}${NC}"
    echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
    echo ""
}

sep() { echo -e "${NEON}${LINE}${NC}"; }
sep2() { echo -e "${DIM}${LINE2}${NC}"; }

status_service() {
    systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${NEON}◆ ON ${NC}" || echo -e "${R}◇ OFF${NC}"
}

status_port() {
    ss -${2:-t}lnp 2>/dev/null | grep -q ":${1} " && echo -e "${NEON}◆ ON ${NC}" || echo -e "${R}◇ OFF${NC}"
}

# ══════════════════════════════════════════
#   WEBSOCKET PYTHON
# ══════════════════════════════════════════

instalar_ws() {
    banner; sep
    echo -e "  ${Y}Configure WebSocket Python${NC}"; sep; echo ""
    read -p "  WebSocket Port (e.g., 80): " WS_PORT; WS_PORT=${WS_PORT:-80}
    read -p "  Local SSH Port (e.g., 22): " SSH_PORT; SSH_PORT=${SSH_PORT:-22}
    echo ""; sep
    echo -e "  ${W}RESPONSE (101 for WebSocket, 200 default):${NC}"
    read -p "  RESPONSE: " STATUS_RESP; STATUS_RESP=${STATUS_RESP:-200}
    echo ""; read -p "  Mini-Banner: " BANNER_MSG
    BANNER_MSG=${BANNER_MSG:-"SSHFREE LTM by DarkZFull"}
    echo ""; sep
    echo -e "  ${W}Custom Header (ENTER for default):${NC}"
    read -p "  Header: " CUSTOM_HEADER
    [ -z "$CUSTOM_HEADER" ] && CUSTOM_HEADER="\r\nContent-length: 0\r\n\r\nHTTP/1.1 200 Connection Established\r\n\r\n"

    cat > $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py << PYEOF
#!/usr/bin/env python3
import socket, threading, select, sys, time
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = ${WS_PORT}
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = b'127.0.0.1:${SSH_PORT}'
MSG = '${BANNER_MSG}'.encode('utf-8')
STATUS_RESP = b'${STATUS_RESP}'
FTAG = b'${CUSTOM_HEADER}'
RESPONSE = b'HTTP/1.1 ' + STATUS_RESP + b' ' + MSG + b' ' + FTAG

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False; self.host = host; self.port = port
        self.threads = []; self.threadsLock = threading.Lock(); self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2); self.soc.bind((self.host, int(self.port))); self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try: c, addr = self.soc.accept(); c.setblocking(1)
                except socket.timeout: continue
                conn = ConnectionHandler(c, self, addr); conn.start(); self.addConn(conn)
        finally: self.running = False; self.soc.close()
    def printLog(self, log):
        self.logLock.acquire(); print(log); self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running: self.threads.append(conn)
        finally: self.threadsLock.release()
    def removeConn(self, conn):
        try: self.threadsLock.acquire(); self.threads.remove(conn)
        finally: self.threadsLock.release()
    def close(self):
        try:
            self.running = False; self.threadsLock.acquire()
            for c in list(self.threads): c.close()
        finally: self.threadsLock.release()

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False; self.targetClosed = True
        self.client = socClient; self.client_buffer = b''
        self.server = server; self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed: self.client.shutdown(socket.SHUT_RDWR); self.client.close()
        except: pass
        finally: self.clientClosed = True
        try:
            if not self.targetClosed: self.target.shutdown(socket.SHUT_RDWR); self.target.close()
        except: pass
        finally: self.targetClosed = True
    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, b'X-Real-Host')
            if hostPort == b'': hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, b'X-Split')
            if split != b'': self.client.recv(BUFLEN)
            if hostPort != b'':
                if hostPort.startswith(b'127.0.0.1') or hostPort.startswith(b'localhost'):
                    self.method_CONNECT(hostPort)
                else: self.client.send(b'HTTP/1.1 403 Forbidden!\r\n\r\n')
            else: self.client.send(b'HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + str(e); self.server.printLog(self.log)
        finally: self.close(); self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + b': ')
        if aux == -1: return b''
        aux = head.find(b':', aux); head = head[aux + 2:]
        aux = head.find(b'\r\n')
        if aux == -1: return b''
        return head[:aux]
    def connect_target(self, host):
        i = host.find(b':')
        if i != -1: port = int(host[i + 1:]); host = host[:i]
        else: port = ${SSH_PORT}
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False; self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path.decode()
        self.connect_target(path); self.client.sendall(RESPONSE)
        self.client_buffer = b''; self.server.printLog(self.log); self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]; count = 0; error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err: error = True
            if recv:
                for in_ in recv:
                    try:
                        data = in_.recv(BUFLEN)
                        if data:
                            if in_ is self.target: self.client.send(data)
                            else:
                                while data: byte = self.target.send(data); data = data[byte:]
                            count = 0
                        else: break
                    except: error = True; break
            if count == TIMEOUT: error = True
            if error: break

if __name__ == '__main__':
    print(f"\033[0;34m{'*'*8} \033[1;32mPYTHON3 WEBSOCKET PROXY \033[0;34m{'*'*8}\n")
    print(f"\033[1;33mPORT:\033[1;32m {LISTENING_PORT}\n")
    server = Server(LISTENING_ADDR, LISTENING_PORT); server.start()
    while True:
        try: time.sleep(2)
        except KeyboardInterrupt: server.close(); break
PYEOF

    chmod +x $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py
    cat > $DIR_SERVICES/ws-proxy-${WS_PORT}.service << EOF
[Unit]
Description=WebSocket Python Proxy Port ${WS_PORT}
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 ${DIR_SCRIPTS}/proxy_ws_${WS_PORT}.py ${WS_PORT}
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable ws-proxy-${WS_PORT}; systemctl start ws-proxy-${WS_PORT}
    sleep 2
    systemctl is-active --quiet ws-proxy-${WS_PORT} && echo -e "\n  ${G}OK WebSocket active on port ${WS_PORT}${NC}" || echo -e "\n  ${R}Error${NC}"
    read -p "  Press ENTER to continue..."
}

menu_ws() {
    while true; do
        banner; sep; echo -e "  ${Y}  WEBSOCKET PYTHON${NC}"; sep; echo ""
        for f in $(ls $DIR_SERVICES/ws-proxy-*.service 2>/dev/null); do
            name=$(basename $f .service); port=$(echo $name | grep -o '[0-9]*$')
            echo -e "  Port ${Y}${port}${NC} $(status_service $name)"
        done
        echo ""; sep
        echo -e "  ${W}[1]${NC} Install/Configure"
        echo -e "  ${W}[2]${NC} Start"
        echo -e "  ${W}[3]${NC} Stop"
        echo -e "  ${W}[4]${NC} Restart"
        echo -e "  ${W}[5]${NC} Remove"
        echo -e "  ${W}[0]${NC} Back"; sep
        read -p "  Option: " OPT
        case $OPT in
            1) instalar_ws ;;
            2) read -p "  Port: " P; systemctl start ws-proxy-${P} && echo -e "  ${G}Started${NC}"; sleep 1 ;;
            3) read -p "  Port: " P; systemctl stop ws-proxy-${P} && echo -e "  ${Y}Stopped${NC}"; sleep 1 ;;
            4) read -p "  Port: " P; systemctl restart ws-proxy-${P} && echo -e "  ${G}Restarted${NC}"; sleep 1 ;;
            5)
                read -p "  Port (0=all): " DEL_PORT
                if [ "$DEL_PORT" = "0" ]; then
                    for f in $DIR_SERVICES/ws-proxy-*.service; do
                        name=$(basename $f .service); systemctl stop $name; systemctl disable $name; rm -f $f
                    done; rm -f $DIR_SCRIPTS/proxy_ws_*.py
                else
                    systemctl stop ws-proxy-${DEL_PORT}; systemctl disable ws-proxy-${DEL_PORT}
                    rm -f $DIR_SERVICES/ws-proxy-${DEL_PORT}.service $DIR_SCRIPTS/proxy_ws_${DEL_PORT}.py
                fi
                systemctl daemon-reload; echo -e "  ${G}Removed${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   BADVPN
# ══════════════════════════════════════════

menu_badvpn() {
    while true; do
        banner; sep; echo -e "  ${Y}  BADVPN UDP GATEWAY${NC}"; sep; echo ""
        echo -e "  BadVPN 7200 $(status_service badvpn-7200)"
        echo -e "  BadVPN 7300 $(status_service badvpn-7300)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Install BadVPN"
        echo -e "  ${W}[2]${NC} Start"
        echo -e "  ${W}[3]${NC} Stop"
        echo -e "  ${W}[4]${NC} Restart"
        echo -e "  ${W}[5]${NC} Custom Port"
        echo -e "  ${W}[0]${NC} Back"; sep
        read -p "  Option: " OPT
        case $OPT in
            1)
                if [ ! -f /usr/local/bin/badvpn-udpgw ] || [ ! -s /usr/local/bin/badvpn-udpgw ]; then
                    rm -f /usr/local/bin/badvpn-udpgw
                    echo -e "\n  ${C}Updating repositories...${NC}"
                    apt update -y > /dev/null 2>&1
                    echo -e "  ${C}Installing dependencies...${NC}"
                    apt install -y cmake make gcc g++ git > /dev/null 2>&1
                    echo -e "  ${C}Compiling BadVPN...${NC}"
                    cd /tmp || cd /root
                    rm -rf badvpn
                    git clone https://github.com/ambrop72/badvpn.git > /dev/null 2>&1
                    cd /tmp/badvpn && mkdir -p build && cd build
                    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
                    make > /dev/null 2>&1
                    cd /tmp
                    if [ -f /tmp/badvpn/build/udpgw/badvpn-udpgw ] && [ -s /tmp/badvpn/build/udpgw/badvpn-udpgw ]; then
                        cp /tmp/badvpn/build/udpgw/badvpn-udpgw /usr/local/bin/
                        chmod +x /usr/local/bin/badvpn-udpgw
                        echo -e "  ${G}OK Binary compiled${NC}"
                    else
                        echo -e "  ${R}Error: compilation failed${NC}"
                        read -p "  Press ENTER to continue..."; return
                    fi
                fi
                for PORT in 7200 7300; do
                    cat > $DIR_SERVICES/badvpn-${PORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway ${PORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${PORT} --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                    systemctl daemon-reload; systemctl enable badvpn-${PORT}; systemctl start badvpn-${PORT}
                done
                echo -e "  ${G}OK BadVPN 7200 and 7300 installed${NC}"; sleep 2 ;;
            2) systemctl start badvpn-7200 badvpn-7300 && echo -e "  ${G}Started${NC}"; sleep 1 ;;
            3) systemctl stop badvpn-7200 badvpn-7300 && echo -e "  ${Y}Stopped${NC}"; sleep 1 ;;
            4) systemctl restart badvpn-7200 badvpn-7300 && echo -e "  ${G}Restarted${NC}"; sleep 1 ;;
            5)
                read -p "  Port: " BPORT
                cat > $DIR_SERVICES/badvpn-${BPORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway ${BPORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${BPORT} --max-clients 500
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload; systemctl enable badvpn-${BPORT}; systemctl start badvpn-${BPORT}
                echo -e "  ${G}OK BadVPN on port ${BPORT}${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   UDP CUSTOM
# ══════════════════════════════════════════

menu_udp() {
    while true; do
        banner; sep; echo -e "  ${Y}  UDP CUSTOM${NC}"; sep; echo ""
        ps aux | grep -i "udp-custom\|UDP-Custom" | grep -v grep | grep -q . && echo -e "  UDP Custom ${G}[ON]${NC}" || echo -e "  UDP Custom ${R}[OFF]${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Install UDP Custom"
        echo -e "  ${W}[2]${NC} Start"
        echo -e "  ${W}[3]${NC} Stop"
        echo -e "  ${W}[4]${NC} Restart"
        echo -e "  ${W}[5]${NC} View Status"
        echo -e "  ${W}[0]${NC} Back"; sep
        read -p "  Option: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Installing UDP Custom (Epro Dev Team)...${NC}"
                read -p "  Port to exclude (default 5300): " UDP_EXCL; UDP_EXCL=${UDP_EXCL:-5300}
                wget -O /tmp/install-udp "https://drive.usercontent.google.com/download?id=1S3IE25v_fyUfCLslnujFBSBMNunDHDk2&export=download&confirm=t"
                chmod +x /tmp/install-udp; bash /tmp/install-udp $UDP_EXCL
                echo -e "  ${G}OK UDP Custom installed${NC}"; sleep 2 ;;
            2) systemctl start udp-custom 2>/dev/null || (/root/udp/udp-custom server -exclude 5300 &); echo -e "  ${G}Started${NC}"; sleep 1 ;;
            3) systemctl stop udp-custom 2>/dev/null; pkill -f udp-custom 2>/dev/null; echo -e "  ${Y}Stopped${NC}"; sleep 1 ;;
            4) pkill -f udp-custom 2>/dev/null; sleep 1; systemctl start udp-custom 2>/dev/null || (/root/udp/udp-custom server -exclude 5300 &); echo -e "  ${G}Restarted${NC}"; sleep 1 ;;
            5) ss -ulnp | grep udp; echo ""; read -p "  Press ENTER to continue..." ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   SSL/TLS STUNNEL
# ══════════════════════════════════════════

menu_ssl() {
    while true; do
        banner; sep; echo -e "  ${Y}  SSL/TLS STUNNEL${NC}"; sep; echo ""
        echo -e "  Stunnel $(status_service stunnel4)"
        echo -e "  Port 443 $(status_port 443)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Install SSL/TLS Stunnel"
        echo -e "  ${W}[2]${NC} Start"
        echo -e "  ${W}[3]${NC} Stop"
        echo -e "  ${W}[4]${NC} Restart"
        echo -e "  ${W}[0]${NC} Back"; sep
        read -p "  Option: " OPT
        case $OPT in
            1)
                apt install -y stunnel4 > /dev/null 2>&1
                read -p "  SSL Port (e.g., 443): " SSL_PORT; SSL_PORT=${SSL_PORT:-443}
                read -p "  Local SSH Port (e.g., 22): " LOCAL_PORT; LOCAL_PORT=${LOCAL_PORT:-22}
                openssl req -new -x509 -days 3650 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem -subj "/C=US/ST=Miami/L=Miami/O=SSHFREE/CN=sshfree" 2>/dev/null
                cat > /etc/stunnel/stunnel.conf << EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
socket = a:SO_REUSEADDR=1
[ssh]
accept = ${SSL_PORT}
connect = 127.0.0.1:${LOCAL_PORT}
EOF
                sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
                systemctl enable stunnel4; systemctl start stunnel4
                echo -e "  ${G}OK SSL/TLS on port ${SSL_PORT}${NC}"; sleep 2 ;;
            2) systemctl start stunnel4 && echo -e "  ${G}Started${NC}"; sleep 1 ;;
            3) systemctl stop stunnel4 && echo -e "  ${Y}Stopped${NC}"; sleep 1 ;;
            4) systemctl restart stunnel4 && echo -e "  ${G}Restarted${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   V2RAY
# ══════════════════════════════════════════

menu_v2ray() {
    while true; do
        banner; sep
        echo -e "  ${NEON}◆ V2RAY VMESS${NC}"; sep; echo ""
        echo -e "  V2Ray $(status_service v2ray)"
        if [ -f /usr/local/etc/v2ray/config.json ]; then
            python3 -c "
import json
try:
    with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
    inbounds = c.get('inbounds',[])
    if not inbounds:
        print('  \033[2;37m  No inbounds configured\033[0m')
    for ib in inbounds:
        net=ib.get('streamSettings',{}).get('network','tcp')
        tls=ib.get('streamSettings',{}).get('security','none')
        tls_icon='\033[1;96m TLS\033[0m' if tls=='tls' else ''
        print(f'  \033[1;96m◈\033[0m \033[1;97mPort \033[1;33m{ib[\"port\"]}\033[0m \033[2;37m|\033[0m \033[1;96m{ib[\"protocol\"]}\033[0m \033[2;37m|\033[0m {net}{tls_icon}')
except: pass
" 2>/dev/null
        fi
        echo ""; sep
        printf " ${Y}❬1❭ ⚡ Install V2Ray       ❬2❭ ➕ Add Inbound${NC}\n"
        printf " ${Y}❬3❭ 🗑  Remove Inbound    ❬4❭ ▶  Start${NC}\n"
        printf " ${Y}❬5❭ ⏹  Stop              ❬6❭ 🔄 Restart${NC}\n"
        printf " ${Y}❬7❭ 👤 Create User         ❬8❭ 📋 View Users${NC}\n"
        printf " ${R}❬9❭ 🗑  Uninstall V2Ray${NC}\n"
        sep
        printf " ${R}❬0❭ Back${NC}\n"; sep; echo ""
        read -p " Option: " OPT
        case $OPT in
            1)
                read -p "  Domain (for SSL): " DOMAIN
                EMAIL="admin@${DOMAIN#*.}"
                echo -e "  ${C}Installing V2Ray...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) > /dev/null 2>&1
                echo -e "  ${C}Getting SSL certificate...${NC}"
                apt install -y certbot > /dev/null 2>&1
                pkill -f "python3.*:80" 2>/dev/null; sleep 1
                certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos -m $EMAIL
                chmod 755 /etc/letsencrypt/live/ /etc/letsencrypt/archive/ 2>/dev/null
                chmod 644 /etc/letsencrypt/live/$DOMAIN/*.pem 2>/dev/null
                chmod 644 /etc/letsencrypt/archive/$DOMAIN/*.pem 2>/dev/null
                cat > /usr/local/etc/v2ray/config.json << EOF
{"log":{"loglevel":"warning"},"inbounds":[],"outbounds":[{"protocol":"freedom"}]}
EOF
                mkdir -p /etc/sshfreeltm
                echo "$DOMAIN" > /etc/sshfreeltm/v2ray_domain
                systemctl enable v2ray; systemctl start v2ray
                echo -e "  ${G}OK V2Ray installed — Use ❬2❭ to add ports${NC}"; sleep 2 ;;
            2)
                banner; sep
                echo -e "  ${Y}  ADD INBOUND${NC}"; sep; echo ""
                read -p "  Port: " V2_PORT
                echo -e "  Protocol: ${Y}❬1❭${NC} vmess ${Y}❬2❭${NC} vless ${Y}❬3❭${NC} trojan"
                read -p "  Option: " V2_PROTO_OPT
                case $V2_PROTO_OPT in
                    1) V2_PROTO="vmess" ;; 2) V2_PROTO="vless" ;; 3) V2_PROTO="trojan" ;; *) V2_PROTO="vmess" ;;
                esac
                echo -e "  Network: ${Y}❬1❭${NC} ws ${Y}❬2❭${NC} tcp ${Y}❬3❭${NC} xhttp ${Y}❬4❭${NC} grpc"
                read -p "  Option: " V2_NET_OPT
                case $V2_NET_OPT in
                    1) V2_NET="ws" ;; 2) V2_NET="tcp" ;; 3) V2_NET="xhttp" ;; 4) V2_NET="grpc" ;; *) V2_NET="ws" ;;
                esac
                read -p "  Path (e.g., /v2ray): " V2_PATH; V2_PATH=${V2_PATH:-/v2ray}
                echo -e "  TLS: ${Y}❬1❭${NC} Yes ${Y}❬2❭${NC} No"
                read -p "  Option: " V2_TLS_OPT
                [ "$V2_TLS_OPT" = "1" ] && V2_TLS="tls" || V2_TLS="none"
                python3 - << PYEOF
import json, os
port, proto, net, path, tls = int("$V2_PORT"), "$V2_PROTO", "$V2_NET", "$V2_PATH", "$V2_TLS"
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
ib = {"port": port, "protocol": proto, "settings": {"clients": []}, "streamSettings": {"network": net, "security": tls}}
if net == "ws": ib["streamSettings"]["wsSettings"] = {"path": path}
elif net == "xhttp": ib["streamSettings"]["xhttpSettings"] = {"path": path}
elif net == "grpc": ib["streamSettings"]["grpcSettings"] = {"serviceName": path.strip("/")}
if tls == "tls":
    domain = open('/etc/sshfreeltm/v2ray_domain').read().strip() if os.path.exists('/etc/sshfreeltm/v2ray_domain') else ''
    ib["streamSettings"]["tlsSettings"] = {"certificates": [{"certificateFile": f"/etc/letsencrypt/live/{domain}/fullchain.pem","keyFile": f"/etc/letsencrypt/live/{domain}/privkey.pem"}]}
config["inbounds"].append(ib)
with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
print(f"OK {proto} {net} port {port}")
PYEOF
                systemctl restart v2ray; echo -e "  ${G}OK Inbound added${NC}"; read -p "  Press ENTER to continue..." ;;
            3)
                banner; sep; echo -e "  ${R}  REMOVE INBOUND${NC}"; sep; echo ""
                python3 -c "
import json
with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
for i,ib in enumerate(c.get('inbounds',[])):
    print(f'  [{i+1}] Port {ib[\"port\"]} | {ib[\"protocol\"]}')
" 2>/dev/null
                echo ""; read -p "  Number to remove: " DEL_NUM
                python3 - << PYEOF
import json
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
idx = int("$DEL_NUM") - 1
if 0 <= idx < len(config['inbounds']):
    removed = config['inbounds'].pop(idx)
    with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
    print(f"OK Port {removed['port']} removed")
else: print("Invalid number")
PYEOF
                systemctl restart v2ray; sleep 1 ;;
            4) systemctl start v2ray && echo -e "  ${G}Started${NC}"; sleep 1 ;;
            5) systemctl stop v2ray && echo -e "  ${Y}Stopped${NC}"; sleep 1 ;;
            6) systemctl restart v2ray && echo -e "  ${G}Restarted${NC}"; sleep 1 ;;
            7)
                banner; sep; echo -e "  ${Y}  CREATE VMESS USER${NC}"; sep; echo ""
                python3 -c "
import json
with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
for i,ib in enumerate(c.get('inbounds',[])):
    net=ib.get('streamSettings',{}).get('network','tcp')
    tls=ib.get('streamSettings',{}).get('security','none')
    print(f'  [{i+1}] Port {ib[\"port\"]} | {ib[\"protocol\"]} | {net} | tls:{tls}')
" 2>/dev/null
                echo ""; read -p "  Inbound number: " IB_NUM
                IB_IDX=$((IB_NUM - 1))
                read -p "  Profile name: " VNAME
                read -p "  Validity days (default 30): " V2_DAYS; V2_DAYS=${V2_DAYS:-30}
                EXP_SHOW=$(date -d "+${V2_DAYS} days" +%d/%m/%Y)
                VDOMAIN=$(cat /etc/sshfreeltm/v2ray_domain 2>/dev/null || hostname -I | awk '{print $1}')
                python3 - << PYEOF
import json, uuid, base64, datetime
idx, name, days, domain = int("$IB_IDX"), "$VNAME", int("$V2_DAYS"), "$VDOMAIN"
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
inbounds = config.get('inbounds', [])
if idx >= len(inbounds): print("Inbound not found"); exit(1)
ib = inbounds[idx]
uid = str(uuid.uuid4())
exp = (datetime.datetime.now() + datetime.timedelta(days=days)).strftime("%Y-%m-%d")
if 'clients' not in ib['settings']: ib['settings']['clients'] = []
ib['settings']['clients'].append({"id": uid, "alterId": 0, "email": name, "expires": exp})
with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
net = ib.get('streamSettings', {}).get('network', 'tcp')
tls = ib.get('streamSettings', {}).get('security', 'none')
path = ib.get('streamSettings', {}).get('wsSettings', {}).get('path', '/v2ray') if net == 'ws' else ''
out_port = "443" if ib['port'] == 8080 else str(ib['port'])
out_tls = "tls" if ib['port'] == 8080 else (tls if tls != "none" else "")
vmess = {"v":"2","ps":name,"add":domain,"port":out_port,"id":uid,"aid":"0","net":net,"type":"none","host":domain,"path":path,"tls":out_tls}
link = "vmess://" + base64.b64encode(json.dumps(vmess).encode()).decode()
print("")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
print("  \033[1;32m✅ VMESS ACCOUNT CREATED\033[0m")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mProfile:\033[0m  \033[1;97m{name}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mHost   :\033[0m  \033[1;97m{domain}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mPort   :\033[0m  \033[1;33m{out_port}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mNetwork:\033[0m  \033[1;96m{net}\033[0m")
print(f"  \033[1;96m◈\033[0m \033[2;37mExpires:\033[0m  \033[1;33m$EXP_SHOW\033[0m")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
print("  \033[1;96m🔑 VMESS LINK:\033[0m")
print("")
print("\033[1;97m" + link + "\033[0m")
print("")
print("\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m")
PYEOF
                systemctl restart v2ray; read -p "  Press ENTER to continue..." ;;
            8)
                python3 -c "
import json
try:
    with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
    for ib in c['inbounds']:
        print(f'  Port {ib[\"port\"]}:')
        for u in ib['settings'].get('clients',[]):
            print(f'    - {u.get(\"email\",\"?\")} | expires: {u.get(\"expires\",\"n/a\")}')
except Exception as e: print(f'Error: {e}')
"; read -p "  Press ENTER to continue..." ;;
            9)
                read -p "  Confirm V2Ray uninstall (yes/no): " CONFIRM
                if [ "$CONFIRM" = "yes" ]; then
                    systemctl stop v2ray; systemctl disable v2ray
                    bash <(curl -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --remove > /dev/null 2>&1
                    rm -f /etc/sshfreeltm/v2ray_domain
                    echo -e "  ${G}OK V2Ray uninstalled${NC}"; sleep 2
                fi ;;
            0) break ;;
            *) echo -e "  ${R}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# ══════════════════════════════════════════
#   SSH USERS
# ══════════════════════════════════════════

listar_usuarios() {
    banner; sep; echo -e "  ${Y}  ACTIVE SSH USERS${NC}"; sep; echo ""
    printf "  %-20s %-15s %s\n" "User" "Expires" "Status"
    sep
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do
        EXP=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        if [ "$EXP" = "never" ] || [ -z "$EXP" ]; then
            printf "  ${Y}%-20s${NC} %-15s\n" "$user" "No expiration"
        else
            EXP_TS=$(date -d "$EXP" +%s 2>/dev/null || echo 0)
            NOW_TS=$(date +%s)
            if [ $EXP_TS -lt $NOW_TS ]; then
                printf "  ${R}%-20s${NC} %-15s ${R}[EXPIRED]${NC}\n" "$user" "$EXP"
            else
                printf "  ${G}%-20s${NC} %-15s\n" "$user" "$EXP"
            fi
        fi
    done
    echo ""; sep; read -p "  Press ENTER to continue..."
}

crear_usuario() {
    banner; sep; echo -e "  ${Y}  CREATE SSH USER${NC}"; sep; echo ""
    read -p "  Username: " USR_NAME
    [ -z "$USR_NAME" ] && echo -e "  ${R}Username is required${NC}" && sleep 1 && return
    read -p "  Password (ENTER to generate): " USR_PASS
    [ -z "$USR_PASS" ] && USR_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1) && echo -e "  ${G}Generated: ${W}${USR_PASS}${NC}"
    read -p "  Validity days (default 30): " USR_DAYS; USR_DAYS=${USR_DAYS:-30}
    EXP_DATE=$(date -d "+${USR_DAYS} days" +%Y-%m-%d)
    EXP_SHOW=$(date -d "+${USR_DAYS} days" +%d/%m/%Y)
    SERVER_IP=$(curl -s -4 ifconfig.me 2>/dev/null || ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
    echo ""; echo -e "  ${C}Creating user...${NC}"
    if id "$USR_NAME" &>/dev/null; then
        usermod -e $EXP_DATE $USR_NAME; echo "$USR_NAME:$USR_PASS" | chpasswd
    else
        useradd -M -s /bin/false -e $EXP_DATE $USR_NAME
        echo "$USR_NAME:$USR_PASS" | chpasswd
        chage -E $EXP_DATE -M 99999 $USR_NAME; usermod -f 0 $USR_NAME
    fi
    echo ""; sep; echo -e "  ${Y}  CREDENTIALS${NC}"; sep
    echo -e "  ${W}User:${NC}      $USR_NAME"
    echo -e "  ${W}Password:${NC}  $USR_PASS"
    echo -e "  ${W}IP:${NC}        $SERVER_IP"
    echo -e "  ${W}Expires:${NC}   $EXP_SHOW ($USR_DAYS days)"
    echo ""; sep; echo -e "  ${Y}  AVAILABLE CONNECTIONS${NC}"; sep; echo ""
    echo -e "  ${C}Direct SSH:${NC}"; echo -e "  ${W}$SERVER_IP:22@$USR_NAME:$USR_PASS${NC}"; echo ""
    ss -tlnp | grep -q ":80 " && echo -e "  ${C}WS Port 80:${NC}" && echo -e "  ${W}$SERVER_IP:80@$USR_NAME:$USR_PASS${NC}" && echo ""
    systemctl is-active --quiet stunnel4 2>/dev/null && echo -e "  ${C}SSL/TLS 443:${NC}" && echo -e "  ${W}$SERVER_IP:443@$USR_NAME:$USR_PASS${NC}" && echo ""
    ps aux | grep -i "udp-custom\|UDP-Custom" | grep -v grep | grep -q . && echo -e "  ${C}UDP Custom:${NC}" && echo -e "  ${W}$SERVER_IP:1-65535@$USR_NAME:$USR_PASS${NC}" && echo ""
    (systemctl is-active --quiet badvpn-7200 2>/dev/null || systemctl is-active --quiet badvpn-7300 2>/dev/null) && echo -e "  ${C}BadVPN:${NC}" && systemctl is-active --quiet badvpn-7200 && echo -e "  ${W}Port 7200 active${NC}" && systemctl is-active --quiet badvpn-7300 && echo -e "  ${W}Port 7300 active${NC}" && echo ""
    sep; read -p "  Press ENTER to continue..."
}

eliminar_usuario() {
    banner; sep; echo -e "  ${R}  REMOVE SSH USER${NC}"; sep; echo ""
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do printf "  ${Y}%-20s${NC}\n" "$user"; done
    echo ""; read -p "  User to remove: " DEL_USR
    if id "$DEL_USR" &>/dev/null; then
        pkill -u "$DEL_USR" 2>/dev/null; userdel -f "$DEL_USR" 2>/dev/null
        echo -e "  ${G}OK User $DEL_USR removed${NC}"
    else echo -e "  ${R}User not found${NC}"; fi
    sleep 2
}

renovar_usuario() {
    banner; sep; echo -e "  ${Y}  RENEW SSH USER${NC}"; sep; echo ""
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do
        EXP=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        printf "  ${Y}%-20s${NC} %s\n" "$user" "$EXP"
    done
    echo ""; read -p "  User to renew: " REN_USR
    id "$REN_USR" &>/dev/null || { echo -e "  ${R}Not found${NC}"; sleep 1; return; }
    read -p "  Days to add (default 30): " REN_DAYS; REN_DAYS=${REN_DAYS:-30}
    EXP_DATE=$(date -d "+${REN_DAYS} days" +%Y-%m-%d)
    EXP_SHOW=$(date -d "+${REN_DAYS} days" +%d/%m/%Y)
    usermod -e $EXP_DATE $REN_USR; chage -E $EXP_DATE $REN_USR
    echo -e "  ${G}OK $REN_USR renewed until $EXP_SHOW${NC}"; sleep 2
}

menu_usuarios() {
    while true; do
        banner; sep; echo -e "  ${Y}  SSH USER MANAGEMENT${NC}"; sep; echo ""
        TOTAL=$(awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | wc -l)
        echo -e "  Total users: ${G}${TOTAL}${NC}"; echo ""; sep
        echo -e "  ${W}[1]${NC} Create User"
        echo -e "  ${W}[2]${NC} List Users"
        echo -e "  ${W}[3]${NC} Remove User"
        echo -e "  ${W}[4]${NC} Renew User"
        echo -e "  ${W}[0]${NC} Back"; sep
        read -p "  Option: " OPT
        case $OPT in
            1) crear_usuario ;;
            2) listar_usuarios ;;
            3) eliminar_usuario ;;
            4) renovar_usuario ;;
            0) break ;;
        esac
    done
}


instalar_motd() {
    banner; sep
    echo -e "  ${Y}  CONFIGURE SERVER MOTD${NC}"; sep; echo ""
    read -p "  Server name: " SRV_NAME
    [ -z "$SRV_NAME" ] && SRV_NAME="SSHFREE LTM"

    # Install figlet for ASCII art
    apt install -y figlet > /dev/null 2>&1

    INSTALL_DATE=$(date +%d-%m-%Y)

    # Save installation date
    echo "$INSTALL_DATE" > /etc/sshfreeltm/install_date
    echo "$SRV_NAME" > /etc/sshfreeltm/server_name

    # Test figlet
    echo -e "  ${C}Name preview:${NC}"
    figlet -f slant "$SRV_NAME" 2>/dev/null || figlet "$SRV_NAME" 2>/dev/null || echo "$SRV_NAME"
    
    # Create dynamic MOTD script
    cat > /etc/profile.d/sshfree-motd.sh << MOTDEOF
#!/bin/bash
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

INSTALL_DATE=\$(cat /etc/sshfreeltm/install_date 2>/dev/null || echo "N/A")
SRV_NAME=\$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
CURRENT_DATE=\$(date +%d-%m-%Y)
CURRENT_TIME=\$(date +%H:%M:%S)
UPTIME=\$(uptime -p | sed 's/up //')
RAM_FREE=\$(free -h | awk '/^Mem:/{print \$4}')
HOSTNAME=\$(hostname)

echo -e "\${PURPLE}"
figlet -f slant "\$SRV_NAME" 2>/dev/null || echo "\$SRV_NAME"
echo -e "\${NC}"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo -e "  \${YELLOW}SERVER INSTALLED ON\${NC}    : \${WHITE}\$INSTALL_DATE\${NC}"
echo -e "  \${YELLOW}CURRENT DATE/TIME\${NC}      : \${WHITE}\$CURRENT_DATE - \$CURRENT_TIME\${NC}"
echo -e "  \${YELLOW}SERVER NAME\${NC}            : \${WHITE}\$HOSTNAME\${NC}"
echo -e "  \${YELLOW}UPTIME\${NC}                 : \${WHITE}\$UPTIME\${NC}"
echo -e "  \${YELLOW}INSTALLED VERSION\${NC}      : \${WHITE}V1.0.0\${NC}"
echo -e "  \${YELLOW}FREE RAM\${NC}               : \${WHITE}\$RAM_FREE\${NC}"
echo -e "  \${YELLOW}SCRIPT CREATOR\${NC}         : \${PURPLE}@DarkZFull ❴LTM❵\${NC}"
echo -e "  \${GREEN}WELCOME BACK!\${NC}"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo -e "  Type \${YELLOW}menu\${NC} to see the LTM MENU"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo ""
MOTDEOF

    chmod +x /etc/profile.d/sshfree-motd.sh
    
    # Disable default Ubuntu MOTD
    [ -f /etc/motd ] && > /etc/motd
    
    echo -e "
  ${G}OK MOTD configured for ${SRV_NAME}${NC}"
    echo -e "  ${Y}It will be displayed upon SSH connection${NC}"
    sleep 2
}

# ══════════════════════════════════════════
#   MAIN MENU
# ══════════════════════════════════════════

desinstalar_script() {
    banner; sep
    echo -e "  ${R}  UNINSTALL SCRIPT${NC}"; sep; echo ""
    echo -e "  ${Y}This will remove:${NC}"
    echo -e "  - The 'menu' command"
    echo -e "  - Server MOTD"
    echo -e "  - Configuration files"
    echo -e "  - Installed services (WS, BadVPN, etc.)"
    echo ""
    read -p "  Confirm (yes/no): " CONFIRM
    [ "$CONFIRM" != "yes" ] && echo -e "  ${Y}Cancelled${NC}" && sleep 1 && return

    echo -e "\n  ${C}Uninstalling...${NC}"
    # Stop and remove services
    for svc in ws-proxy-* badvpn-* udp-custom stunnel4 v2ray hysteria-server; do
        systemctl stop $svc 2>/dev/null
        systemctl disable $svc 2>/dev/null
        rm -f /etc/systemd/system/$svc.service
    done
    systemctl daemon-reload

    # Remove files
    rm -f /usr/local/bin/menu
    rm -f /etc/profile.d/sshfree-motd.sh
    rm -rf /etc/sshfreeltm
    rm -rf $DIR_SCRIPTS

    echo -e "  ${G}Script uninstalled successfully${NC}"
    sleep 2
    exit 0
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  UPDATE SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Downloading latest version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/DarkFull0726/SSHSCRIPT-LTM/main/sshscript-ltm.sh?$(date +%s)"
    chmod +x /usr/local/bin/menu
    mkdir -p /etc/sshfreeltm
    touch /etc/sshfreeltm/.installed
    echo -e "  ${G}OK Script updated to v$(grep SCRIPT_VERSION /usr/local/bin/menu | head -1 | grep -o '[0-9.]*')${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_principal() {
    while true; do
        banner
        SRV_IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
        SRV_OS=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Ubuntu")
        SRV_CPU=$(nproc)
        SRV_DATE=$(date +%d/%m/%Y-%H:%M)
        SRV_RAM=$(free -h | awk '/^Mem:/{print $4}')
        SRV_UPTIME=$(uptime -p | sed 's/up //')
        sep
        printf " ${NEON}◈${NC} ${DIM}OS:${NC}  ${W}%-20s${NC} ${NEON}◈${NC} ${DIM}IP:${NC}  ${NEON}%s${NC}\n" "$SRV_OS" "$SRV_IP"
        printf " ${NEON}◈${NC} ${DIM}CPU:${NC} ${W}%-19s${NC} ${NEON}◈${NC} ${DIM}Date:${NC} ${Y}%s${NC}\n" "$SRV_CPU cores" "$SRV_DATE"
        printf " ${NEON}◈${NC} ${DIM}RAM:${NC} ${W}%-19s${NC} ${NEON}◈${NC} ${DIM}Uptime:${NC} ${W}%s${NC}\n" "$SRV_RAM" "$SRV_UPTIME"
        sep
        
        # Service Status Display
        C1="" C2=""
        check_and_display() {
            local label="$1"
            local status_msg="$2"
            if [ -z "$C1" ]; then C1="$status_msg"; else
                if [ -z "$C2" ]; then C2="$status_msg"; else
                    printf "  %-25b %-25b\n" "$C1" "$C2"
                    C1="$status_msg"; C2=""
                fi
            fi
        }

        WS_PORT=$(ss -tlnp 2>/dev/null | grep -oP 'python3.*:(\K[0-9]+)' | head -1)
        [ -n "$WS_PORT" ] && check_and_display "WebSocket" "$(printf "${NEON}◈${NC} ${W}WebSocket:${WS_PORT}${NC} ${NEON}◆ ON${NC}")"
        
        [ -e "$DIR_SERVICES/badvpn-7200.service" ] && check_and_display "BadVPN" "$(printf "${NEON}◈${NC} ${W}BadVPN:7200${NC} %b" "$(status_service badvpn-7200)")"
        [ -e "$DIR_SERVICES/badvpn-7300.service" ] && check_and_display "BadVPN" "$(printf "${NEON}◈${NC} ${W}BadVPN:7300${NC} %b" "$(status_service badvpn-7300)")"
        
        pgrep -f "udp-custom" >/dev/null && check_and_display "UDP Custom" "$(printf "${NEON}◈${NC} ${W}UDP Custom${NC} ${NEON}◆ ON${NC}")"
        
        [ -e "$DIR_SERVICES/stunnel4.service" ] && check_and_display "SSL/TLS" "$(printf "${NEON}◈${NC} ${W}SSL/TLS:443${NC} %b" "$(status_service stunnel4)")"
        
        if systemctl is-active --quiet v2ray 2>/dev/null; then
            V2P=$(python3 -c "import json; c=json.load(open('/usr/local/etc/v2ray/config.json')); print(','.join([str(ib['port']) for ib in c.get('inbounds',[])]))" 2>/dev/null)
            [ -n "$V2P" ] && check_and_display "V2Ray" "$(printf "${NEON}◈${NC} ${W}V2Ray:${V2P}${NC} ${NEON}◆ ON${NC}")"
        fi
        
        [ -e "$DIR_SERVICES/server-sldns.service" ] && check_and_display "SlowDNS" "$(printf "${NEON}◈${NC} ${W}SlowDNS${NC} %b" "$(status_service server-sldns)")"
        
        DB_PORT=$(cat /etc/sshfreeltm/dropbear_port 2>/dev/null || echo "444")
        [ -e "$DIR_SERVICES/dropbear.service" ] && check_and_display "Dropbear" "$(printf "${NEON}◈${NC} ${W}Dropbear:${DB_PORT}${NC} %b" "$(status_service dropbear)")"
        
        [ -e "$DIR_SERVICES/hysteria-server.service" ] && check_and_display "LTMUDPv1" "$(printf "${NEON}◈${NC} ${W}LTMUDPv1${NC} %b" "$(status_service hysteria-server)")"

        if [ -n "$C1" ] && [ -n "$C2" ]; then printf "  %-25b %-25b\n" "$C1" "$C2"; elif [ -n "$C1" ]; then printf "  %s\n" "$C1"; else echo -e " ${DIM} No active services${NC}"; fi
        
        sep
        printf " \033[1;97m❬1❭ ⚡ SSH Users            ❬2❭ 📡 VMess Users\033[0m\n"
        printf " \033[1;97m❬3❭ 🛠️  Tools & Protocols  ❬4❭ 👤 SSH Online\033[0m\n"
        printf " \033[1;97m❬5❭ 📡 V2Ray Online\033[0m\n"
        printf " ${NEON}❖ Version: ${Y}%s ${NEON}❖${NC}\n" "$SCRIPT_VERSION"
        sep
        printf " ${Y}❬9❭ 🖥️  %-18s${NC} ${R}❬10❭ 🗑️  %s${NC}\n" "Configure MOTD" "Uninstall"
        printf " ${Y}❬11❭ 🔄 Update Script${NC}\n"
        sep
        printf " ${R}❬0❭ ✖  Exit${NC}\n"
        sep
        echo ""
        read -p " Option: " OPT
        case $OPT in
            1) menu_usuarios ;;
            2) menu_v2ray ;;
            3) menu_herramientas ;;
            4) usuarios_ssh_online_count ;; # Placeholder for online user functions
            5) usuarios_v2ray_online_count ;; # Placeholder
            9) instalar_motd ;;
            10) desinstalar_script ;;
            11) actualizar_script ;;
            0) echo -e "\n  ${G}Goodbye! — DarkZFull${NC}\n"; exit 0 ;;
            *) echo -e "  ${R}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Placeholder functions for online user counts to avoid errors
usuarios_ssh_online_count() { echo "SSH Online users function not implemented in this version."; sleep 2; }
usuarios_v2ray_online_count() { echo "V2Ray Online users function not implemented in this version."; sleep 2; }


[ "$EUID" -ne 0 ] && echo -e "${R}Please run as root${NC}" && exit 1
menu_principal