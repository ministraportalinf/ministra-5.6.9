#!/bin/bash


# Color schema

red='\033[01;31m'
blue='\033[01;34m'
green='\033[01;32m'
norm='\033[00m'

# Temporary colors
RED="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
CYAN="$(tput setaf 6)"
NORMAL="$(tput sgr0)"

# smallLoader colors

CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CPURPLE="${CSI}1;35m"
CCYAN="${CSI}1;36m"
CBROWN="${CSI}0;33m"

# smallLoader

smallLoader() {
    echo ""
    echo ""
    echo -ne '[ + + +             ] 3s \r'
    sleep 1
    echo -ne '[ + + + + + +       ] 2s \r'
    sleep 1
    echo -ne '[ + + + + + + + + + ] 1s \r'
    sleep 1
    echo -ne '[ + + + + + + + + + ] Press [Enter] to continue... \r'
    echo -ne '\n'

    read -r
}



VER="5.6.9"
PRODUCT="Ministra Portal"
WAN="http://`wget -qO- http://ipecho.net/plain | xargs echo`/stalker_portal"
LAN="http://`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`/stalker_portal"
PHPMA="http://`wget -qO- http://ipecho.net/plain | xargs echo`/phpmyadmin"
SUPPORTED="Ubuntu 20.04 LTS Server"
TIME_ZONE="America/Los_Angeles" 

skipyesno=0

# Ask a yes or no question
# if $skipyesno is 1, always Y
# if NONINTERACTIVE environment variable is 1, always Y
yesno () {
  # XXX skipyesno is a global set in the calling script
  # shellcheck disable=SC2154
  if [ "$skipyesno" = "1" ]; then
    return 0
  fi
  if [ "$NONINTERACTIVE" = "1" ]; then
    return 0
  fi
  while read -r line; do
    case $line in
      y|Y|Yes|YES|yes|yES|yEs|YeS|yeS) return 0
      ;;
      n|N|No|NO|no|nO) return 1
      ;;
      *)
      printf "\n${YELLOW}Please enter ${CYAN}[y]${YELLOW} or ${CYAN}[n]${YELLOW}:${NORMAL} "
      ;;
    esac
  done
}
clear
install_msg() {
cat <<EOF
  Welcome to the ${RED}$PRODUCT${NORMAL} installer, version ${RED}$VER${NORMAL}
EOF


  printf " Continue? (y/n) "
  if ! yesno; then
    exit
  fi
}

if [ "$skipyesno" -ne 1 ] && [ -z "$setup_only" ]; then
  install_msg
fi


# Setup mysql password
mysql_root_pass="st@lk3r"
repo="http://servepc.com/stalker"

# SET LOCALE TO UTF-8
function setLocale {
	echo "Setting locales..."
	locale-gen en_US.UTF-8  >> /dev/null 2>&1
	export LANG="en_US.UTF-8" >> /dev/null 2>&1
	echo "Done."
}


setLocale;

sleep 3

# Install Necessary support Ubuntu 20
sudo apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
sudo apt-get update
#Update and Upgrade
echo "Updating and Upgrading"
apt-get update && apt-get upgrade -y

# Setting for the new UTF-8 terminal support in Lion
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# Installing pakg
apt-get install -y dialog net-tools wget git curl nano sudo unzip sl lolcat software-properties-common aview
chmod +x /tmp/tv/lab/*
# Installing Apache & Nginx
echo "Installing libs . . ."
sleep 3
apt-get install nginx nginx-extras -y
/etc/init.d/nginx stop
sleep 1
apt-get install apache2 -y
/etc/init.d/apache2 stop
sleep 1

# Install Necessary services & packets
apt-get -y install php7.0-dev php7.0-mcrypt php7.0-intl php7.0-mbstring php7.0-zip memcached php7.0-memcache php7.0 php7.0-xml php7.0-gettext php7.0-soap php7.0-mysql php7.0-geoip php-pear nodejs libapache2-mod-php php7.0-curl php7.0-imagick php7.0-sqlite3 unzip

#Change php version
update-alternatives --set php /usr/bin/php7.0

sleep 2

# Installing phing
echo "Installing phing . . ."
sleep 3
pear channel-discover pear.phing.info
pear install phing/phing-2.15.0

# Installing NPM 2.5.11
echo "installing npm 2.5.11 . . . "
sleep 3
apt-get install npm -y
npm config set strict-ssl false
npm install -g npm@2.15.11
ln -s /usr/bin/nodejs /usr/bin/node

# Set the Server Timezone to CST
echo "Configure timezone . . . "
sleep 3
echo "$TIME_ZONE" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Install MySQL Server in a Non-Interactive mode. Default root password will be "st@lk3r"

echo "Installing mysql server . . . "
sleep 3
export DEBIAN_FRONTEND="noninteractive"
echo "mysql-server mysql-server/root_password password $mysql_root_pass" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysql_root_pass" | sudo debconf-set-selections
apt-get install -y mysql-server
sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
mysql -uroot -p$mysql_root_pass -e "USE mysql; UPDATE user SET Host='%' WHERE User='root' AND Host='localhost'; DELETE FROM user WHERE Host != '%' AND User='root'; FLUSH PRIVILEGES;"
mysql -uroot -p$mysql_root_pass -e "create database stalker_db;"
mysql -uroot -p$mysql_root_pass -e "ALTER USER root IDENTIFIED WITH mysql_native_password BY '"$mysql_root_pass"';"
mysql -uroot -p$mysql_root_pass -e "CREATE USER stalker IDENTIFIED BY '1';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL ON *.* TO stalker WITH GRANT OPTION;"
mysql -ustalker -p1 -e "ALTER USER stalker IDENTIFIED WITH mysql_native_password BY '1';"


echo 'sql_mode=""' >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo 'extension=geoip.so' >> /etc/php/7.0/apache2/php.ini
echo 'default_authentication_plugin=mysql_native_password' >> /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart

# Installing Ministra portal
echo "Installing " $PRODUCT $VER " . . . "
sleep 3
cd /var/www/html/
wget http://download.ministra.com/downloads/159934057961c4dfe9153ee02d7e3fb1/ministra-5.6.9.zip
unzip ministra-5.6.9.zip
rm -rf *.zip

# Settup php
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.0/apache2/php.ini
ln -s /etc/php/7.0/mods-available/mcrypt.ini /etc/php/8.0/mods-available/
phpenmod mcrypt
a2enmod rewrite
apt-get purge libapache2-mod-php5filter > /dev/null

# Install phpmyadmin
cd /var/www/html/ > /dev/null
wget https://files.phpmyadmin.net/phpMyAdmin/4.9.1/phpMyAdmin-4.9.1-all-languages.zip > /dev/null
unzip phpMyAdmin-4.9.1-all-languages.zip > /dev/null
mv phpMyAdmin-4.9.1-all-languages phpmyadmin > /dev/null

sleep 1

# Setup Configs
cd /etc/apache2/sites-enabled/
rm -rf *
wget $repo/000-default.conf
cd /etc/apache2/
rm -rf ports.conf
wget $repo/ports.conf
cd /etc/nginx/sites-available/
rm -rf default
wget $repo/default
/etc/init.d/apache2 restart
/etc/init.d/nginx restart
sleep 1
#rm -rf /var/www/html/stalker_portal/admin/vendor
#cd /var/www/html/stalker_portal/admin
#wget https://dev.d-dtox.com/stalker/vendor.tar
#tar -xvf vendor.tar
#sleep 1


# Fix Smart Launcher Applications
mkdir /var/www/.npm
chmod 777 /var/www/.npm

#Patch Composer
cd /var/www/html/stalker_portal
wget $repo/composer_version_1.9.1.patch
patch -p1 < composer_version_1.9.1.patch

# Download custom.ini
cd /var/www/html/stalker_portal/server
wget -O custom.ini $repo/custom.ini
cd

# Phing :)
cd /var/www/html/stalker_portal/deploy
sudo phing
sleep 1
smallLoader

echo ""
echo -e "${CCYAN}-----------------------------------------------------------------------${CEND}"
echo ""
echo -e "${CCYAN}[ Install Complete Default username is: ${CRED}admin${CEND} ${CCYAN}Default password is: ${CRED}1${CEND} ${CCYAN}: ]${CEND}"
echo ""
echo -e "IP WAN       : ${CGREEN}${WAN}${CEND}"
echo -e "Local IP     : ${CGREEN}${LAN}${CEND}"
echo -e "MySQL Pass   : ${CGREEN}${mysql_root_pass}${CEND}"
echo -e "PHPMyadmin   : ${CGREEN}${PHPMA}${CEND}"
echo ""
echo -e "${CCYAN}-----------------------------------------------------------------------${CEND}"
echo ""

rm -rf /tmp/tv >> /dev/null 2>&1
