
# Home server

This repo contains documentation of my current setup for my home server running Ubuntu Server 22.04 on an Intel Nuc.

Services include

* Plex Media Server
* Vaultwarden
* NextCloud
* Radarr, Sonarr, Prowlarr, Overseerr & qBittorrent
* Home Assistant, Mosquitto, Zigbee2MQTT & Cloudflared
* Pi-hole & Unbound
* Azure Self Hosted Build Agent 
* Tailscale, Gluetun
* Portainer
* Watchtower & Glances
* Nginx Proxy Manager

Everything is containerized in Docker, and it assumes that the local subnet is 192.168.2.0/24, with the gateway located at 192.168.2.254 and the network interface named eno1.

# Install docker

Install docker
https://docs.docker.com/engine/install/ubuntu/


# Installing containers apps 

The `apps` folder can be copied to `~/apps`

    ~
    ├── data          
    ├── apps                    
    │   ├── azure-build-agent          
    │   ├── home-assistant          
    │   ├── monitor             
    │   └── ...                
    └── ...


In each folder in `apps` after providing the `.env` file you can run `docker compose up -d` to bring them to life. 

```bash
docker compose up -d
docker compose up -d --force-recreate --build
```

Pihole, Home Assistant, Overseerr & Glances needs to have their IP addresses setup first (next chapter).

# Add extra IP addresses to Host

The host uses Netplan to keep additional static addresses on `eno1`, alongside its main DHCP address (currently `192.168.2.21`). Exclude `192.168.2.239` through `192.168.2.253` from the router's DHCP pool so they cannot be assigned to other devices. The gateway remains `192.168.2.254`.

| IP            | App                 | Domain       |
| ------------- | ------------------- | ------------ |
| 192.168.2.253 | Pi-Hole             | pihole.local |
| 192.168.2.252 | Unbound             |              |
| 192.168.2.251 | Home Assistant      | home.local   |
| 192.168.2.250 | Overseerr           | stream.local |
| 192.168.2.249 | Glances             | stats.local  |
| 192.168.2.248 | Stirling PDF        | pdf.local    |
| 192.168.2.247 | Bar Assistant       | bar.local    |
| 192.168.2.246 | NextCloud           | cloud.local  |
| 192.168.2.245 | Nginx Proxy Manager | npm.local:81 |

You can add these local DNS records in pi-hole.


### Configure persistent IP addresses

Declare these addresses in Netplan so they are restored after networking restarts and reboots. The previous `extra-ips.service` only added runtime addresses at boot. During the October 16, 2026 daily APT upgrade, `systemd-networkd` restarted and the extra addresses disappeared; rerunning the old service restored access. The Netplan setup below was also verified after a reboot.

1. After Ubuntu installation, keep the existing Netplan files and back them up:

```bash
sudo cp -a /etc/netplan "/root/netplan-backup-$(date +%Y%m%d-%H%M%S)"
sudo netplan get ethernets
```

Confirm that the LAN interface is `eno1`. The configuration below keeps DHCP enabled on that interface and adds all 15 addresses used by the existing host setup. Existing settings for other interfaces remain in their original files.

2. Create `/etc/netplan/90-service-addresses.yaml` with restricted permissions. On an existing installation, inspect any file already at this path before replacing it.

```bash
sudo install -m 600 /dev/null /etc/netplan/90-service-addresses.yaml
sudo tee /etc/netplan/90-service-addresses.yaml >/dev/null <<'EOF'
network:
  version: 2
  ethernets:
    eno1:
      dhcp4: true
      addresses:
        - 192.168.2.253/24
        - 192.168.2.252/24
        - 192.168.2.251/24
        - 192.168.2.250/24
        - 192.168.2.249/24
        - 192.168.2.248/24
        - 192.168.2.247/24
        - 192.168.2.246/24
        - 192.168.2.245/24
        - 192.168.2.244/24
        - 192.168.2.243/24
        - 192.168.2.242/24
        - 192.168.2.241/24
        - 192.168.2.240/24
        - 192.168.2.239/24
EOF
sudo chmod 600 /etc/netplan/*.yaml
```

3. Validate the combined configuration before applying it:

```bash
sudo netplan generate
sudo netplan get ethernets.eno1
```

The output should contain `dhcp4: true` and all 15 addresses above. Resolve any validation errors before continuing.

4. Apply with a three-minute confirmation window:

```bash
sudo netplan try --timeout 180
```

Keep the terminal open. Use a second connection to check SSH access and run `ip -4 -br addr show eno1` to confirm the addresses. Press Enter at the confirmation prompt if the checks pass. If connectivity fails, leave it unconfirmed so Netplan can attempt rollback after the timeout. Verify the actual configuration after a rollback before making further changes or rebooting.

5. After the Pi-hole and proxy containers are running, verify DNS and proxy access:

```bash
ip -4 -br addr show eno1
dig @192.168.2.253 example.com A +short +time=3 +tries=1
curl -sS --max-time 10 -o /dev/null -w 'HTTP %{http_code}\n' http://192.168.2.245:81/
```

Expect all 15 static addresses plus the DHCP address, a DNS answer, and HTTP 200 from the Nginx Proxy Manager login page. Also check access from another LAN device. Run these service checks after starting the containers when rebuilding from scratch.

6. When migrating an existing installation that has `extra-ips.service`, disable it after the checks pass:

```bash
sudo systemctl disable extra-ips.service
systemctl is-enabled extra-ips.service
```

The final command should print `disabled` (its nonzero exit status is expected). Keep the old script and unit as fallback files; Netplan now manages the addresses. On a fresh installation, do not create or enable the old service. A reboot is not required to apply the configuration; after any later reboot, repeat the address and service checks above.


# Media

### filestructure
    
    ~
    ├── data                    
    │   ├── torrent          
    │   ├── usenet          
    │   ├── media
    │   │   ├── movies       
    │   │   ├── tv       
    │   │   ├── youtube       
    ├── apps                    
    │   ├── portainer          
    │   ├── home-assistant          
    │   ├── # omitted          
    │   ├── torrent   
    │   │   ├── docker-compose.yml      # containing qbittorrent, radarr, sonarr, etc.          
    │   └── ...                
    └── ...

Torrents downloads to `~/data/torrent`    
Usenet downloads to `~/data/torrent`    
Plex has access to `~/data/media`    

The setup requires remote path mappings on Radarr and Sonarr's download client. 

**Torrent**: From remote path  `/download` to local path `/movies/torrents`

**Usenet**: From remote path `/config/Downloads/complete/` to local path `/movies/usenet`

# Start Automatically When a Power Source is Connected

When connected to a power source the Nuc automacally turns on. Handy for when there's an power outage and you're on vacation.

1. Press F2 during boot to enter BIOS Setup.
2. Go to the Power > Secondary Power Settings menu.
3. Set the option for After Power Failure to Power On.

https://www.intel.com/content/www/us/en/support/articles/000054773/intel-nuc/intel-nuc-mini-pcs.html

# Handy commands

Recursive add user to folders: `sudo chown -R 1001:1001 /dont/do/this`

`ip address`

`ip route`

`nslookup example.com`

`nslookup example.com 192.168.2.253`


Find eth interface: (eno1) `ifconfig` the ip that's the ip of the machine is the eth that should be used.

Find gateway: `ip r | grep ^def`

Ping from inside container `sudo docker exec -ti pihole ping -c 4 google.com`

Use all available space for LVM group

```bash
sudo lvextend -r -L +150g ubuntu-vg/ubuntu-lv
sudo lvextend -r -l +100%FREE ubuntu-vg/ubuntu-lv
```

`nmap 192.168.2.243` to see network stuff

# Mount harddrive

Find harddrive with:

`lsblk -f`

mount by name:

`sudo mkdir /mnt`
`sudo mkdir /mnt/hdd1`

`sudo mount -t auto -v /dev/sda /mnt/hdd1`


for startup:

find UUID:
`sudo blkid /dev/sda (or name)`

open
`sudo nano /etc/fstab`

write a new line:
`UUID={id from before} /mntt/hdd1 ext4 defaults,errors=remount-ro 0 1`