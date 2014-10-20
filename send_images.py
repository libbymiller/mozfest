#!/usr/bin/python
# read from stdin

import fileinput
import re
import subprocess
import os
import glob
import time

command = "raspistill -tl 1000 -n  -o /run/shm/image%d.jpg -w 320 -h 240"
#ip = "192.168.1.10"
ip = "10.0.0.200"
source = "moz1"
p=subprocess.Popen(command,shell=True)


while(True):
  if(p.poll() is not None):
    print "gone"
    files = filter(os.path.isfile, glob.glob('/run/shm/' + "image*jpg"))
    files.sort(key=lambda x: os.path.getmtime(x))
    for x in files:
       imagefile = x
       tt = int(os.path.getmtime(x))
       print "time diff"
       print int(time.time()) -tt
       if(int(time.time()) -tt < 10 ):
         cmd2 = "curl http://"+ip+":8080/image -F my_file=@\""+imagefile+"\" -F \"name="+str(tt)+"\" -F \"source="+source+"\""
         print cmd2
         ppp=subprocess.Popen(cmd2,shell=True)
         time.sleep(1)
    if(p.poll() is not None):
       print "restarting raspistill"
       p=subprocess.Popen(command,shell=True)

