
# Home server

This repo contains documentation of my current setup for my home server running Ubuntu Server 22.04 on an Intel Nuc.

Services include

* Plex Media Server
* Radarr, Sonarr, Prowlarr, Overseerr & qBittorrent
* Home Assistant, Mosquitto, Zigbee2MQTT & Cloudflared
* Pi-hole & Unbound
* Azure Self Hosted Build Agent 
* Tailscale, Gluetun
* Portainer, Watchtower & Glances
* Ollama (LLM) & Open WebUI

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

We can add multiple addresses to our network interface. Make sure the router does not assign IP's above these IP's. Currently we have these hardcoded IP addresses:

| IP            | App            | Domain       |
| ------------- | -------------- | ------------ |
| 192.168.2.253 | Pi-Hole        | pihole.local |
| 192.168.2.252 | Unbound        |              |
| 192.168.2.251 | Home Assistant | home.local   |
| 192.168.2.250 | Overseerr      | stream.local |
| 192.168.2.249 | Glances        | stats.local  |
| 192.168.2.248 | Open WebUI (Ollama)        | chat.local  |


### Adding the IP address

We have to create a file that we can call on boot to always add these IP addresses.

1. Create file `sudo nano ~/scripts/extra-ips.sh`

```bash 
#!/usr/bin/env bash
ip addr add 192.168.2.253/24 dev eno1
ip addr add 192.168.2.252/24 dev eno1
ip addr add 192.168.2.251/24 dev eno1
ip addr add 192.168.2.250/24 dev eno1
ip addr add 192.168.2.249/24 dev eno1
ip addr add 192.168.2.248/24 dev eno1
```

`sudo chmod +x ~/scripts/extra-ips.sh`

1. Create file `sudo nano /etc/systemd/system/extra-ips.service`

```bash
#!/usr/bin/env bash
[Unit]
After=network.target

[Service]
ExecStart=~/scripts/extra-ips.sh          # REPLACE ~ WITH REAL PATH 

[Install]
WantedBy=default.target
```

Enable the service with `sudo systemctl enable extra-ips`
Debug with `sudo systemctl status extra-ips`


Then `sudo reboot`


# Media

### filestructure
    
    ~
    ├── data                    
    │   ├── torrent          
    │   ├── media
    │   │   ├── movies       
    │   │   ├── tv       
    ├── apps                    
    │   ├── portainer          
    │   ├── home-assistant          
    │   ├── torrent   
    │   │   ├── docker-compose.yml      # containing qbittorrent, radarr, sonarr, etc.          
    │   └── ...                
    └── ...

Torrents download to `~/data/torrent`    
Plex has access to `~/data/media`    

The setup requires remote path mappings on Radarr and Sonarr's download client. From remote path  `/download` to local path `/movies/torrents`

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

`nslookup example.com 192.168.2.243`


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