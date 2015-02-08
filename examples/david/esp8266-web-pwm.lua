--Configure Gpio
d1_output = 3
d1_input  = 4

--Show a User Message
print("Welcome to the Wifi PWM Controller")

srv=net.createServer(net.TCP) 
srv:listen(80,function(conn) 
    conn:on("receive", function(client,request)
        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then 
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP"); 
        end
        local _GET = {}
        if (vars ~= nil)then 
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do 
                _GET[k] = v; 
                print(k,'=',v);
            end 
        end
        buf = buf.."<h1>ESP8266 IoT Device</h1>";
        buf = buf.."<form src=\"/\">";
        buf = buf.."PWM Value (0-1023):<br>";
        buf = buf.."<input type=\"text\" name=\"pwmvalue\"><br>";
--      buf = buf.."Time to run (Seconds):<br>";
--      buf = buf.."<input type=\"text\" name=\"runtime\"><br>";
        buf = buf.."<br>Turn Digital Output Pin (gpio4) <select name=\"pin\" onchange=\"form.submit()\">";
        local _on,_off = "",""
        if(_GET.pin == "ON")then
              _on = " selected=true";
              pwm.setup(d1_output, 1000, tonumber(_GET.pwmvalue))
              pwm.start(d1_output)
        elseif(_GET.pin == "OFF")then
              _off = " selected=\"true\"";
              pwm.close(d1_output)
        end
        buf = buf.."<option".._on..">ON</opton><option".._off..">OFF</option></select><br><br>";
        buf = buf.."</form>";
        client:send(buf);
        client:close();
        collectgarbage();
    end)
end)
