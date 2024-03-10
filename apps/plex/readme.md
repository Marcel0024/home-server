# Claim

For plex claim token visit https://www.plex.tv/claim/


# Enable QuickSync for iGPU transcoder

Create a file called `/etc/modprobe.d/i915.conf`

In the file add this line: `options i915 enable_guc=2 force_probe=4e61`

Run `sudo update-initramfs -u -k all`

# Misc

Once up and running navigate to Settings -> Network -> LAN Networks, make sure to add the local subnet `192.168.2.0/24`. This fixes local clients not detecting they are local.