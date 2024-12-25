#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Prompt user for public IP and domain/subdomain
read -p "Enter the public IP address of the server: " PUBLIC_IP
read -p "Enter the domain or subdomain to be used (e.g., example.com): " DOMAIN_NAME

# Update and install required packages
apt update -y && apt upgrade -y
apt install -y software-properties-common

# Install required dependencies
dependencies=(
  certbot
  nginx
  apache2
  libapache2-mod-ssl
  fail2ban
  wget
  geoipupdate
  openvpn
  ufw
  nano
)

for package in "${dependencies[@]}"; do
  if ! dpkg -l | grep -q "^ii  $package"; then
    echo "Installing missing dependency: $package"
    apt install -y $package
  else
    echo "$package is already installed."
  fi
done

# Configure Nginx for the domain
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN_NAME"
NGINX_LINK="/etc/nginx/sites-enabled/$DOMAIN_NAME"

cat <<EOL > $NGINX_CONF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:8080; # Adjust if necessary
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

ln -s $NGINX_CONF $NGINX_LINK
systemctl restart nginx

# Configure Apache for the domain
APACHE_CONF="/etc/apache2/sites-available/$DOMAIN_NAME.conf"

cat <<EOL > $APACHE_CONF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>

    ErrorLog /var/log/apache2/${DOMAIN_NAME}_error.log
    CustomLog /var/log/apache2/${DOMAIN_NAME}_access.log combined
</VirtualHost>
EOL

a2ensite $DOMAIN_NAME.conf
a2enmod ssl
systemctl restart apache2

# Obtain SSL certificates for Nginx and Apache
certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME
certbot --apache -d $DOMAIN_NAME --non-interactive --agree-tos -m admin@$DOMAIN_NAME

# Save SSL certificates to the user's home directory
LOGGED_USER=$(logname)
mkdir -p /home/$LOGGED_USER/ssl_backups
cp -r /etc/letsencrypt /home/$LOGGED_USER/ssl_backups/
chown -R $LOGGED_USER:$LOGGED_USER /home/$LOGGED_USER/ssl_backups

# Update GeoIP database
geoipupdate

# Configure OpenVPN
OPENVPN_CONF="/etc/openvpn/server/${DOMAIN_NAME}.conf"

cat <<EOL > $OPENVPN_CONF
port 1194
proto udp
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
tls-auth /etc/openvpn/easy-rsa/pki/ta.key 0
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3
EOL
systemctl enable openvpn-server@${DOMAIN_NAME} --now

# Configure SSH banner
SSH_BANNER="/etc/ssh/banner.txt"

cat <<EOL > $SSH_BANNER
========================================
Welcome to $DOMAIN_NAME
========================================
Unauthorized access is prohibited.
All activities are monitored and logged.
========================================
EOL

sed -i 's/^#Banner.*/Banner $SSH_BANNER/' /etc/ssh/sshd_config
systemctl restart sshd

# Configure UFW
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw allow 1194/udp
ufw enable

# Configure Fail2Ban
FAIL2BAN_JAIL_CONF="/etc/fail2ban/jail.local"

cat <<EOL > $FAIL2BAN_JAIL_CONF
[DEFAULT]
bantime = -1
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOL

systemctl enable fail2ban --now

# Set up automatic SSL certificate renewal
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet && systemctl reload nginx && systemctl reload apache2") | crontab -

# Print success message
echo "Server setup has been successfully configured for $DOMAIN_NAME on Debian with firewall rules, GeoIP, and Fail2Ban configured!"
