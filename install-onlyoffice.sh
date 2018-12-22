############################################################
### Onlyoffice v.5.1 based on Ubuntu 18.04.x LTS         ###
### Version 2.1 - December 22nd 2018                     ###
############################################################
#!/bin/bash
apt update && apt upgrade -y && apt install software-properties-common zip unzip screen curl ffmpeg libfile-fcntllock-perl -y
add-apt-repository ppa:certbot/certbot -y && apt update && apt upgrade -y && apt install letsencrypt -y && apt install python-certbot-nginx -y
apt install gcc g++ make -y
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
     echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt update && apt install yarn -y
curl -sL https://deb.nodesource.com/setup_6.x | sudo bash -
apt install postgresql -y
echo -n "Enter your database password then press [ENTER]: "
read db_password
sudo -i -u postgres psql -c "CREATE DATABASE onlyoffice;"
sudo -i -u postgres psql -c "CREATE USER onlyoffice WITH password '$db_password';"
sudo -i -u postgres psql -c "GRANT ALL privileges ON DATABASE onlyoffice TO onlyoffice;"
apt install redis-server -y
apt install rabbitmq-server -y
apt install npm nginx-extras -y
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
echo "deb http://download.onlyoffice.com/repo/debian squeeze main" | sudo tee /etc/apt/sources.list.d/onlyoffice.list
apt update && apt install onlyoffice-documentserver -y
/usr/sbin/service nginx stop 
mv /etc/nginx/conf.d/onlyoffice-documentserver.conf /etc/nginx/conf.d/onlyoffice-documentserver.conf.bak
cat <<EOF >> /etc/nginx/conf.d/onlyoffice-documentserver.conf
include /etc/nginx/includes/onlyoffice-http.conf;
server {
  listen 0.0.0.0:80;
  listen [::]:80 default_server;
  server_name _;
  server_tokens off;
  root /nowhere;
  rewrite ^ https://$host$request_uri? permanent;
}
server {
  listen 127.0.0.1:80;
  listen [::1]:80;
  server_name localhost;
  server_tokens off;
  include /etc/nginx/includes/onlyoffice-documentserver-common.conf;
  include /etc/nginx/includes/onlyoffice-documentserver-docservice.conf;
}
server {
  listen 0.0.0.0:443 ssl;
  listen [::]:443 ssl default_server;
  server_tokens off;
  root /usr/share/nginx/html;
  ssl on;
  ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
  ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
  ssl_verify_client off;
  ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_prefer_server_ciphers   on;
  add_header Strict-Transport-Security max-age=31536000;
  add_header X-Content-Type-Options nosniff;
  # ssl_stapling on;
  # ssl_stapling_verify on;
  # ssl_trusted_certificate /etc/nginx/ssl/stapling.trusted.crt;
  resolver 208.67.222.222 valid=300s; # Can be changed to your DNS if desired
  resolver_timeout 10s;
  ## [Optional] Generate a stronger DHE parameter:
  ##   cd /etc/ssl/certs
  ##   sudo openssl dhparam -out dhparam.pem 4096
  # ssl_dhparam /etc/ssl/certs/dhparam.pem;
  include /etc/nginx/includes/onlyoffice-documentserver-*.conf;
}
EOF
mkdir /var/www/letsencrypt
chown -R www-data /var/www/letsencrypt
/usr/sbin/service nginx restart 
sudo ufw allow 'nginx full'
sudo ufw enable
exit 0
