#/bin/sh


# find hostname and ip
host=$(hostname)
foo=$(hostname -I)

# start up airmon and airodump
cd /home/pi/mozfest/;

sudo rm nohup.out
sudo mv airodump.log airodump.log.1

sudo airmon-ng check kill;
sudo airmon-ng start wlan0;
sudo airodump-ng mon0 --channel 11 --berlin 2  2>&1  | ./send_wifi_data.py 2>&1 >  airodump.log &

# sort out the networking to attach to known wifi networks on the other card
sudo  wpa_supplicant -B -iwlan1 -c/etc/wpa_supplicant.conf -Dwext && dhclient wlan1;
sudo dhclient wlan1;


sleep 5
echo $foo

# sort out logs
sudo mv wifi.log wifi.log.1
sudo rm wifi.log


# start up the image sender
cd /home/pi/mozfest;
sudo ./send_images.py 2>&1 > wifi.log &
