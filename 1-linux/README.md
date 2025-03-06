# DevOps Exercise 1: Linux essentials

## General mentions
Before solving these tasks I updated the repositories and upgraded the apps using

```sh
apt update && apt upgrade -y
```

## Lookup the public IP of `tremend.com`

### Installing `dig`
For solving this task I decided to use `dig`. In order to use `dig`, the `dnsutils` package must be installed first by running

```sh
apt install dnsutils
```

### General `dig` output

In order to get the public IP(s) of the Tremend site we can simply use `dig tremend.com`. The output of this command is

```sh
; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> tremend.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 30560
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;tremend.com.                   IN      A

;; ANSWER SECTION:
tremend.com.            52      IN      A       34.255.35.46
tremend.com.            52      IN      A       34.248.35.216
tremend.com.            52      IN      A       176.34.175.11

;; Query time: 0 msec
;; SERVER: 192.168.65.7#53(192.168.65.7) (UDP)
;; WHEN: Wed Mar 05 12:13:34 UTC 2025
;; MSG SIZE  rcvd: 110
```

In here we can see that the `tremend.com` domain has 3 `A` DNS entries.

### "Machine friendly" `dig` output

While the output above does the job we might need a more parsable output. Here comes to the rescue `+short`. By adding `+short` to the previous `dig` command we can get a more standard output:

```sh
$ dig +short tremend.com
```

```sh
34.255.35.46
34.248.35.216
176.34.175.11
```

## Map IP address 8.8.8.8 to hostname google-dns

In order to achieve this we can simply append the IP address and the desired hostname to `/etc/hosts`:

```sh
echo "8.8.8.8 google-dns" >> /etc/hosts

cat /etc/hosts
```

```sh
127.0.0.1       localhost
::1     localhost ip6-localhost ip6--loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.17.0.2      43a0b04d4673
8.8.8.8 google-dns
```

## Check if the DNS Port is open for Google DNS

In order to do this I will be using `nmap`. We have to first install it as it's not installed by default and then we can scan for port `53` like this:

```sh
apt install nmap
nmap -sU -p 53 google-dns
```

```
Starting Nmap 7.94SVN ( https://nmap.org ) at 2025-03-06 05:32 EET
Nmap scan report for google-dns (8.8.8.8)
Host is up (0.032s latency).

PORT   STATE SERVICE
53/udp open  domain

Nmap done: 1 IP address (1 host up) scanned in 0.49 seconds
```

## Modify the System to Use Google’s Public DNS 

### Change the nameserver to 8.8.8.8 instead of the default local configuration

In order to achieve this we can simply append `nameserver` accompanied by the IP address to `/etc/resolv.conf`:

```sh
echo "nameserver 8.8.8.8" > /etc/resolv.conf

cat /etc/hosts
```

```
nameserver 8.8.8.8
```

#### ⚠️ 🤓 Mention
Due to the `resolv.conf` specification ([see here](https://man7.org/linux/man-pages/man5/resolv.conf.5.html)) we **cannot** use the previously declared hostname `google-dns` in this file.


### Perform another public IP lookup for tremend.com and compare the results

```sh
dig +short tremend.com
```

```sh
176.34.175.11
34.255.35.46
34.248.35.216
```

As we can see, other than the order of the entries the output is the same.

#### ⚠️ 🤓 Mention
I tried to use other DNS providers such as [Quad9](https://quad9.net) and [Cloudflare](https://cloudflare.com) but the results were pretty much the same. I tried later during the day though and I got a different set of IP addresses.

```sh
dig +short tremend.com @9.9.9.9
```

```sh
52.18.209.114 # new IP address
176.34.175.11
34.248.35.216
```

## Install and verify that Nginx service is running 

To achieve this `nginx` can be simply installed from the Ubuntu repos and managed through the `service` command as `systemd` and subsequently `systemctl` are not available on the Docker version of Ubuntu.

```sh
apt install nginx

service nginx status
```

```sh
 * nginx is not running
```

```sh
service nginx start
```

```sh
 * Starting nginx nginx                                                                                                         [ OK ]
```

```sh
service nginx status
```

```sh
 * nginx is running
```

## Find the listening port for nginx
In order to find the listening port for the `nginx` service we can use `ss` like so:

```sh
ss -tulnp | grep nginx
```

```
tcp       LISTEN     0          511                  0.0.0.0:80                0.0.0.0:*       users:(("nginx",pid=1399,fd=41))
tcp       LISTEN     0          511                     [::]:80                   [::]:*       users:(("nginx",pid=1399,fd=42))
```

In here we can see that `nginx` can be reached at port 80 over IPv4 and IPv6.

## 🎁 Bonus Exercises

### Change the Nginx Listening port to 8080 
In order to achieve this we must edit the default configuration available at `/etc/nginx/sites-available/default`. We have to change the ports from both listen statements in the server block to the desired port, `8080`, and then restart the service through `service nginx reload`.

This is how the file will look after the modifications:

```java
server {
        listen 8080 default_server; // changed port from 80
        listen [::]:8080 default_server; // changed port from 80

        ... # other statements
}
```

In order to make sure we have not broken the configuration file we can run `service nginx configtest` and *hope* it does not fail.

Afterwards we can restart the service and test on what ports is `nginx` listening:

```sh
service nginx reload

ss -tulnp | grep nginx
```

```sh
Netid     State      Recv-Q     Send-Q         Local Address:Port         Peer Address:Port    Process
tcp       LISTEN     0          511                  0.0.0.0:8080              0.0.0.0:*
tcp       LISTEN     0          511                     [::]:8080                 [::]:*
```

### Modify the default HTML page title

The same `/etc/nginx/sites-available/default` tells us that the site is located at `/var/www/html` through the `root` directive. (`root /var/www/html`). Listing the file contents in that folders renders one file, `index.nginx-debian.html`. By editing the heading in this file we can achieve the wanted result.

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<!-- edited section -->
<h1>I have completed the Linux part of the Tremend DevOps internship project</h1>
<!-- edited section -->
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

![Edited nginx page screenshot](img/1-nginx-edited-page.png)