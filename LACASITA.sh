#!/bin/bash
clear
CTRL_C(){
  rm -rf LACASITA.sh
  exit
}
if [ "$(whoami)" != 'root' ]; then
  echo -e "\e[1;31mTO USE THE INSTALLER YOU MUST BE ROOT\nDO YOU NOT KNOW HOW TO START AS ROOT?\nTYPE THIS COMMAND IN YOUR TERMINAL ( sudo -i )\e[0m"
  exit
fi
trap "CTRL_C" INT TERM EXIT

# ── Version fetch ──────────────────────────────────────────────────────────────
# [EXTERNAL] github.com/lacasitamx/version — version string
v1=$(curl -sSL "https://raw.githubusercontent.com/lacasitamx/version/master/vercion")
echo "$v1" > /etc/versin_script

# ── Color / msg helper ─────────────────────────────────────────────────────────
msg () {
  v22=$(cat /etc/versin_script)
  vesaoSCT="\033[1;37mVersion \033[1;32m${v22}\033[1;31m]"
  BRAN='\033[1;37m'
  ROJO='\e[91m'
  VERMELHO='\e[91m'
  VERDE='\e[92m'
  AMARELO='\e[93m'
  AZUL='\e[94m'
  MAGENTA='\e[95m'
  MAG='\033[1;96m'
  NEGRITO='\e[1m'
  SEMCOR='\e[0m'
  case $1 in
    -tit)
      echo -e "\e[91m≪━━─━━─━─━─━─━─━━─━━─━─━─◈─━━─━─━─━─━━─━─━━─━─━━─━≫ \e[0m\n  \e[2;97m\e[3;93m❯❯❯❯❯❯ ꜱᴄʀɪᴩᴛ ᴍᴏᴅ ʟᴀᴄᴀꜱɪᴛᴀᴍx ❮❮❮❮❮❮\033[0m \033[1;31m[\033[1;32m${vesaoSCT}\n\e[91m≪━━─━─━━━─━─━─━─━─━━─━─━─◈─━─━─━─━─━━━─━─━─━━━─━─━≫   \e[0m"
      ;;
    -bar)
      cor="\e[91m————————————————————————————————————————————————————"
      echo -e "\e[0m\e[91m————————————————————————————————————————————————————\e[0m"
      ;;
    -bar2)
      cor="\e[91m————————————————————————————————————————————————————"
      echo -e "\e[0m\e[91m————————————————————————————————————————————————————\e[0m"
      ;;
    -verd)
      cor="\e[92m\e[1m"
      echo -e "\e[92m\e[1m${@:2}\e[0m"
      ;;
    -verm)
      cor="\e[93m\e[1m\e[91m"
      echo -e "\e[93m\e[1m\e[91m${@:2}\e[0m"
      ;;
    -verm2)
      cor="\e[91m\e[1m"
      echo -e "\e[91m\e[1m${@:2}\e[0m"
      ;;
    -ama)
      cor="\e[93m\e[1m"
      echo -e "\e[93m\e[1m${@:2}\e[0m"
      ;;
    -nazu)
      cor="\e[94m\e[1m"
      echo -ne "\e[94m\e[1m${@:2}\e[0m"
      ;;
    -ne)
      cor="\e[91m\e[1m"
      echo -ne "\e[91m\e[1m${@:2}\e[0m"
      ;;
  esac
}

# ── Directories ────────────────────────────────────────────────────────────────
SCPdir="/etc/VPS-MX"
SCPusr="/etc/VPS-MX/users"
SCPfrm="/etc/VPS-MX/tools"
SCPinst="/etc/VPS-MX/installers"
SCPinstal="/etc/VPS-MX/installers"
SCPidioma="/etc/VPS-MX/idioma"

# ── Time-based reboot ──────────────────────────────────────────────────────────
time_reboot(){
  REBOOT_TIMEOUT="$1"
  echo -e "     \e[1;97m\e[1;100mREBOOTING VPS IN $1 SECONDS\e[0m"
  while [ $REBOOT_TIMEOUT -gt 0 ]; do
    msg -ne "       -$REBOOT_TIMEOUT-\r"
    sleep 2
    : $((REBOOT_TIMEOUT--))
  done
  sudo reboot
}

# ── Banner (stored to /bin/last12) ─────────────────────────────────────────────
echo "\e[1;92m╭╮\e[93m╱╱╱\e[93m╭━━━╮\e[94m╭━━━╮\e[95m╭━━━╮\e[96m╭━━━╮\e[97m╭━━╮\e[93m╭━━━━╮\e[92m╭━━━╮\e[91m╭━╮╭━╮\e[93m╭━╮╭━╮\e[0m
\e[92m┃┃\e[93m╱╱╱\e[93m┃╭━╮┃\e[94m┃╭━╮┃\e[95m┃╭━╮┃\e[96m┃╭━╮┃\e[97m╰┫┣╯\e[93m┃╭╮╭╮┃\e[92m┃╭━╮┃\e[91m┃┃╰╯┃┃\e[93m╰╮╰╯╭╯\e[0m
\e[93m┃┃\e[93m╱╱╱\e[94m┃┃\e[91m╱\e[96m┃┃┃┃\e[91m╱\e[97m╰╯┃┃\e[91m╱\e[93m┃┃┃╰━━╮\e[91m╱\e[94m┃┃\e[91m╱\e[93m╰╯┃┃╰╯┃┃\e[91m╱\e[97m┃┃\e[93m┃╭╮╭╮┃\e[91m╱\e[94m╰╮╭╯\e[91m╱\e[0m
\e[92m┃┃\e[93m╱╭╮\e[94m┃╰━╯┃\e[95m┃┃\e[91m╱\e[97m╭╮┃╰━╯┃\e[93m╰━━╮┃\e[91m╱\e[93m┃┃\e[91m╱╱╱\e[96m┃┃\e[93m╱╱\e[94m┃╰━╯┃\e[97m┃┃\e[94m┃┃\e[93m┃┃\e[97m╭╯╭╮╰╮\e[0m
\e[93m┃╰━╯┃\e[94m┃╭━╮┃\e[91m┃╰━╯┃\e[97m┃╭━╮┃\e[95m┃╰━╯┃\e[97m╭┫┣╮\e[93m╱╱\e[94m┃┃\e[93m╱╱\e[94m┃╭━╮┃\e[97m┃┃\e[94m┃┃\e[93m┃┃\e[97m╭╯╭╮╰╮\e[0m
\e[94m╰━━━╯\e[93m╰╯\e[91m╱╰╯\e[93m╰━━━╯\e[97m╰╯\e[91m╱\e[95m╰╯╰━━━╯\e[94m╰━━╯\e[93m╱╱\e[94m╰╯\e[93m╱╱\e[94m╰╯\e[91m╱\e[91m╰╯\e[93m╰╯\e[94m╰╯\e[95m╰╯\e[97m╰━╯\e[93m╰━╯\e[0m
\e[1;93m╱╱╱╱╱╱╱╱╱╱╱╱╱\e[91m╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱\e[94m╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱\e[95m╱╱╱╱\e[0m
\e[1;93m╱╱╱╱╱╱╱╱╱╱╱╱╱\e[91m╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱\e[94m╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱\e[95m╱╱╱╱\e[0m" > /bin/last12
clear

# ── OS detection ───────────────────────────────────────────────────────────────
os_system(){
  # [EXTERNAL] github.com/lacasitamx/version — year string
  v3=$(curl -sSL "https://raw.githubusercontent.com/lacasitamx/version/master/anio")
  echo "$v3" > /etc/anio
  system=$(cat -n /etc/issue | grep 1 | cut -d ' ' -f6,7,8 | sed 's/1//' | sed 's/      //')
  distro=$(echo "$system" | awk '{print $1}')
  case $distro in
    Debian) vercion=$(echo $system | awk '{print $3}' | cut -d '.' -f1) ;;
    Ubuntu) vercion=$(echo $system | awk '{print $2}' | cut -d '.' -f1,2) ;;
  esac
  # [EXTERNAL] github.com/rudi9999/ADMRufu — repo list (commented out, kept for reference)
  link="https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Repositorios/${vercion}.list"
  case $vercion in
    8|9|10|11|16.04|18.04|20.04|20.10|21.04|21.10|22.04) ;;
    12*|24.04*) ;;
  esac
}

repo_install(){
  # [EXTERNAL] github.com/rudi9999/ADMRufu — repo list (commented out, kept for reference)
  link="https://raw.githubusercontent.com/rudi9999/ADMRufu/main/Repositorios/$VERSION_ID.list"
  case $VERSION_ID in
    8*|9*|10*|11*|16.04*|18.04*|20.04*|20.10*|21.04*|21.10*|22.04*) ;;
    12*|24.04*) ;;
  esac
}

stop_install(){
  msg -verm "     INSTALLATION CANCELLED"
  exit
}

function printTitle {
  echo ""
  echo -e "\033[1;92m$1\033[1;91m"
  printf '%0.s-' $(seq 1 ${#1})
  echo ""
}

del(){
  for (( i = 0; i < $1; i++ )); do
    tput cuu1 && tput dl1
  done
}

# ── Root VPS access (for cloud providers: AWS, GCP, Azure, etc.) ───────────────
rootvps(){
  msg -tit
  echo -e "\033[31m     OBTAINING ROOT ACCESS    "
  # [EXTERNAL] github.com/lacasitamx/VPSMX — root enabler script
  wget https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SR/root.sh \
    &>/dev/null -O /usr/bin/rootlx &>/dev/null
  chmod 775 /usr/bin/rootlx &>/dev/null
  rootlx
  clear
  echo -e "\033[31m     ROOT ACCESS SUCCESSFUL    "
  sleep 1
  rm -rf /usr/bin/rootlx
}

msg -bar
echo -e "\033[1;93m  DO YOU ALREADY HAVE ROOT ACCESS TO YOUR VPS?\n  THIS ONLY WORKS FOR (AWS, GOOGLECLOUD, AZURE, ETC)\n  IF YOU ALREADY HAVE ROOT ACCESS JUST IGNORE THIS MESSAGE\n  AND CONTINUE WITH THE NORMAL INSTALLATION..."
msg -bar
read -p "Answer [ y | n ]: " -e -i n rootvps_ans
[[ "$rootvps_ans" = "y" || "$rootvps_ans" = "Y" ]] && rootvps
clear

# ── IP detection ───────────────────────────────────────────────────────────────
fun_ipe(){
  # [EXTERNAL] whatismyip.akamai.com — public IP detection
  MIP=$(wget -qO- whatismyip.akamai.com)
  if [ $? -eq 0 ]; then
    IP="$MIP"
  else
    # [EXTERNAL] ipv4.icanhazip.com — fallback IP detection
    IP="$MIP2"
  fi
  # [EXTERNAL] ipv4.icanhazip.com — secondary IP check
  MIP2=$(wget -qO- ipv4.icanhazip.com)
  [[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
  echo "$IP" > /bin/IPca
}

# ── Dependencies ───────────────────────────────────────────────────────────────
dependencias(){
  msg -tit
  msg -ama "               PREPARING INSTALLATION"
  msg -bar2
  clear
  printTitle "Cleaning local cache"
  apt-get clean
  clear
  printTitle "Updating packages"
  dpkg --configure -a &>/dev/null
  apt install sudo -y &>/dev/null
  clear
  os_system
  msg -tit
  echo "$distro $vercion" > /tmp/distro
  echo -e "\e[1;31m       🖥 SYSTEM: \e[33m$distro $vercion   "
  echo -e "\e[1;31m       🖥 IP: \e[33m$IP   "
  echo -e "  \033[41m   -- PACKAGE INSTALLATION | $(cat /etc/anio) --    \e[49m"
  msg -bar
  soft="sudo bsdmainutils zip unzip ufw curl python python3 python3-pip openssl screen cron iptables lsof nano at mlocate gawk figlet grep bc jq curl socat netcat net-tools cowsay lolcat figlet toilet pv perl apache2"
  for install in $soft; do
    leng="${#install}"
    puntos=$(( 21 - $leng ))
    pts="."
    for (( a = 0; a < $puntos; a++ )); do
      pts+="."
    done
    msg -nazu "   INSTALLING $install $(msg -ama "$pts")"
    if [[ $(dpkg --get-selections | grep -w "${install}" | head -1) ]] || sudo apt-get install ${install} -y &>/dev/null; then
      msg -verd " INSTALLED"
    else
      msg -verm2 " FAILED"
      sleep 2
      del 1
      if [[ $install = "python" ]]; then
        pts=$(echo ${pts:1})
        msg -nazu "   INSTALLING python2 $(msg -ama "$pts")"
        if apt-get install python2 -y &>/dev/null; then
          apt-get install python -y >/dev/null 2>&1
          apt-get install python2 -y >/dev/null 2>&1
          apt-get install python3.6 -y >/dev/null 2>&1
          apt-get install python3.7 -y >/dev/null 2>&1
          apt-get install python3.8 -y >/dev/null 2>&1
          apt-get install python3.9 -y >/dev/null 2>&1
          update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1 >/dev/null 2>&1
          update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 3 >/dev/null 2>&1
          update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2 >/dev/null 2>&1
          update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 4 >/dev/null 2>&1
          apt install pip -y &>/dev/null
          apt install python3-pip -y &>/dev/null
          apt install socat -y &>/dev/null
          update-alternatives --set python3 /usr/bin/python3.6
          msg -verd " INSTALLED"
        else
          msg -verm2 " FAILED"
        fi
        continue
      fi
      msg -ama " applying fix to $install"
      dpkg --configure -a &>/dev/null
      sleep 2
    fi
  done
}

# ── Finalize installation ──────────────────────────────────────────────────────
install_fim(){
  msg -ama "               Finalizing Installation" && msg -bar2

  # [EXTERNAL] github.com/lacasitamx/VPSMX — utility log files
  [[ $(find /etc/VPS-MX/controlador -name nombre.log 2>/dev/null | grep -w "nombre.log" | head -1) ]] || \
    wget -O /etc/VPS-MX/controlador/nombre.log \
    https://github.com/lacasitamx/VPSMX/raw/master/ArchivosUtilitarios/nombre.log &>/dev/null
  [[ $(find /etc/VPS-MX/controlador -name IDT.log 2>/dev/null | grep -w "IDT.log" | head -1) ]] || \
    wget -O /etc/VPS-MX/controlador/IDT.log \
    https://github.com/lacasitamx/VPSMX/raw/master/ArchivosUtilitarios/IDT.log &>/dev/null
  [[ $(find /etc/VPS-MX/controlador -name tiemlim.log 2>/dev/null | grep -w "tiemlim.log" | head -1) ]] || \
    wget -O /etc/VPS-MX/controlador/tiemlim.log \
    https://github.com/lacasitamx/VPSMX/raw/master/ArchivosUtilitarios/tiemlim.log &>/dev/null

  touch /usr/share/lognull &>/dev/null

  # [EXTERNAL] github.com/lacasitamx/VPSMX — SPR script
  wget https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SR/SPR \
    &>/dev/null -O /usr/bin/SPR &>/dev/null
  chmod 775 /usr/bin/SPR &>/dev/null

  # DNS fallback
  [[ -z $(cat /etc/resolv.conf | grep "8.8.8.8") ]] && echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  [[ -z $(cat /etc/resolv.conf | grep "1.1.1.1") ]] && echo "nameserver 1.1.1.1" >> /etc/resolv.conf

  # [EXTERNAL] github.com/lacasitamx/VPSMX — reboot helper
  wget -O /bin/rebootnb \
    https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/rebootnb &>/dev/null
  chmod +x /bin/rebootnb

  # [EXTERNAL] github.com/lacasitamx/VPSMX — SSH drop reset helper
  wget -O /bin/resetsshdrop \
    https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/resetsshdrop &>/dev/null
  chmod +x /bin/resetsshdrop

  # [EXTERNAL] github.com/lacasitamx/version — new version string
  wget -O /etc/versin_script_new \
    https://raw.githubusercontent.com/lacasitamx/version/master/vercion &>/dev/null

  # [EXTERNAL] github.com/lacasitamx/ZETA — sshd_config
  wget -O /etc/ssh/sshd_config \
    https://raw.githubusercontent.com/lacasitamx/ZETA/master/sshd &>/dev/null
  chmod 777 /etc/ssh/sshd_config

  msg -bar2

  # rc.local
  echo '#!/bin/sh -e' > /etc/rc.local
  sudo chmod +x /etc/rc.local
  echo "sudo rebootnb" >> /etc/rc.local
  echo "sudo resetsshdrop" >> /etc/rc.local
  echo "sleep 2s" >> /etc/rc.local
  echo "exit 0" >> /etc/rc.local

  # .bashrc setup
  /bin/cp /etc/skel/.bashrc ~/
  echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/' >> /etc/profile
  echo 'clear' >> .bashrc
  echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/' >> .bashrc
  echo 'echo ""' >> .bashrc
  echo 'fecha=$(date +"%d-%b-%y")' >> .bashrc
  echo 'hora=$(date +"%T")' >> .bashrc
  echo 'mn=$(cat /bin/last12)' >> .bashrc
  echo 'echo -e "\033[1;91m——————————————————————————————————————————————————\e[0m" ' >> .bashrc
  echo 'echo -e "${mn}"' >> .bashrc
  echo 'mess1="$(less /etc/VPS-MX/message.txt)" ' >> .bashrc
  echo 'echo -e "\033[1;91m——————————————————————————————————————————————————\e[0m" ' >> .bashrc
  echo 'echo -e "\t\033[1;91mRESELLER :\e[92m $mess1 "' >> .bashrc
  echo 'echo -e "\t\e[1;33mVERSION: \e[1;31m$(cat /etc/versin_script_new)"' >> .bashrc
  echo 'echo -e "\e[1;97m  TIME: \e[1;91m$hora    \e[1;97mDATE: \e[1;91m${fecha}\e[0m"' >> .bashrc
  echo 'echo -e "\033[1;91m——————————————————————————————————————————————————\e[0m" ' >> .bashrc
  echo 'echo -e "\t\033[1;100mTO ENTER THE MENU TYPE:\e[0m\e[1;41m menu \e[0m"' >> .bashrc
  echo 'echo ""' >> .bashrc

  echo -e "         MAIN COMMAND TO ENTER THE SCRIPT "
  echo -e "  \033[1;41m               sudo menu             \033[0;37m" && msg -bar2

  rm -rf /usr/bin/pytransform &>/dev/null
  rm -rf LACASITA.sh
  rm -rf lista-arq
  service ssh restart &>/dev/null
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/
  time_reboot "10"
}

# ── File organiser ─────────────────────────────────────────────────────────────
verificar_arq(){
  [[ ! -d ${SCPdir} ]]   && mkdir ${SCPdir}
  [[ ! -d ${SCPusr} ]]   && mkdir ${SCPusr}
  [[ ! -d ${SCPfrm} ]]   && mkdir ${SCPfrm}
  [[ ! -d ${SCPinst} ]]  && mkdir ${SCPinst}
  [[ ! -d ${SCPdir}/tmp ]]   && mkdir ${SCPdir}/tmp
  [[ ! -d ${SCPdir}/passw ]] && mkdir ${SCPdir}/passw
  case $1 in
    "menu"|"message.txt"|"ID") ARQ="${SCPdir}/" ;;
    "C-SSR.sh"|"UDPcustom.sh") ARQ="${SCPinst}/" ;;
    "openssh.sh")               ARQ="${SCPinst}/" ;;
    "squid.sh")                 ARQ="${SCPinst}/" ;;
    "dropbear.sh"|"proxy.sh"|"wireguard.sh") ARQ="${SCPinst}/" ;;
    "openvpn.sh")               ARQ="${SCPinst}/" ;;
    "ssl.sh"|"python.py")       ARQ="${SCPinst}/" ;;
    "shadowsocks.sh")           ARQ="${SCPinst}/" ;;
    "Shadowsocks-libev.sh")     ARQ="${SCPinst}/" ;;
    "Shadowsocks-R.sh")         ARQ="${SCPinst}/" ;;
    "v2ray.sh"|"slowdns.sh")    ARQ="${SCPinst}/" ;;
    "name"|"adminkey")          ARQ="${SCPdir}/tmp/" ;;
    "sockspy.sh"|"PDirect.py"|"PPub.py"|"PPriv.py"|"POpen.py"|"PGet.py") ARQ="${SCPinst}/" ;;
    *) ARQ="${SCPfrm}/" ;;
  esac
  mv -f ${SCPinstal}/$1 ${ARQ}/$1
  chmod +x ${ARQ}/$1
}

# ── Install start ──────────────────────────────────────────────────────────────
install_start(){
  clear
  os_system
  msg -tit
  echo -e "\e[1;31m       🖥 SYSTEM: \e[33m$distro $vercion   "
  msg -bar
  repo_install
  install_continue
}

install_continue(){
  dependencias
}

# ── Download extra utilities ───────────────────────────────────────────────────
# [EXTERNAL] github.com/scriptsmx/script — translate helper
wget -O /usr/bin/trans \
  https://raw.githubusercontent.com/scriptsmx/script/master/Install/trans &>/dev/null
# [EXTERNAL] github.com/lacasitamx/VPSMX — network monitor
wget -O /bin/monitor.sh \
  https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/monitor.sh &>/dev/null
chmod +x /bin/monitor.sh
# [EXTERNAL] github.com/lacasitamx/VPSMX — web panel CSS
wget -O /var/www/html/estilos.css \
  https://raw.githubusercontent.com/lacasitamx/VPSMX/master/SCRIPT-8.4/Utilidad/estilos.css &>/dev/null

[[ -f "/usr/sbin/ufw" ]] && ufw allow 443/tcp &>/dev/null
ufw allow 80/tcp   &>/dev/null
ufw allow 3128/tcp &>/dev/null
ufw allow 8799/tcp &>/dev/null
ufw allow 8080/tcp &>/dev/null
ufw allow 81/tcp   &>/dev/null

# ── Key entry (license check removed — goes straight to install) ───────────────
ingresar_key(){
  /bin/cp /etc/skel/.bashrc ~/
  service apache2 restart >/dev/null 2>&1

  [[ ! -d ${SCPdir} ]]        && mkdir -p ${SCPdir}
  [[ ! -d ${SCPdir}/tmp ]]    && mkdir -p ${SCPdir}/tmp
  [[ ! -d ${SCPdir}/passw ]]  && mkdir -p ${SCPdir}/passw
  [[ ! -d ${SCPusr} ]]        && mkdir -p ${SCPusr}
  [[ ! -d ${SCPfrm} ]]        && mkdir -p ${SCPfrm}
  [[ ! -d ${SCPinst} ]]       && mkdir -p ${SCPinst}
  [[ ! -d /etc/VPS-MX/controlador ]] && mkdir -p /etc/VPS-MX/controlador
  [[ ! -d /etc/VPS-MX/protocolos ]]  && mkdir -p /etc/VPS-MX/protocolos

  # Update version
  v1=$(curl -sSL "https://raw.githubusercontent.com/lacasitamx/version/master/vercion")
  echo "$v1" > /etc/versin_script

  msg -bar2
  msg -verd "    Files Ready"

  # ── Download all protocol/tool scripts ────────────────────────────────────
  archivos='wireguard.sh
adminkey
name
ID
slowdns.sh
ADMbot.sh
C-SSR.sh
PDirect.py
PGet.py
POpen.py
PPriv.py
PPub.py
fai2ban.sh
message.txt
openvpn.sh
ports.sh
speed.py
squid.sh
squidpass.sh
python.py'

  # [EXTERNAL] gitea.com/blubin/INFAM — menu and protocol files
  lisArq="https://gitea.com/blubin/INFAM/raw/hack/Arc"

  pontos="!"
  stopping="Downloading Files"
  for arqx in $(echo ${archivos}); do
    msg -verm "${stopping}${pontos}"
    # [EXTERNAL] gitea.com/blubin/INFAM — individual protocol/tool files
    wget --no-check-certificate -O ${SCPinstal}/${arqx} ${lisArq}/${arqx} &>/dev/null && \
      verificar_arq "${arqx}" || {
        msg -verm2 "  Failed to download: ${arqx} — skipping"
      }
    tput cuu1 && tput dl1
    pontos+="!"
  done

  # [EXTERNAL] gitea.com/blubin/INFAM — main menu file
  wget --no-check-certificate -O ${SCPdir}/menu ${lisArq}/menu &>/dev/null
  chmod 777 ${SCPdir}/menu

  # IP log
  wget -qO- ipv4.icanhazip.com > /etc/VPS-MX/IP.log

  msg -bar2
  [[ -e $HOME/lista-arq ]] && rm -rf $HOME/lista-arq

  # bash.bashrc timeout for non-root
  cat /etc/bash.bashrc | grep -v '[[ $UID != 0 ]] && TMOUT=15 && export TMOUT' > /etc/bash.bashrc.2
  echo -e '[[ $UID != 0 ]] && TMOUT=15 && export TMOUT' >> /etc/bash.bashrc.2
  mv -f /etc/bash.bashrc.2 /etc/bash.bashrc

  # Menu symlinks
  rm -rf /usr/bin/menu
  rm -rf /usr/bin/VPSMX
  ln -s /etc/VPS-MX/menu /usr/bin/menu
  ln -s /etc/VPS-MX/menu /usr/bin/VPSMX

  [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
  echo "es" > ${SCPidioma}

  msg -bar2
  install_fim
}

# ── Main flow ──────────────────────────────────────────────────────────────────
idioma(){
  clear
  clear
  msg -bar2
  echo -e "$(cat /bin/last12)"
  byinst="true"
}

fun_ipe
source /etc/os-release; export PRETTY_NAME
install_start

idioma
ingresar_key
