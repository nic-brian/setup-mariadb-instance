# Setup MariaDB Instance

Sets up MariaDB, Nginx, phpMyAdmin on a Debian Google Cloud Compute Engine VM.

Create a Debian VM using Google Cloud Console. Be sure to change the following settings.

## Firewall

Allow HTTP and HTTPS traffic.

## Final configuration

After the VM starts, use SSH to connect and get a root shell as follows.


```bash
sudo -s
```

Once you have root shell, you can copy and paste the commands below to configure Webmin and WordPress.


```bash
cd /root
curl -o setup-mariadb-instance.sh https://raw.githubusercontent.com/nic-brian/setup-mariadb-instance/main/main-script.sh
bash setup-mariadb-instance.sh
```
