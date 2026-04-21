#!/bin/bash
# =============================================================================
#  VPSMX - Personal VPS Autoscript
#  Author  : lacasitamx (cleaned & rebuilt)
#  Target  : Ubuntu 20.04 / 22.04 / Debian 10 / 11
#  Run as  : root
# =============================================================================

# ---------------------------------------------------------------------------
# COLORS
# ---------------------------------------------------------------------------
RED='\e[91m'
GREEN='\e[92m'
YELLOW='\e[93m'
BLUE='\e[94m'
MAGENTA='\e[95m'
CYAN='\e[96m'
WHITE='\e[97m'
BOLD='\e[1m'
RESET='\e[0m'

# ---------------------------------------------------------------------------
# DIRECTORIES
# ---------------------------------------------------------------------------
VPSDIR="/etc/VPS-MX"
INSTDIR="${VPSDIR}/installers"
CTRLDIR="${VPSDIR}/control"
TMPDIR="${VPSDIR}/tmp"

# ---------------------------------------------------------------------------
# TRAP — clean up on Ctrl+C / exit
# ---------------------------------------------------------------------------
cleanup() {
    echo -e "\n${RED}Installation cancelled.${RESET}"
    exit 1
}
trap cleanup INT TERM

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
bar() {
    echo -e "${RED}————————————————————————————————————————————————————${RESET}"
}

bar2() {
    echo -e "${RED}≪━━─━━─━─━─━─━─━━─━━─━─━─◈─━━─━─━─━─━━─━─━━─━─━━─━≫${RESET}"
}

title() {
    echo ""
    echo -e "${GREEN}${BOLD}$1${RESET}"
    printf '%0.s-' $(seq 1 ${#1})
    echo ""
}

msg_ok()   { echo -e "${GREEN}${BOLD}  ✔ $*${RESET}"; }
msg_err()  { echo -e "${RED}${BOLD}  ✘ $*${RESET}"; }
msg_info() { echo -e "${YELLOW}  » $*${RESET}"; }
msg_warn() { echo -e "${MAGENTA}  ⚠ $*${RESET}"; }

# Delete N lines upward in terminal
del() {
    for (( i = 0; i < $1; i++ )); do
        tput cuu1 && tput dl1
    done
}

# ---------------------------------------------------------------------------
# ROOT CHECK
# ---------------------------------------------------------------------------
check_root() {
    if [[ $(whoami) != "root" ]]; then
        echo -e "${RED}${BOLD}You must run this script as root.${RESET}"
        echo -e "${YELLOW}Try:  sudo -i${RESET}"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# DETECT PUBLIC IP
# ---------------------------------------------------------------------------
get_ip() {
    # [EXTERNAL] icanhazip.com — returns your public IPv4
    IP=$(curl -s --max-time 5 https://ipv4.icanhazip.com 2>/dev/null)
    if [[ -z "$IP" ]]; then
        # [EXTERNAL] akamai — fallback IP detection
        IP=$(curl -s --max-time 5 https://whatismyip.akamai.com 2>/dev/null)
    fi
    if [[ -z "$IP" ]]; then
        # [EXTERNAL] ifconfig.me — second fallback
        IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null)
    fi
    echo "${IP:-Unknown}"
}

# ---------------------------------------------------------------------------
# DETECT OS
# ---------------------------------------------------------------------------
detect_os() {
    source /etc/os-release 2>/dev/null
    DISTRO="${ID^}"          # e.g. Ubuntu / Debian
    VERSION="${VERSION_ID}"  # e.g. 22.04
}

# ---------------------------------------------------------------------------
# BANNER
# ---------------------------------------------------------------------------
show_banner() {
    clear
    bar2
    echo -e "${CYAN}${BOLD}"
    echo "   ██╗      █████╗  ██████╗ █████╗ ███████╗██╗████████╗ █████╗ ███╗   ███╗██╗  ██╗"
    echo "   ██║     ██╔══██╗██╔════╝██╔══██╗██╔════╝██║╚══██╔══╝██╔══██╗████╗ ████║╚██╗██╔╝"
    echo "   ██║     ███████║██║     ███████║███████╗██║   ██║   ███████║██╔████╔██║ ╚███╔╝ "
    echo "   ██║     ██╔══██║██║     ██╔══██║╚════██║██║   ██║   ██╔══██║██║╚██╔╝██║ ██╔██╗ "
    echo "   ███████╗██║  ██║╚██████╗██║  ██║███████║██║   ██║   ██║  ██║██║ ╚═╝ ██║██╔╝ ██╗"
    echo "   ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝"
    echo -e "${RESET}"
    bar2
    echo -e "  ${WHITE}System : ${YELLOW}${DISTRO} ${VERSION}"
    echo -e "  ${WHITE}IP     : ${YELLOW}${IP}"
    bar2
}

# ---------------------------------------------------------------------------
# MAKE DIRECTORIES
# ---------------------------------------------------------------------------
init_dirs() {
    mkdir -p "${VPSDIR}" "${INSTDIR}" "${CTRLDIR}" "${TMPDIR}"
    mkdir -p "${VPSDIR}/passw" "${VPSDIR}/protocolos"
}

# ---------------------------------------------------------------------------
# DEPENDENCIES
# ---------------------------------------------------------------------------
install_dependencies() {
    title "Updating package lists"
    dpkg --configure -a &>/dev/null
    apt-get update -y &>/dev/null
    apt-get install -y sudo &>/dev/null

    local packages=(
        sudo bsdmainutils zip unzip ufw curl wget
        python3 python3-pip openssl screen cron
        iptables lsof nano at mlocate gawk grep bc
        jq socat netcat-openbsd net-tools
        figlet toilet pv perl apache2
        lolcat cowsay
    )

    bar
    msg_info "Installing required packages..."
    bar

    for pkg in "${packages[@]}"; do
        local dots
        dots=$(printf '%.0s.' $(seq 1 $((24 - ${#pkg}))))
        echo -ne "${CYAN}  Installing ${pkg} ${YELLOW}${dots}${RESET}"

        if dpkg -l "$pkg" &>/dev/null || apt-get install -y "$pkg" &>/dev/null; then
            echo -e " ${GREEN}OK${RESET}"
        else
            echo -e " ${RED}FAILED${RESET}"
        fi
    done

    bar
    msg_ok "Package installation complete."
}

# ---------------------------------------------------------------------------
# UFW FIREWALL
# ---------------------------------------------------------------------------
setup_firewall() {
    title "Configuring UFW Firewall"
    if [[ -f /usr/sbin/ufw ]]; then
        ufw allow 22/tcp   &>/dev/null   # SSH
        ufw allow 80/tcp   &>/dev/null   # HTTP
        ufw allow 443/tcp  &>/dev/null   # HTTPS
        ufw allow 3128/tcp &>/dev/null   # Squid proxy
        ufw allow 8080/tcp &>/dev/null   # Alt HTTP
        ufw allow 8799/tcp &>/dev/null   # Custom
        ufw allow 81/tcp   &>/dev/null   # Alt HTTP
        msg_ok "Firewall rules applied."
    else
        msg_warn "UFW not found — skipping firewall setup."
    fi
}

# ---------------------------------------------------------------------------
# DNS — add fallback resolvers if missing
# ---------------------------------------------------------------------------
setup_dns() {
    [[ -z $(grep "8.8.8.8" /etc/resolv.conf) ]] && echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    [[ -z $(grep "1.1.1.1" /etc/resolv.conf) ]] && echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    msg_ok "DNS resolvers verified."
}

# ---------------------------------------------------------------------------
# SSH HARDENING
# ---------------------------------------------------------------------------
harden_ssh() {
    title "Hardening SSH"
    local sshd_cfg="/etc/ssh/sshd_config"
    cp "${sshd_cfg}" "${sshd_cfg}.bak.$(date +%Y%m%d)" 2>/dev/null

    # Apply safe hardening settings
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/'         "$sshd_cfg"
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$sshd_cfg"
    sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/'              "$sshd_cfg"
    sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 5/'                  "$sshd_cfg"
    sed -i 's/^#\?LoginGraceTime.*/LoginGraceTime 60/'            "$sshd_cfg"

    # Ensure AllowTcpForwarding is on (needed for tunnels/VPN)
    grep -q "^AllowTcpForwarding" "$sshd_cfg" \
        && sed -i 's/^AllowTcpForwarding.*/AllowTcpForwarding yes/' "$sshd_cfg" \
        || echo "AllowTcpForwarding yes" >> "$sshd_cfg"

    systemctl restart ssh &>/dev/null || service ssh restart &>/dev/null
    msg_ok "SSH hardened and restarted."
}

# ---------------------------------------------------------------------------
# RC.LOCAL — run startup scripts on boot
# ---------------------------------------------------------------------------
setup_rc_local() {
    title "Setting up rc.local"
    cat > /etc/rc.local <<'EOF'
#!/bin/sh -e
# rc.local — runs at boot
sleep 2
exit 0
EOF
    chmod +x /etc/rc.local
    msg_ok "rc.local configured."
}

# ---------------------------------------------------------------------------
# BASH PROFILE — MOTD / welcome message
# ---------------------------------------------------------------------------
setup_bashrc() {
    title "Configuring login welcome message"

    # Save the banner to a file so .bashrc can display it
    cat > /etc/vpsmx_banner.sh <<'BANNER'
#!/bin/bash
VERSION=$(cat /etc/versin_script 2>/dev/null || echo "N/A")
RESELLER=$(cat /etc/VPS-MX/message.txt 2>/dev/null || echo "N/A")
IP=$(cat /bin/IPca 2>/dev/null || echo "N/A")
FECHA=$(date +"%d-%b-%Y")
HORA=$(date +"%T")
echo -e "\e[91m——————————————————————————————————————————————————\e[0m"
echo -e "\e[93m  LACASITAMX VPS Script\e[0m"
echo -e "\e[97m  Reseller  : \e[92m${RESELLER}"
echo -e "\e[97m  Version   : \e[91m${VERSION}"
echo -e "\e[97m  IP        : \e[91m${IP}"
echo -e "\e[97m  Time      : \e[91m${HORA}   Date: ${FECHA}\e[0m"
echo -e "\e[91m——————————————————————————————————————————————————\e[0m"
echo -e "\e[100m  Type  \e[0m\e[41m menu \e[0m  to open the main menu"
echo ""
BANNER
    chmod +x /etc/vpsmx_banner.sh

    # Append to .bashrc if not already there
    if ! grep -q "vpsmx_banner" ~/.bashrc; then
        {
            echo 'clear'
            echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/'
            echo 'bash /etc/vpsmx_banner.sh'
        } >> ~/.bashrc
    fi

    # Enforce timeout for non-root users
    grep -q 'TMOUT' /etc/bash.bashrc \
        || echo '[[ $UID != 0 ]] && TMOUT=900 && export TMOUT' >> /etc/bash.bashrc

    msg_ok ".bashrc and MOTD configured."
}

# ---------------------------------------------------------------------------
# DOWNLOAD UTILITIES — all external downloads are clearly labeled
# ---------------------------------------------------------------------------
download_utilities() {
    title "Downloading utility scripts"
    bar

    # [EXTERNAL] lacasitamx GitHub — reboot helper
    msg_info "[DOWNLOAD] rebootnb  ← github.com/lacasitamx/VPSMX"
    wget -q -O /bin/rebootnb \
        https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/rebootnb \
        && chmod +x /bin/rebootnb && msg_ok "rebootnb downloaded." \
        || msg_err "rebootnb download failed."

    # [EXTERNAL] lacasitamx GitHub — SSH reset helper
    msg_info "[DOWNLOAD] resetsshdrop  ← github.com/lacasitamx/VPSMX"
    wget -q -O /bin/resetsshdrop \
        https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/resetsshdrop \
        && chmod +x /bin/resetsshdrop && msg_ok "resetsshdrop downloaded." \
        || msg_err "resetsshdrop download failed."

    # [EXTERNAL] lacasitamx GitHub — network monitor
    msg_info "[DOWNLOAD] monitor.sh  ← github.com/lacasitamx/VPSMX"
    wget -q -O /bin/monitor.sh \
        https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/monitor.sh \
        && chmod +x /bin/monitor.sh && msg_ok "monitor.sh downloaded." \
        || msg_err "monitor.sh download failed."

    # [EXTERNAL] lacasitamx GitHub — web panel CSS
    msg_info "[DOWNLOAD] estilos.css  ← github.com/lacasitamx/VPSMX"
    wget -q -O /var/www/html/estilos.css \
        https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/estilos.css \
        && msg_ok "estilos.css downloaded." \
        || msg_err "estilos.css download failed."

    # [EXTERNAL] scriptsmx GitHub — translation helper
    msg_info "[DOWNLOAD] trans  ← github.com/scriptsmx/script"
    wget -q -O /usr/bin/trans \
        https://raw.githubusercontent.com/scriptsmx/script/master/Install/trans \
        && chmod +x /usr/bin/trans && msg_ok "trans downloaded." \
        || msg_err "trans download failed."

    bar
}

# ---------------------------------------------------------------------------
# MENU SYMLINKS
# ---------------------------------------------------------------------------
setup_menu_links() {
    title "Setting up menu command"
    rm -f /usr/bin/menu /usr/bin/VPSMX

    if [[ -f "${VPSDIR}/menu" ]]; then
        ln -s "${VPSDIR}/menu" /usr/bin/menu
        ln -s "${VPSDIR}/menu" /usr/bin/VPSMX
        msg_ok "menu command linked."
    else
        msg_warn "Menu file not found at ${VPSDIR}/menu — skipping symlink."
    fi
}

# ---------------------------------------------------------------------------
# WRITE VERSION FILE
# ---------------------------------------------------------------------------
write_version() {
    # [EXTERNAL] lacasitamx GitHub — version string
    local ver
    ver=$(curl -sSL --max-time 5 \
        https://raw.githubusercontent.com/lacasitamx/version/master/vercion 2>/dev/null)
    echo "${ver:-local}" > /etc/versin_script
    msg_ok "Version written: ${ver:-local}"
}

# ---------------------------------------------------------------------------
# WRITE IP CACHE
# ---------------------------------------------------------------------------
write_ip_cache() {
    echo "$IP" > /bin/IPca
    msg_ok "IP cached: $IP"
}

# ---------------------------------------------------------------------------
# FINALIZE
# ---------------------------------------------------------------------------
finalize() {
    bar2
    msg_ok "Installation complete!"
    bar
    echo -e "  ${WHITE}Type ${YELLOW}menu${WHITE} after reboot to access the main panel.${RESET}"
    bar2
    echo ""
    echo -e "  ${YELLOW}Rebooting in 10 seconds... (Ctrl+C to cancel)${RESET}"
    for i in $(seq 10 -1 1); do
        echo -ne "  ${RED}$i...${RESET}\r"
        sleep 1
    done
    echo ""
    reboot
}

# ---------------------------------------------------------------------------
# ROOT VPS ACCESS (for cloud providers like AWS, GCP, Azure)
# ---------------------------------------------------------------------------
enable_root_access() {
    bar
    echo -e "${YELLOW}  Do you already have root access on this VPS?${RESET}"
    echo -e "  ${WHITE}(Skip this if you're already root — this is only for cloud VPS providers)${RESET}"
    bar
    read -rp "  Enable root access? [y/N]: " rootchoice
    if [[ "$rootchoice" =~ ^[yY]$ ]]; then
        # [EXTERNAL] lacasitamx GitHub — root enabler script
        msg_info "[DOWNLOAD] root.sh  ← github.com/lacasitamx/VPSMX"
        wget -q -O /usr/bin/rootlx \
            https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SR/root.sh \
            && chmod +x /usr/bin/rootlx \
            && /usr/bin/rootlx \
            && msg_ok "Root access enabled." \
            || msg_err "Root access script failed to download."
        rm -f /usr/bin/rootlx
    fi
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
    check_root
    detect_os
    IP=$(get_ip)
    show_banner

    bar
    echo -e "  ${WHITE}Starting installation on ${YELLOW}${DISTRO} ${VERSION}${RESET}"
    echo -e "  ${WHITE}Public IP: ${YELLOW}${IP}${RESET}"
    bar
    sleep 2

    enable_root_access
    init_dirs
    write_ip_cache
    write_version
    install_dependencies
    setup_dns
    setup_firewall
    harden_ssh
    setup_rc_local
    setup_bashrc
    download_utilities
    setup_menu_links
    finalize
}

main "$@"
