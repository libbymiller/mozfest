# For all of them

Make a new blank card with wheezy

    diskutil list
    diskutil unmountDisk /dev/diskn
    sudo dd bs=1m if=~/Downloads/2014-09-09-wheezy-raspbian.img of=/dev/diskn
    
connect to the pi and do

    sudo raspi-config

resize, enable camera, overclock to 900 (medium)

reboot

    sudo apt-get update && sudo apt-get upgrade -y

# For the emitters

install prerequisites

    sudo apt-get install libnl-dev libssl-dev iw avahi-daemon ntpdate

install airodump-ng

    wget http://download.aircrack-ng.org/aircrack-ng-1.2-beta3.tar.gz
    tar -zxvf aircrack-ng-1.2-beta3.tar.gz
    cd aircrack-ng-1.2-beta3
    make
    sudo make install

install this

    cd /home/pi/
    git clone https://github.com/libbymiller/mozfest
    cd mozfest

add to init.d

    sudo cp init_d_wifi_stalker /etc/init.d/wifi_stalker
    sudo chmod 755 /etc/init.d/wifi_stalker
    sudo chown root:root /etc/init.d/wifi_stalker

    sudo update-rc.d wifi_stalker defaults
    sudo update-rc.d wifi_stalker enable

add network to /etc/wpa_supplicant.conf

    network={
      ssid="XXX"
      psk="XXX"
    }

sort out the timing - emitters get their time from the collector

    sudo cp ntp.conf.emitter /etc/ntp.conf

edit /etc/rc.local to include

    ( /etc/init.d/ntp stop
      until ping -nq -c3 10.0.0.200; do
      echo "waiting for network..."
    done
    ntpdate -b -u 10.0.0.200 
    /etc/init.d/ntp start ) &

reboot

# For the displayer

As emitter but

* set hostname to mozdisplayer
* comment out the last two lines in start_wifi_stalker.sh

# For the collector 

    sudo apt-get update && sudo apt-get upgrade -y

install the parts of radiodan we need:

    git clone https://github.com/radiodan/provision.git

    cd provision

replace the contents of steps/wpa/install.sh

with

    sudo apt-get install -y --force-yes dnsmasq && \
    sudo apt-get install -y --force-yes ruby1.9.1-dev hostapd=1:1.0-3+deb7u1 wpasupplicant && \
    sudo gem install --no-ri --no-rdoc wpa_cli_web

then

    sudo mkdir /var/log/radiodan

    sudo LOG_LEVEL=DEBUG ./provision avahi nginx wpa

edit /etc/hostapd/hostapd.conf to make it create a wifi network with a password

    sudo pico /etc/hostapd/hostapd.conf


    ssid=mozstalker
    interface=wlan0
    driver=nl80211
    hw_mode=g
    channel=1
    wpa=2
    wpa_passphrase=xxxxxxx
    wpa_key_mgmt=WPA-PSK
    # makes the SSID visible and broadcasted
    ignore_broadcast_ssid=0

install this code

    git clone https://github.com/libbymiller/mozfest.git


Now: unplug any ethernet, reboot, and check the network comes up.

install sqlite3

    sudo apt-get install sqlite3 libsqlite3-dev

get this and install the ruby code

    git clone https://github.com/libbymiller/mozfest
    cd mozfest

    sudo gem install bundler foreman --no-rdoc --no-ri

    bundle install

(bundle install takes ages on the pi)

update the init.d script

    sudo cp wpa-cli-web /etc/init.d/wpa-cli-web 

we replace radiodan default web page with ours

    sudo cp wpa_cli_web_redirect /etc/nginx/sites-enabled/wpa_cli_web_redirect

collector controls the time, so we make it a local ntp server

    sudo cp ntp.conf.collector /etc/ntp.conf

change its name (not essential, but less confusing)

    sudo pico /etc/hostname
    sudo pico /etc/hosts

and replacing "raspberrypi" with e.g. "collector"

reboot

What should happen is that a protected network called mozstalker should come up. If you connect to it and go to http://10.0.0.200:7070, you should see a blank page, which should update when there's an emitter around. Logs are in /var/log/radiodan/adhoc.log


# For a printer

    cd
    sudo apt-get install jp2a
    cd provision
    sudo LOG_LEVEL=DEBUG ./provision node
    cd ../mozfest
    npm install faye es6-promise 

then to test:

    node main.js
