#! /bin/bash

date
cd /root

# get user's email address
echo What is your email address?
read email

# update repositories
apt update

# set up a generic domain name for this instance
vhost=`curl https://dgl-dns-wzwqo2bdfa-uw.a.run.app/`

# install required packages
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install
apt install -y mariadb-server
apt install -y nginx
sudo apt install phpmyadmin snapd php-fpm php-mysql
apt install -y snapd
snap install core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# open firewall for Webmin port
gcloud compute firewall-rules create default-allow-mariadb --action allow --target-tags mariadb-server --source-ranges 0.0.0.0/0 --rules tcp:3306

# create virtual host
pushd /etc/apache2/sites-available
cat <<EOF >${vhost}.conf
<VirtualHost *:80>
    DocumentRoot "/var/www/wordpress"
    ServerName ${vhost}
    <Directory "/var/www/wordpress">
        Options None
        Require all granted
    </Directory>
</VirtualHost>
EOF

a2ensite ${vhost}.conf
systemctl reload apache2
popd

# provision TLS certificate
certbot --apache -n --no-eff-email --agree-tos -m $email -d ${vhost}

# create wordpress database, user, and permissions
mariadb -e 'create database wp1;'
mariadbpw=`tr -dc A-Za-z0-9 </dev/urandom | head -c 20`
mariadb -e "create user user1@localhost identified by '$mariadbpw';"
mariadb -e 'grant all privileges on wp1.* to user1@localhost;'

# output summary information
echo ========== IMPORTANT INFORMATION ==========
echo Webmin URL: https://${vhost}:10000
echo Webmin username: root
echo Webmin password: $rootpw
echo WordPress URL: https://${vhost}
echo WordPress database: wp1
echo WordPress database username: user1
echo WordPress database password: $mariadbpw
echo WordPress database host: localhost
echo ===========================================

date
