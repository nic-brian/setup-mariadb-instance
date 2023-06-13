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
DEBIAN_FRONTEND=noninteractive apt install -yq phpmyadmin snapd php-fpm php-mysql
apt install -y snapd
snap install core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# open firewall for MariaDB port
gcloud compute firewall-rules create default-allow-mariadb --action allow --target-tags mariadb-server --source-ranges 0.0.0.0/0 --rules tcp:3306

# create virtual host
pushd /etc/nginx/sites-available
cat <<EOF >${vhost}.conf
server {
       listen 80;
       listen [::]:80;

       server_name ${vhost};

       root /var/www/html;
       index index.php index.html index.htm index.nginx-debian.html;

       location / {
               try_files \$uri \$uri/ =404;
       }
       
       location ~ \.php$ {
               include snippets/fastcgi-php.conf;
               fastcgi_pass unix:/run/php/php7.4-fpm.sock;
       }
}
EOF

ln -s /etc/nginx/sites-available/${vhost}.conf /etc/nginx/sites-enabled/${vhost}.conf
systemctl reload nginx
popd

# provision TLS certificate
certbot --nginx -n --no-eff-email --agree-tos -m $email -d ${vhost}

# fix MariaDB configuration
pushd /etc/mysql
cp /etc/letsencrypt/live/${vhost}/chain.pem cacert.pem
cp /etc/letsencrypt/live/${vhost}/cert.pem server-cert.pem
cp /etc/letsencrypt/live/${vhost}/privkey.pem server-key.pem
chown mysql:mysql server-key.pem
sed -i  /bind-address/s/bind-address/\#bind-address/ 50-server.cnf
sed -i  /ssl-ca/s/\#ssl-ca/ssl-ca/ 50-server.cnf
sed -i  /ssl-cert/s/\#ssl-cert/ssl-cert/ 50-server.cnf
sed -i  /ssl-key/s/\#ssl-key/ssl-key/ 50-server.cnf
sed -i  /require-secure-transport/s/\#require-secure-transport/\require-secure-transport/ 50-server.cnf
systemctl restarat mariadb
popd

# create menagerie database
pushd /tmp
wget https://downloads.mysql.com/docs/menagerie-db.tar.gz
tar zxf menagerie-db.tar.gz
cd menagerie-db
mariadb -e 'create database menagerie;'
mariadb -e 'use menagerie; source cr_pet_tbl.sql'
mariadb -e "use menagerie; load data local infile 'pet.txt' into table pet;"
mariadb -e 'use menagerie; source ins_puff_rec.sql'
mariadb -e 'use menagerie; source cr_event_tbl.sql'
mariadb -e "use menagerie; load data local infile 'event.txt' into table event;"
popd


# create database user and permissions
mariadbpw=`tr -dc A-Za-z0-9 </dev/urandom | head -c 20`
mariadb -e "create user admin@'%' identified by '$mariadbpw';"
mariadb -e "grant all privileges on *.* to admin@'%';"

# create phpmyadmin URL
pushd /var/www/html
phpmyadminshuffle=`tr -dc A-Za-z0-9 </dev/urandom | head -c 20`
ln -s ${phpmyadminshuffle}phpmyadmin /usr/share/phpmyadmin

# output summary information
echo ========== IMPORTANT INFORMATION ==========
echo MariaDB username: admin
echo MariaDB password: $mariadbpw
echo phpMyAdmin URL: https://${vhost}/${phpmyadminshuffle}phpmyadmin
echo ===========================================

date
