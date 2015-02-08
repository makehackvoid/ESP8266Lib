-- Send a Packet on a Socket with keypress

count = 0
delay = 0
buttonstate = false
gpio.mode(4,gpio.INT or gpio.PULLUP)

function transmit_msg()
   sk=net.createConnection(net.TCP, 0)
   sk:on("receive", function(sck, c) print(c) end )
   sk:on("connection", function(sck) 
       if buttonstate then 
           sk:send("GET index.html/?pin=OFF HTTP/1.0")
           print("Off Sent")
       else
           sk:send("GET index.html/?pin=ON HTTP/1.0")
           print("On Sent")
           end
       buttonstate = not buttonstate
   end )
   sk:connect(80,"192.168.0.13")
   tmr.delay(1000000)
   end

function buttonpress(level)
   x = tmr.now()
   if x > delay then
      delay = tmr.now()+50000
      count = count + 1
      print(".")
      transmit_msg()
      end
   end

gpio.trig(4, "down",buttonpress)
