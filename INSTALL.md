# Resize and reboot, upgrade apt-get

    sudo raspi-config

resize, enable camera, overclock to 900 (medium)

reboot

    sudo apt-get update && sudo apt-get upgrade -y

# Emitters

install airodump-ng

    sudo apt-get install libnl-dev libssl-dev iw
 
    wget http://download.aircrack-ng.org/aircrack-ng-1.2-beta3.tar.gz
    tar -zxvf aircrack-ng-1.2-beta3.tar.gz
    cd aircrack-ng-1.2-beta3
    make
    sudo make install

install this

    git clone https://github.com/libbymiller/mozfest
    cd mozfest

add to init.d

    sudo cp init_d_wifi_stalker /etc/init.d/
    sudo chmod 755 /etc/init.d/wifi_stalker
    sudo chown root:root /etc/init.d/wifi_stalker

    sudo update-rc.d wifi_stalker defaults
    sudo update-rc.d wifi_stalker enable

add network to

    /etc/wpa_supplicant.conf

    network={
      ssid="XXX"
      psk="XXX"
    }

sort out the timing - emitters get their time form teh collector

    sudo cp ntp.conf.emitter /etc/ntp.conf

edit /etc/rc.local to include

    ( /etc/init.d/ntp stop
      until ping -nq -c3 10.0.0.200; do
      echo "waiting for network..."
    done
    ntpdate -b -u 10.0.0.200 /etc/init.d/ntp start ) &

reboot

# For the collector 

use a radiodan base image

install sqlite3

    sudo apt-get install sqlite3 libsqlite3-dev

get this and install the ruby code

    git clone https://github.com/libbymiller/mozfest
    cd mozfest

    sudo gem install bundler
    bundle install

collector controls the time

    sudo cp ntp.conf.collector /etc/ntp.conf

we replace radiodan default web page with ours

    sudo cp wpa-cli-web /etc/init.d/wpa-cli-web 
    sudo cp wpa_cli_web_redirect /etc/nginx/sites-enabled/wpa_cli_web_redirect


reboot

connect to radiodan-configuration
connect to http://10.0.0.200:8080/
