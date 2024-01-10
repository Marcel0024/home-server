
# Home server

This repo contains documentation of my current setup for my home server running Ubuntu 22.04 on an Intel Nuc.

Services include

* Plex Media Server
* Radarr, Sonarr, qBittorrent
* Home Assistant
* Pi-hole + Unbound for all traffic on network
* Azure Self Hosted Build Agent 
* Tailscale
* Watchtower
* Grafana + Prometheus for monitoring
* Portainer

Everything is running in docker except Tailscale. All files asumes the local subnet is `192.168.2.0/24` and the gateway is on `192.168.2.100`.

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

Pihole/Home Assistant needs to have macvlan network setup first (next chapter)

# macvlan

The macvlan is declared with `192.168.2.240/28` making IP's `.240` to `.254` available to assign. Make sure the router does not assign IP's above .240.
Current hosts on the macvlan:

| IP            | Name           |
| ------------- | -------------- |
| 192.168.2.242 | Home Assistant |
| 192.168.2.243 | Pihole         |
| 192.168.2.244 | Unbound        |
| 192.168.2.254 | Nuc/Host       |


### Creating the macvlan

Make sure promiscuous mode is on our parent interface: `sudo ip link set eth0 promisc on`

```bash
docker network create -d macvlan -o parent=eno1 \
  --subnet 192.168.2.0/24 \
  --gateway 192.168.2.100 \
  --ip-range 192.168.2.240/28 \
  --aux-address="nuc=192.168.2.254" \
macvlan
```

### Enable docker to host communication over macvlan

So the idea is to create a second macvlan on the host with the same subnet and give the Host an IP (Defined above in the aux-address). And make sure it's there on boot.

1. Create file `~/scripts/macvlan.sh`

```bash 
#!/usr/bin/env bash
ip link add macvlan-shim link eno1 type macvlan mode bridge
ip addr add 192.168.2.254/28 dev macvlan-shim
ip link set macvlan-shim up
ifconfig macvlan-shim
```

1. Create `/etc/systemd/system/macvlan.service`

```bash
#!/usr/bin/env bash
[Unit]
After=network.target

[Service]
ExecStart=~/scripts/macvlan.sh          # REPLACE ~ WITH REAL PATH 

[Install]
WantedBy=default.target
```

Enable the service with `sudo systemctl enable macvlan`
Debug with `sudo systemctl status macvlan`


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

# Handy commands

Recursive add user to folders: `sudo chown -R 1001:1001 /dont/do/this`

`ip ddress`

`ip route`

`nslookup example.com`

`nslookup example.com 192.168.2.243`


Find eth interface: (eno1) `ifconfig` the ip that's the ip of the machine is the eth that should be used.

Find gateway: `ip r | grep ^def`

Ping from inside container ` sudo docker exec -ti pihole ping -c 4 google.com`

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