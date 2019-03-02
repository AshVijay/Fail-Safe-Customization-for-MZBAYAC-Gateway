#!/usr/bin/env python
import time
import thread
import socket
import sys,os
import json,ast
import pprint
import urllib2
import subprocess
import serial, datetime
import scipy
import numpy
import math
import pywt
import pandas
import sklearn
import pickle
import urllib2,base64,requests
import netifaces
import re
import threading
import socket
import struct
import csv
import sqlite3
import time

from svm import *
from svmutil import *


ERROR_CODE = 0x01
CLIENTSOCKET = None

subprocess.call(["sh","/home/appusr_swilch/swilch/swilch_application_000.000.003/Socket_Script"])

sqlite_file = '/home/appusr_swilch/swilch/swilch_application_000.000.003/db.sqlite'    # name of the sqlite database file
table_name = 'my_table'   # name of the table to be created
id_field = 'id' # name of the ID column
date_time_col = 'date_time' # name of the date & time column
field_type = 'TEXT'  # column data type

# Connecting to the database file
conn = sqlite3.connect(sqlite_file)
c = conn.cursor()

# Creating a new SQLite table with 1 column
c.execute('CREATE TABLE IF NOT EXISTS {tn} ({fn} {ft} PRIMARY KEY AUTOINCREMENT)'\
        .format(tn=table_name, fn=id_field, ft="INTEGER"))

# adding a new column to save date and time and update with current date-time
# in the following format: YYYY-MM-DD HH:MM:SS
# e.g., 2014-03-06 16:26:37
try:
	c.execute("ALTER TABLE {tn} ADD COLUMN '{cn}'"\
	         .format(tn=table_name, cn=date_time_col))
except:
	pass
conn.commit()
conn.close()
def fn_update_current_time():
	global sqlite_file, table_name, id_field, date_time_col
	conn = sqlite3.connect(sqlite_file)
	c = conn.cursor()
	# update row for the new current date and time column, e.g., 2014-03-06 16:26:37
	c.execute("INSERT INTO {tn} ({cn}) VALUES(CURRENT_TIMESTAMP)"\
	         .format(tn=table_name, idf=id_field, cn=date_time_col))

	# The database should now look like this:
	# id         date           time        date_time
	# "some_id1" "2014-03-06"   "16:42:30"  "2014-03-06 16:42:30"

	conn.commit()
	conn.close()

def fn_check_internet():
	global ERROR_CODE
	#try:
        #		response = urllib2.urlopen("http://ec2-52-77-255-95.ap-southeast-1.compute.amazonaws.com:8080", timeout=1)
	#	ERROR_CODE = ERROR_CODE & 0xFFFE
	#	print 'gsm_connected'
	#except :
	#	ERROR_CODE = ERROR_CODE |0x0001
	#	print 'gsm_disconnected'

def thread_heartbeat(addr):
	global ERROR_CODE,CLIENTSOCKET
	while 1:
		try:
			if CLIENTSOCKET is not None:

                                CLIENTSOCKET.send(b"0x09");
                                #CLIENTSOCKET.send(b"0x02,0x09,0x3a,0x25,0x10")
				time.sleep(5)
                                #CLIENTSOCKET.send(b"0x07")
                                #message =  CLIENTSOCKET.recv(1024) ;    ##This receive blocks the flow




		except (KeyboardInterrupt) as e:
			print e
			CLIENTSOCKET.close()
			print "Client Socket ", addr, " Closed"
			CLIENTSOCKET = None
			break
        	except:
			CLIENTSOCKET.close()
			print "Client Socket ", addr, " Closed"
			CLIENTSOCKET = None
			break


def main_thread():
	global ERROR_CODE,CLIENTSOCKET
	serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	serversocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR,1)

	#get local machine name
	host = socket.gethostname()

	port = 9999

	#bind the port
	serversocket.bind((host, port))

	#queue up to 5 requests
	serversocket.listen(5)
        while True:


                #establish a connection
                print 'waiting for a connection_input at server end'

                CLIENTSOCKET, addr = serversocket.accept()
                CLIENTSOCKET.settimeout(30)


                print("Got a connection from %s" % str(addr))

                #print("0x80,0x81,0X83".encode());
                thread.start_new_thread(thread_heartbeat,(addr,))
                while True:
                        try:
                                message =  CLIENTSOCKET.recv(1024) ;
                                time.sleep(1.5)

                                if message == '0x84' :
                                   print ("8484")

                                print  message ;


                                if CLIENTSOCKET is not None :
                                        fn_check_internet()
                                        fn_update_current_time()
                                else:
                                        CLIENTSOCKET = None
                                        break
                        except (KeyboardInterrupt) as e:
                                print e
                                CLIENTSOCKET.close()
                                print "Client Socket ", addr, " Closed"
                                CLIENTSOCKET = None
                                break
                  #      except :                                               This section was ommitted to prevent client from closing as soon as it connects (infinite loop)
                  #              CLIENTSOCKET.close()
                  #              print "Client Socket" , addr , "Closed:"
                  #              CLIENTSOCKET = None
                  #              break


if __name__=="__main__":
	main_thread()

