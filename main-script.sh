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
