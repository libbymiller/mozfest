sudo raspi-config

# resize
# reboot

sudo apt-get update && sudo apt-get upgrade -y

== For the wifi stalkers ==

#installing airodump-ng

wget http://download.aircrack-ng.org/aircrack-ng-1.2-beta3.tar.gz
tar -zxvf aircrack-ng-1.2-beta3.tar.gz
cd aircrack-ng-1.2-beta3
sudo apt-get install libnl-dev libssl-dev iw
make
sudo make install

# install this
git clone https://github.com/libbymiller/mozfest
cd mozfest

#add init.d

sudo cp init_d_wifi_stalker /etc/init.d/
sudo chmod 755 /etc/init.d/wifi_stalker
sudo chown root:root /etc/init.d/wifi_stalker

sudo update-rc.d wifi_stalker defaults
sudo update-rc.d wifi_stalker enable

#add network to
#/etc/wpa_supplicant.conf


network={
    ssid="XXX"
    psk="XXX"
}

== For the collector ==

git clone https://github.com/libbymiller/mozfest
cd mozfest
sudo gem install bundler
bundle install

foreman start


