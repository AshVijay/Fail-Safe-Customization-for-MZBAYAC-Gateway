import socket
import subprocess
import os
import fcntl
import pprint
import time
import thread


fil1 = open("/home/appusr_swilch/swilch/swilch_application_000.000.003/pidfile",'w');
b=os.getpid();
fil1.write(str(b)) ;
fil1.close();
#	create a socket object
s= socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR,1)
host = socket.gethostname()
port = 9999 #connection to hostname on the port
s.settimeout(15);


replace =0
loop = 1
while(loop < 4):                                          #To check if the application cannot be brought up
  try :
        time.sleep(0.5)
        loop = loop + 1
        if (replace == 0 ):
            s.connect((host,port))
        replace = 1
  except :
        replace = 0

Kernel_Update=0                               # Flag to check if Kernel update is accepted by the application
Application_Update=0                          # Flag to check if Application update is accepted by the application



def ThreadedCall_OTA () :                     # To Start the communication with OTA Script as a separate thread
       global s , s1 , s2 , Kernel_Update , Application_Update
       while 1 :

            mes1 = '0'
            try :

               CLIENTSOCKET1, addr1 = s1.accept()
               mes1 = CLIENTSOCKET1.recv(4);  #This will time out if it doesnt receive any message from the client script
               print(mes1)

               if mes1 == '44':               # send hotplug notification
                   s.send("0x84") ;
               ######################
               if mes1 == '45' :
                   s.send("0x88,0x01") ;      # send kernel update request from USB
               if mes1 == '46':
                   s.send("0x89,0x01")        # send application update request from USB
               if mes1 == '47' :
                   s.send("0x88,0x01") ;
                   s.send("0x89,0x01") ;      # send both the update requests from USB

               ######################
               if mes1 == '55' :
                  s.send("0x88,0x02") ;      # send kernel update request from SSH
               if mes1 == '56':
                  s.send("0x89,0x02")        # send application update request from SSH
               if mes1 == '57' :
                  s.send("0x88,0x02") ;
                  s.send("0x89,0x02") ;      # send both the update requests from SSH
               ######################

               host2 = socket.gethostname()
               port2 = 8000
               OTA_connect = 0
               while(OTA_connect == 0):      # Infinite loop to wait for connection with server script
                  try :
                    s2.connect((host2,port2))
                    while(1):                # Infinite loop that waits for the server script to time out if the application is unable to acknowledge request
                       if (Kernel_Update == 1 ):  #Kernel_Update will be set to 1 when application responds
                          s2.send("90")
                          Kernel_Update = 0
                          break
                       elif (Application_Update == 1): #Application_Update will be set to 1 when application responds
                          s2.send("90")
                          Application_Update = 0
                          break
                       else :
                          print("No acknowledgement from Application") 

                    OTA_connect=1             # To break out of loop if connection to server script is received
                    s2.close()
                  except :
                     OTA_connect=0            # Do nothing if the request for connection is not met at the server side

            except socket.timeout :
                     print("Could not find connection from OTA Client") ; # Do nothing





if(replace == 0) :                                        #To replace the corrupted application folder with the last stored backup version
     #subprocess.call(["rm","-r","/home/appusr_swilch/swilch/swilch_application_000.000.003"])
     #subprocess.call(["cp","-r","/backup/recusr_swilch/swilch_application_000.000.003/*","/home/appusr_swilch/swilch/swilch_application_000.000.003"])
     print("Replacing the corrupted Application with the last stable version")
     subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/RC_Script_Hang"])


s1=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s1.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR,1)
host1 = socket.gethostname()
port1 = 8080
s1.bind((host1, port1))       # creating s1 socket as server for OTA requests from OTA script
s1.listen(3)                  # queue upto 3 requests
s1.settimeout(2)
s2= socket.socket(socket.AF_INET, socket.SOCK_STREAM)           # Socket s2 acts as client for the connection between Monitor program and OTA script
s2.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR,1)


thread.start_new_thread(ThreadedCall_OTA,())

while(1):

     #s1.close();
     #subprocess.call(["fuser","-k","-n","tcp","8080"])
     time.sleep(2)
     try:
         subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/DiskUsage_Script"])
         f2= open ("/home/appusr_swilch/swilch/swilch_application_000.000.003/DiskUsage_Code");
         diskusage_code = f2.read(100);

         s.send(diskusage_code);        # sends 0x8f along with percentage usage to application periodically

         tm = s.recv(128)
         print(tm)

         if tm == '0x01' :
           s.send("0x80 , 0x01")
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Internet_Script"])
           f1= open("/home/appusr_swilch/swilch/swilch_application_000.000.003/Internet_Code")
           internet_code=f1.read(100)
           time.sleep(2)
           s.send(internet_code)
           f1.close()

         elif tm[0:4] == '0x02':
           usb_list = tm.split(",")
           vendorid =  usb_list[1][2:4]+usb_list[2][2:4]
           productid = usb_list[3][2:4]+usb_list[4][2:4]
           s.send("0x80, "+tm)
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/USB_Script", vendorid, productid])
           f2= open("/home/appusr_swilch/swilch/swilch_application_000.000.003/USB_Code")
           usb_code=f2.read(100)
           s.send(usb_code)
           f2.close()

         elif tm == '0x03':
           s.send("0x80 , 0x03")
           time.sleep(5)
           s.close()
           s1.close()
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/RC_Script_Hang"])


         elif tm == '0x04':
           s.send("0x80 , 0x04")
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Wifi_Script"])

         elif tm == '0x05' :
           s.send("0x80 , 0x05")
           time.sleep(5)
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Restart_Script"])

         elif tm[0:4] == '0x06':
           port_list = tm.split(",")
           port_num = port_list[1][2:4]+port_list[2][2:4]
           s.send("0x80 , 0x06")
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Socket_Script",port_num])

         elif tm == '0x07':
           s.send("0x80 , 0x07")
           Kernel_Update = 1
           print ("Request for Kernel Update Accepted")


         elif tm == '0x08' :
           s.send("0x80 , 0x08")
           Application_Update = 1
           #host2 = socket.gethostname()
           #port2 = 8000
           #s2.connect((host2,port2))
           #s2.send("90")
           #s2.close()
           print ("Request for Application update accepted")

         elif tm == '0x09' :
           s.send("0x80 , 0x09")
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Backup_Script"])
           f3= open("/home/appusr_swilch/swilch/swilch_application_000.000.003/BackupDone_Code")
           backupdone_code=f3.read(1)

           if (backupdone_code == "1"):
             s.send("0x8b")             #Backup done

         ####   Acknowledgement Codes from  Application to Monitor ######################
         elif tm == '0x00,0x81' :
           print("Acknowledgement for Code 0x81 received") ;
         elif tm == '0x00,0x82' :
           print("Acknowledgement for Code 0x82 received") ;
         elif tm == '0x00,0x83' :
           print("Acknowledgement for Code 0x83 received") ;
         elif tm == '0x00,0x84,0x82' :
           print("Acknowledgement for Code 0x84,0x82 received") ;
         elif tm == '0x00,0x84,0x83' :
           print("Acknowledgement for Code 0x84,0x83 received") ;
         elif tm == '0x00,0x85' :
           print("Acknowledgement for Code 0x85 received") ;
         elif tm == '0x00,0x86' :
           print("Acknowledgement for Code 0x86 received") ;
         elif tm == '0x00,0x88' :
           print("Acknowledgement for Code 0x88 received") ;
         elif tm == '0x00,0x89' :
           print("Acknowledgement for Code 0x89 received") ;
         elif tm == '0x00,0x8a':
           subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Backup_Script"]);
           f3= open("/home/appusr_swilch/swilch/swilch_application_000.000.003/BackupDone_Code");
           backupdone_code=f3.read(1);
           if (backupdone_code == "1"):
              s.send("0x8b");
         elif tm == '0x00,0x8b' :
           print("Acknowledgement for Code 0x8b received")
         #################################################################################

         else :
           #s.close();
           print ("Invalid message code received")
           #subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Application_Script"]);
           #s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
           #s.connect((host,port));

     except socket.timeout:
         print("Request Timed Out - No response from server")
         s.close();
         s1.close();
         subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/RC_Script_Hang"])


     except :
         print ("Unexpected exception")
         s.close()
         s1.close()
         subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/RC_Script_Hang"])






