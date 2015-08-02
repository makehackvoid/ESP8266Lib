#!/usr/bin/python

# a simple server to provide IoT services
#
# message format:
#  time
#	will reply with the current date+time
#  id runCount data...
#	a timestamp is prepended to the message written to a file
#	the file name is "iot-" prepended to the 'id' in the directory 'path'
#  GET /path...
#	an http request
#
#  4 Apr 15 EL Created
#  5 Apr 15 EL Add req_*
#	EL Better reporting. Add err()
#  6 Apr 15 EL Add udp
#	EL Implement 'last'
#  8 Apr 15 EL Add lastData
#  9 Apr 15 EL Add 'show'
# 10 Apr 15 EL Add messageCount
# 11 Apr 15 EL Add 'data' request
#	EL Add missing 'context' arg to  err()
# 12 Apr 15 EL Add SO_REUSEADDR
#	EL Now loading initial record count
# 10 May 15 EL Add sleep in idle loop
#  6 Jun 15 EL Add options. Add --port=
#
# to do:
# - locking required to protect global stats

import socket
import sys
import string
import time
from thread import *
from datetime import datetime

port = 11883	# not quiet MQ

# unix
#	path = '/data/tellerstats/'
# windows
#	path = 'C:/Users/eyal/Documents/Downloads/arduino/esp8266/firmware/logs/'

# counters
tcp_transactions = 0
udp_transactions = 0
failed_transactions = 0
store_transactions = 0
req_transactions = 0
http_transactions = 0

# times
session_start = ""
tcp_transaction_last = ""
udp_transaction_last = ""
failed_transaction_last = ""
store_transaction_last = ""
req_transaction_last = ""
http_transaction_last = ""

lastData = {}
lastDate = {}
lastRun = {}
deviceIP = {}
messageCount = {}
recordCount = {}

def log(msg):
#	print(msg)
	pass

def dbg(msg):
#	print(msg)
	pass

def ok(context, msg):
	print(context+'\n   '+msg)
	pass

def err(context, msg):
	global failed_transactions, failed_transaction_last
	print(context+'\n   '+msg)
	failed_transactions = failed_transactions + 1
	failed_transaction_last = context

def get_last(device):
	if device in lastRun:
		return (lastRun[device])
	else:
		return ("1")

def get_data(device):
	if device in lastData:
		return (lastData[device])
	else:
		return ("")

def simple_request(context, now, conn, req):
	global req_transactions, req_transaction_last
	req_transactions = req_transactions + 1
	req_transaction_last = context
	dbg("req='"+req+"'")
	if req == 'time':
		resp = now.strftime("%Y%m%d%H%M%S %f")
	elif req[0:5] == 'last/':
		resp = str(get_last(req[5:]))
	elif req[0:5] == 'data/':
		resp = get_data(req[5:])
	else:
		err(context, "unknown request")
		return
	ok(context, 'sending '+req+': '+resp)
	conn.sendall(resp)

def http_stats(conn):
	devices = (("%15s %14s %6s %6s %-15s %s\r\n")
			% ("Device", "Date", "Run", "Count", "IP", "Data"))
	for d in deviceIP:
		devices = (("%s%15s %14s %6s %6d %-15s '%s'\r\n")
			% (devices, d, lastDate[d], lastRun[d], messageCount[d], deviceIP[d], lastData[d]))
	#print ("devices=\n"+devices)
	conn.sendall((   "time now is   %s\r\n"
			+"session start %s\r\n"
			+"tcp     transactions %6d (last: %s)\r\n"
			+"udp     transactions %6d (last: %s)\r\n"
			+"failed  transactions %6d (last: %s)\r\n"
			+"store   transactions %6d (last: %s)\r\n"
			+"request transactions %6d (last: %s)\r\n"
			+"http    transactions %6d (last: %s)\r\n"
			+ "%s")
			% (datetime.now().strftime("%Y%m%d%H%M%S.%f"),
			session_start,
			tcp_transactions, tcp_transaction_last,
			udp_transactions, udp_transaction_last,
			failed_transactions, failed_transaction_last,
			store_transactions, store_transaction_last,
			req_transactions, req_transaction_last,
			http_transactions, http_transaction_last,
			devices))

def http_request(context, now, conn, data, lines, words):
	global http_transactions, http_transaction_last
	http_transactions = http_transactions + 1
	http_transaction_last = context
	dbg("http='"+lines[0].translate(None, '\r\n')+"'")
	fname = words[1]
	if fname == '/time':
		resp = now.strftime("%Y%m%d%H%M%S %f")
	elif fname[0:6] == '/last/':
		resp = str(get_last(fname[6:]))
	elif fname[0:6] == '/data/':
		resp = get_data(fname[6:])
	elif fname == '/stats':
		ok(context, 'sending stats')
		http_stats(conn)
		return
	else:
		conn.sendall("unknown file '"+fname+"'\r\n")
		err(context, "unknown file '"+fname+"'")
		return
	ok(context, 'sending '+fname+': '+resp)
	conn.sendall(resp+"\r\n")

# words is:	'store' device data...
# storing:	timestamp data...
#
def store(context, now, data, words, addr):
	global lastData, lastDate, lastRun, deviceIP, messageCount
	global store_transactions, store_transaction_last
	store_transactions = store_transactions + 1
	store_transaction_last = context

	del words[0]	# remove 'store'
	device = words[0]
	words[0] = now.strftime("%Y%m%d%H%M%S")

	if device not in lastDate:
		ok (context, "new device '"+device+"'")
		messageCount[device] = 0

	lastData[device] = data
	lastDate[device] = words[0]	# timestamp
	lastRun[device]  = words[1]	# expect run count
	deviceIP[device] = addr[0]
	messageCount[device] += 1

	try:
		data = ' '.join(words)
		fname = path+'iot-'+device+'.log'
		f = open(fname, 'a')
		f.write(data+'\n')
		f.close()
		ok(context, "for "+device+" stored '"+data+"'")
	except:
		err(context, "except saving to '"+fname+"'")

def show(context, now, data, words, addr):
	global lastData, lastDate, lastRun, deviceIP, messageCount

	del words[0]	# remove 'show'
	device = words[0]
	del words[0]	# remove device

	lastData[device] = data
	lastDate[device] = now.strftime("%Y%m%d%H%M%S")
	lastRun[device]  = ''
	deviceIP[device] = addr[0]
	messageCount[device] += 1

	data = ' '.join(words)
	ok(context, "for "+device+" show '"+data+"'")

def close_connection(conn):
	if conn is not None:
		conn.close()

def process_request(context, now, conn, data, addr):
	dbg ("data='"+data.translate(None, '\r')+"'")
	if data == '':
		err(context, "no data in '"+data+"'")
		return

	lines = data.split('\n')
	if len(lines) < 1:
		err(context, "no lines in '"+data+"'")
		return

	line = lines[0].translate(None, '\r\n')
	dbg("line='"+line+"'")
	if len(line) < 1:
		err(context, "empty first line '"+line+"'")
		return

	words = line.split()
	req = words[0]

	if len(words) < 1:
		err(context, "no words in '"+line+"'")
	elif len(words) == 1:
		if conn is None:	# UDP
			err(context, "bad request over UDP: '"+line+"'")
			return
		simple_request(context, now, conn, req)
		close_connection(conn)
	elif req == 'GET':		# len >= 2
		if conn is None:	# UDP
			err(context, "GET not allowed over UDP")
			return
		http_request(context, now, conn, data, lines, words)
		close_connection(conn)
	elif req == 'store':
		close_connection(conn)	# let go asap
		store(context, now, data, words, addr)
	elif req == 'show':
		close_connection(conn)	# let go asap
		show(context, now, data, words, addr)
	else:
		err(context, "unknown request '"+line+"'")

def tcp_thread(context, now, conn, addr):
	data = conn.recv(1024)
	process_request(context, now, conn, data, addr)

def udp_thread(context, now, addr, data):
	process_request(context, now, None, data, addr)

def listen_tcp():
	global tcp_transactions, tcp_transaction_last
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
	s.bind(('', port))
	s.listen(100)

	while True:
		conn, addr = s.accept()
		now = datetime.now()
		context = now.strftime("%Y%m%d%H%M%S.%f")+' connection from TCP ' + addr[0] + ':' + str(addr[1])
		dbg (context)
		tcp_transactions = tcp_transactions + 1
		tcp_transaction_last = context
		start_new_thread(tcp_thread ,(context, now, conn, addr))

	s.close()

def listen_udp():
	global udp_transactions, udp_transaction_last
	s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
	s.bind(('', port))

	while True:
		data, addr = s.recvfrom(1024)
		now = datetime.now()
		context = now.strftime("%Y%m%d%H%M%S.%f")+' connection from UDP ' + addr[0] + ':' + str(addr[1])
		dbg (context)
		udp_transactions = udp_transactions + 1
		udp_transaction_last = context
		start_new_thread(udp_thread ,(context, now, addr, data))

def load_devices():
	global path, port, lastData, lastDate, lastRun, deviceIP, messageCount
	args = sys.argv
	del args[0]

	path = args[0]
	del args[0]

	for arg in args:
		if '-' == arg[0:1]:
			if '--port=' == arg[0:7]:
				port = int (arg[7:])
			else:
				print ("bad option %s")%(arg)
				sys.exit ()
		else:
			fields = arg.split(',')
			device = fields[0]
			lastData[device] = ''
			lastDate[device] = fields[1]
			lastRun[device]  = fields[2]
			recordCount[device]  = fields[3]
			messageCount[device]  = 0
			deviceIP[device] = '-'

	print("known devices:")
	print (("%15s %14s %6s %7s %-15s")
			% ("Device", "Date", "Run", "Records", "IP"))
	for d in lastDate:
		print (("%15s %14s %6s %7s %-15s")
				% (d, lastDate[d], lastRun[d], recordCount[d], deviceIP[d]))

session_start = datetime.now().strftime("%Y%m%d%H%M%S.%f")

load_devices()

print ("listening on TCP/UDP port %d")%(port)
print ("data path is '%s'")%(path)

start_new_thread(listen_tcp,())
start_new_thread(listen_udp,())

while True:
	time.sleep(60)	# would rather sleep forever...
	pass

