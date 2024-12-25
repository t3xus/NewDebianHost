# Debian Host Setup Script

![Static Badge](https://img.shields.io/badge/Author-Jgooch-1F4D37)
![Static Badge](https://img.shields.io/badge/Platform-Debian-blue)

## Overview

This script automates the setup and configuration of a new Debian host. It includes:

- Installation and configuration of required services and dependencies.
- Web server setup (Nginx and Apache).
- SSL certificate provisioning using Let's Encrypt.
- Firewall configuration.
- OpenVPN setup.
- Fail2Ban for SSH brute force protection.
- GeoIP database updates.
- Automatic renewal of SSL certificates.

## Features

| Feature                  | Details                                           |
|--------------------------|---------------------------------------------------|
| **Platform**             | Debian                                            |
| **Dependencies**         | `apt`, `certbot`, `nginx`, `apache2`, `fail2ban`, etc. |
| **SSL Certificate**      | Provisioning via Let's Encrypt                   |
| **Firewall**             | Configures UFW with custom rules                 |
| **VPN**                  | OpenVPN setup and configuration                  |
| **Brute Force Protection** | Fail2Ban for SSH                                |
| **GeoIP Database**       | Updates and installation                         |

## Requirements

- Debian 10 or later.
- Root privileges.
- A registered domain name.
- Public IP address of the server.

## Usage

### Run the Script:
```bash
sudo ./DebianHostSetup.sh
```

## What the Script Does

### **1. Installs Required Dependencies**
- Ensures all necessary packages are installed, including:
  - `certbot`
  - `nginx`
  - `apache2`
  - `fail2ban`
  - `geoipupdate`
  - `openvpn`

### **2. Configures Web Servers**
- **Nginx**: Configures for the provided domain on port 80 and port 443.
- **Apache**: Creates a virtual host configuration for the domain.

### **3. Provisions SSL Certificates**
- Uses Certbot to generate SSL certificates for the domain.
- Configures SSL for both Nginx and Apache.

### **4. Firewall Configuration**
- Opens necessary ports using UFW:
  - HTTP (80), HTTPS (443), SSH (22).
  - OpenVPN (1194), NTP (123).
  - SIP (5060-5061), RDP (3389), VNC (5900-5901).

### **5. Fail2Ban Configuration**
- Protects SSH from brute force attacks with permanent bans.
- Customizes Fail2Ban settings for Debian.

### **6. GeoIP Database Update**
- Downloads and installs the latest GeoIP database for location-based restrictions.

### **7. SSL Certificate Renewal**
- Configures a cron job to automatically renew SSL certificates.

## Sample Output

Upon successful execution, the script outputs:
```
DebianHostSetup setup has been successfully configured for <your-domain> with firewall rules, GeoIP, and Fail2Ban!
```

## License

This script is distributed under the MIT License. See `LICENSE` for more information.
