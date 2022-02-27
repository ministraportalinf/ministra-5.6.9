#!/bin/bash

VER="5.6.9"
PRODUCT="Ministra Portal"
PORTAL_WAN="http://`wget -qO- http://ipecho.net/plain | xargs echo`/stalker_portal"
PORTAL_LAN="http://`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`/stalker_portal"
SUPPORTED="Ubuntu 16.04.7 LTS Server"
TIME_ZONE="America/Los_Angeles" #


mysql_root_pass="st@lk3r"
repo="http://servepc.com/stalker"


echo "Updateing system . . . "
sleep 2
apt-get update -y
apt-get upgrade -y


# SET LOCALE TO UTF-8
function setLocale {
 echo "Setting locales..."
 locale-gen en_US.UTF-8  >> /dev/null 2>&1
 export LANG="en_US.UTF-8" >> /dev/null 2>&1
 echo "Done."
}

# TWEAK SYSTEM VALUES
function tweakSystem {
 echo -ne "Tweaking system..."
 echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
 echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
 echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
 echo "fs.file-max = 327680" >> /etc/sysctl.conf
 echo "kern.maxfiles = 327680" >> /etc/sysctl.conf
 echo "kern.maxfilesperproc = 327680" >> /etc/sysctl.conf
 echo "kernel.core_uses_pid = 1" >> /etc/sysctl.conf
 echo "kernel.core_pattern = /var/crash/core-%e-%s-%u-%g-%p-%t" >> /etc/sysctl.conf
 echo "fs.suid_dumpable = 2" >> /etc/sysctl.conf
 sysctl -p >> /dev/null 2>&1
 echo "Done."
}

setLocale;
tweakSystem;

sleep 3

echo "Installing libs . . ."
sleep 3
apt-get install nginx nginx-extras -y
/etc/init.d/nginx stop
sleep 1
apt-get install apache2 -y
/etc/init.d/apache2 stop
sleep 1

apt-get -y install php-mcrypt php-mbstring memcached php-memcache php php-mysql php-pear nodejs libapache2-mod-php php-curl php-imagick php-sqlite3 unzip
sleep 2

echo "Installing phing . . ."
sleep 3
pear channel-discover pear.phing.info
pear install -Z phing/phing
wget -q http://archive.ubuntu.com/ubuntu/pool/universe/p/phing/phing_2.16.1-1_all.deb
dpkg -i phing_2.16.1-1_all.deb

echo "installing npm 2.5.11 . . . "
sleep 3
# Install NPM  2.5.11
apt-get install npm -y
npm config set strict-ssl false
npm install -g npm@2.15.11
ln -s /usr/bin/nodejs /usr/bin/node

echo "Configure timezone . . . "
sleep 3
echo "$TIME_ZONE" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata


echo "Installing mysql server . . . "
sleep 3
export DEBIAN_FRONTEND="noninteractive"
echo "mysql-server mysql-server/root_password password $mysql_root_pass" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysql_root_pass" | sudo debconf-set-selections
apt-get install -y mysql-server
sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
mysql -uroot -p$mysql_root_pass -e "USE mysql; UPDATE user SET Host='%' WHERE User='root' AND Host='localhost'; DELETE FROM user WHERE Host != '%' AND User='root'; FLUSH PRIVILEGES;"
mysql -uroot -p$mysql_root_pass -e "create database stalker_db"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON stalker_db.* TO stalker@localhost IDENTIFIED BY '1' WITH GRANT OPTION;"
echo 'sql_mode=""' >> /etc/mysql/mysql.conf.d/mysqld.cnf
#echo "max_allowed_packet = 32M" >> /etc/mysql/my.cnf
service mysql restart

echo "Installing " $PRODUCT $VER " . . . "
sleep 3
cd /var/www/html/
wget http://download.ministra.com/downloads/159934057961c4dfe9153ee02d7e3fb1/ministra-5.6.9.zip
unzip ministra-5.6.9.zip
rm -rf *.zip

echo "short_open_tag = On" >> /etc/php/7.0/apache2/php.ini
phpenmod mcrypt
a2enmod rewrite
apt-get purge libapache2-mod-php5filter > /dev/null


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
rm -rf /var/www/html/stalker_portal/admin/vendor
cd /var/www/html/stalker_portal/admin
wget https://dev.d-dtox.com/stalker/vendor.tar
tar -xvf vendor.tar
sleep 1


# Fix Smart Launcher Applications
mkdir /var/www/.npm
chmod 777 /var/www/.npm

#Patch Composer
cd /var/www/html/stalker_portal
wget $repo/composer_version_1.9.1.patch
patch -p1 < composer_version_1.9.1.patch

cd /var/www/html/stalker_portal/server
wget -O custom.ini $repo/custom.ini
cd

cd /var/www/html/stalker_portal/deploy
sudo phing
sleep 1

echo ""
echo "-----------------------------------------------------------------------"
echo ""
echo " Install Complete !"
echo ""
echo " Default username is: admin"
echo " Default password is: 1"
echo ""
echo " PORTAL WAN : $PORTAL_WAN"
echo " PORTAL LAN : $PORTAL_LAN"
echo " Mysql User : root"
echo " MySQL Pass : $mysql_root_pass"
echo ""
echo " Change admin panel password :"
echo " mysql -u root -p"
echo " use stalker_db;"
echo " update administrators set pass=MD5('new_password_here') where login='admin';"
echo " quit;"
echo " Logout from web panel and Login with new password."
echo ""
echo "-----------------------------------------------------------------------"
echo ""
