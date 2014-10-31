= Mozfest Prototype = 

This is experimental code developed by BBC R&D for Ian Forrester's Ethical Dilemma cafe at Mozfest 2014, a collaboration between Libby Miller, 
Jasmine Cox and Andrew Nicolaou.

We wanted to investigate how current tools can be used to track you in physical space using the devices you are carrying and using. We were 
particularly interested in tracking devices based on their wifi mac addresses, because these are tools that are being used for tracking people 
[as they shop](http://www.telegraph.co.uk/finance/newsbysector/mediatechnologyandtelecoms/8995867/Shopping-centres-track-customers-with-mobile-technology.html).

This is part of wider work within our groups investigating the costs and benefits of personalisation of media, but for Mozfest the main aim was to 
illustrate the possibilities of the technology in order to provoke discussion.

To do this we created three innocuous "stalker" picture frames, placed strategically around the cafe. These consisted of cheap deep frames with 
postcards mounted in them, and a tiny hole placed for a camera.

![Stalker pictures](/doc/images/frames.jpg "Stalker picture frames")

These frames each house a Raspberry Pi with two wifi cards, a Pi camera, and a USB battery pack. This is all you need to scan for Mac addresses 
in the area, take pictures, and send all the data off for processing.

We used another Pi to create a private wifi network for the others to connect to, and to process the results, matching images 
and mac addresses by time and resending the matched results over the network via web sockets for processing and display.

We had a final Pi just to display the results in a browser on a screen, like this:

![Sample snapshot](/doc/images/snap1.jpg "Sample snapshot")

- but the part that really provoked discussion by creating a noisy, very visible result of all this silent activity by [turning the images into ascii 
art and sending them to a dot matrix printer](https://gist.github.com/andrewn/294d9483f5bd2ef11055). The continuous paper from the refurbished 
printer sprawled over the mezzanine floor we were on and down to the ground floor:

![Continous data](/doc/images/paper2.jpg "Continuous data")

This really gave a sense of the volume of data and gave people souvenirs to take away.

These technologies are used by companies to track us for commercial purposes. The ethical dilemma is one we face every time we go into a space 
with tracking systems like this: do we enjoy the benefits of our mobile phone and be tracked, not knowing what data is being held by whom or used 
for what? or do we give up our phones? If you visited us and we captured images of you or some of your data, unobfuscated that data never left 
the private network or the machines we used, and has since been deleted. But how far do we trust organisations to do this?


== References ==
* ["City of London calls halt to smartphone tracking bins"](http://www.bbc.co.uk/news/technology-23665490)
* ["What's really happening with iOS 8 MAC address randomization?"](http://www.imore.com/closer-look-ios-8s-mac-randomization)
* ["Shopping centres track customers with mobile technology"](http://www.telegraph.co.uk/finance/newsbysector/mediatechnologyandtelecoms/8995867/Shopping-centres-track-customers-with-mobile-technology.html)
* ["High street shops are studying shopper behaviour by tracking their smartphones or movement"](http://www.theguardian.com/news/datablog/2013/oct/03/analytics-amazon-retailers-physical-cookies-high-street)

This work builds on the Radiodan platform and previous technical experiments around [device proximity](https://github.com/libbymiller/mozfest_experiments/blob/master/doc/about.md)


