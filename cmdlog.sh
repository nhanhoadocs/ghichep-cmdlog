#!/bin/bash
# CMD log version 2 2019-10-05
# CanhDX NhanHoa Cloud Team 
# canhdx@nhanhoa.com.vn && uncelvel@gmail.com

# Variable
set -e
OS=""
OS_VER=""
# HOME=$HOME
# if [[ "$HOME" == "/root" ]]; then 
#     USER="root"
# else
#     USER=${HOME#*/home/}
# fi

# Check sudo user 
if [[ "$EUID" -ne 0 ]]; then 
    echo "Please run as root or sudo"
    exit 1;
fi


# Check OS
echo "Check Your OS"
if cat /etc/*release | grep CentOS > /dev/null 2>&1; then

    OS="CentOS"

    if [ $(rpm --eval '%{centos_ver}') == '6' ] ;then 
        OS_VER="CentOS6"
    elif [ $(rpm --eval '%{centos_ver}') == '7' ] ;then 
        OS_VER="CentOS7"
    elif [ $(rpm --eval '%{centos_ver}') == '8' ] ;then 
        OS_VER="CentOS8"
    fi 
elif cat /etc/*release | grep ^NAME | grep Ubuntu > /dev/null 2>&1; then

    OS="Ubuntu"

    if [ $(lsb_release -c | grep Codename | awk '{print $2}') == 'trusty' ] ;then 
        OS_VER="Ubuntu14"
    elif [ $(lsb_release -c | grep Codename | awk '{print $2}') == 'xenial' ] ;then 
        OS_VER="Ubuntu16"
    elif [ $(lsb_release -c | grep Codename | awk '{print $2}') == 'bionic' ] ;then 
        OS_VER="Ubuntu18"
    elif [ $(lsb_release -c | grep Codename | awk '{print $2}') == 'focal' ] ;then 
        OS_VER="Ubuntu20"
    fi 
else
    echo "Script doesn't support or verify this OS type/version"
    exit 1;
fi 

# Check install rsyslog
echo "Check Rsyslog installed"
if [[ $OS == "CentOS" ]]; then 
    if ! rpm -qa | grep rsyslog > /dev/null 2>&1; then
        yum install -y install rsyslog 
    fi 
elif [[ $OS == "Ubuntu" ]]; then 
    if ! dpkg --get-selections | grep rsyslog > /dev/null 2>&1; then
        apt-get -y install rsyslog 
    fi 
fi

# Check config cmdlog
echo "Check old cmdlog config"
if [[ -f "/var/log/cmdlog.log" ]]; then 
    echo "Server have been config CMD log before, Please check your config"
    exit 1;
fi 

# Config for current user 
echo "Config cmdlog for current user"
touch /var/log/cmdlog.log
chmod 600 /var/log/cmdlog.log

if [[ -d "$HOME" ]] && [[ -f "$HOME/.bashrc" ]]; then 
    echo "# Command log" >> ~/.bashrc
    echo "export PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug \"[\$(echo \$SSH_CLIENT | cut -d\" \" -f1)] # \$(history 1 | sed \"s/^[ ]*[0-9]\+[ ]*//\" )\"'" >> ~/.bashrc
    echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> ~/.bashrc
    source ~/.bashrc
elif [[ -d "$HOME" ]] && [[ ! -f "$HOME/.bashrc" ]]; then 
    curl -o ~/.bashrc  https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/config/"$OS".bashrc > /dev/null 2>&1
else 
    echo "Please check config \$HOME for this account"
fi 


# Config for user add 
echo "Config auto cmdlog for new useradd"
if [[ $OS == "CentOS" ]]; then 
    echo "# Command log" >> /etc/skel/.bashrc
    echo "export PROMPT_COMMAND='RETRN_VAL=$?;logger -p local6.debug \"[\$(echo \$SSH_CLIENT | cut -d\" \" -f1)] # \$(history 1 | sed \"s/^[ ]*[0-9]\+[ ]*//\" )\"'" >> /etc/skel/.bashrc
    echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> /etc/skel/.bashrc
elif [[ $OS == "Ubuntu" ]]; then 
    echo "# " >> ~/.bashrc
    echo "alias useradd='adduser'" >> ~/.bashrc
    mv /etc/default/{useradd,useradd.bk}
    echo """# useradd defaults file
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/sh
SKEL=/etc/skel
CREATE_MAIL_SPOOL=yes""" > /etc/default/useradd

    mkdir -p /etc/skel
    curl -o /etc/skel/.bashrc  https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/config/"$OS".bashrc > /dev/null 2>&1
    curl -o /etc/skel/.profile  https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/config/"$OS".profile > /dev/null 2>&1
fi 

# Config rsyslog 
echo "Config rsyslog"
mv /etc/rsyslog.{conf,conf.bk}
curl -o /etc/rsyslog.conf https://raw.githubusercontent.com/nhanhoadocs/ghichep-cmdlog/master/config/"$OS_VER"_rsyslog.cnf > /dev/null 2>&1
systemctl restart rsyslog.service > /dev/null 2>&1 || service rsyslog restart > /dev/null 2>&1
source ~/.bashrc

echo "DONE - This task need be LOGOUT & LOGIN again to start logging cmd"
exit