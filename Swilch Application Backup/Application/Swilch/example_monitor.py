import socket

#	create a socket object
s= socket.socket(socket.AF_INET, socket.SOCK_STREAM)

#	get local machine name
host = socket.gethostname()

port = 9999

#connection to hostname on the port
s.connect((host,port))

#Receive no more than 1kB
while 1:
	tm = s.recv(2)
	if len(tm)>0:	
		print("The message from server is ",tm)
		

