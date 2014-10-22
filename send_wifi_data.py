#!/usr/bin/python
# read from stdin

import fileinput
import re
import subprocess
import os
import glob
import time
import sys
import socket

source = socket.gethostname()
            
print source

to_send_power = {}
to_send_time = {}
last_time_seen = int(time.time())
last_seen_anything = 100
#ip = "192.168.1.10"
ip = "10.0.0.200"
exclusions = ["00:0F:13:37:19:2E","7C:D1:C3:1E:4E:F6","00:0F:13:29:0B:92","FA:AD:4E:3D:EA:D9","7C:DD:90:44:13:29","00:C1:41:17:12:C2"]

for line in fileinput.input():
    pass

    if(re.search('  \w\w\:\w\w', line)):
        arr = re.split('  ',line)
        power = int(arr[2])
        this_id = str(arr[1].strip())
        tt = int(time.time())
        if(power > -51 and power!=-1 and this_id not in exclusions):
            print "this_id "+str(this_id)+" power "+str(power)
#            sys.stdout.write('.')
#            print "updating last seen anything to "+str(tt)         
            to_send_power[this_id] = str(power)
            to_send_time[this_id] = str(tt)
            last_seen_anything = tt

        if((len(to_send_power) > 0) and int(time.time()) - last_time_seen > 10):
          if(int(time.time()) - last_seen_anything < 12):#???
            print "sending because "+str(time.time() - last_seen_anything)
            data_str = "["
            count = 0
            for item in to_send_time:           

             data_str = data_str + "{\"source\":\""+source+"\",\"id\": \""+item+"\", \"time\": \""+to_send_time[item]+"\", \"power\": \""+to_send_power[item]+"\"}"
             if(count < len(to_send_time)-1):
                data_str = data_str +","
             count=count+1
            data_str = data_str+"]"
            cmd2 = "curl -X POST http://"+ip+":8080/metadata -H 'Content-Type: application/json' -d '{\"data\": "+data_str+"}'"
            print cmd2
            ppp=subprocess.Popen(cmd2,shell=True)
#            sleep(1) 
          last_time_seen = int(time.time())
