--[[
Program connects to the wifi, reads the temp from a ds18b20 temp sensor, connects to a MQTT broker,
publishes the temp, then goes to sleep for a minute.

Need to setup init.lua to call this file on boot for it to cycle.
--]]

t = require("ds18b20")

Server_IP_Address = "192.168.0.3"
Server_Port = 1883

gpio0 = 3
gpio2 = 4

t.setup(gpio2)

function testConnection() 
     if wifi.sta.getip()== nil then 
          print("IP unavaiable, Waiting...") 
     else 
          tmr.stop(1)
          print("Config done, IP is "..wifi.sta.getip())
          collectgarbage()
		StartProgram()
     end 
end

function StartProgram()
     m = mqtt.Client("clientid", 120, "user", "password")

     m:on("offline", function(con) 
                    print ("offline") 
                    end)
    
     m:connect(Server_IP_Address, Server_Port, 0, function(conn)
          print("Trying to connect to Broker")
          tmr.alarm(0, 3000, 0, function() 
               temp = t.read()
               print("Temperature: "..temp.."'C")
               m:publish("testing/temp" ,"Temperature: "..temp.."'C",0,0, function(conn)  end)
               node.dsleep(60000000)
               end )
     end)
end

print("Setting up WIFI...")
wifi.setmode(wifi.STATION)
wifi.sta.config("xxx", "xxx")
wifi.sta.connect()
tmr.alarm(1, 2500, 1, testConnection)