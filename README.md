mozfest
=======

Code for our Mozfest prototypes

Consisting of
 * a script in python that takes photos and sends images to a server
 * a script in python that uses airodump to detect nearby wifi-enabled devices and sends their MAC addresses to a server
 * a ruby server that gets the data and displays it, using faye to send the data

It's very hacky at the moment, with hardcoded IP addresses and things like that.
