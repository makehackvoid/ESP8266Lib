local tmr = tmr
local wifi = wifi
local sta = wifi.sta
local eventmon = wifi.eventmon
local timeout = tmr.create()

local function Log (message, ...)
	if #arg > 0 then
		message = message:format(unpack(arg))
	end
	print (("%.6f %s"):format (tmr.now()/1000000, message))
end

local ip      = "192.168.2.52"	-- my IP
local gateway = "192.168.2.7"	-- server IP
local netmask = "255.255.255.0"

local wifi_timeout       = 1000		-- ms
local wifi_suspend_time  = 50*1000	-- us
local sleep_time         = 2		-- s

local function have_connection()
	timeout:unregister()
	Log("have connection sta.status=%d sta.getip=%s/%s", sta.status(), sta.getip())

	Log("deep sleep %ss\n", sleep_time)
	node.dsleep (sleep_time*1000000, 1, 1)	-- wakeup with WiFi, sleep immediately
end

local retry_count        = 0

local function retry()
	if retry_count > 0 then
		Log ("retry failed")
		return
	end
	retry_count = retry_count + 1
	Log ("retry %d", retry_count)

	Log ("suspend status=%d", wifi.suspend())

	Log ("suspending")
	wifi.suspend({
		duration      = wifi_suspend_time,
		suspend_cb    = function() print("wifi suspended") end,
		resume_cb     = function() print("wifi resumed")   end,
		preserve_mode = true})
end

local function dowifi()
	sta.setip({ip=ip, netmask=netmask, gateway=gateway})
	Log("sta.status=%d sta.getip=%s/%s", sta.status(), sta.getip())

	tmr.wdclr()

	Log ("registering eventmons")
	eventmon.register(eventmon.STA_GOT_IP, function(T)
		Log("STA_GOT_IP")
		have_connection()
	end)

	eventmon.register(eventmon.STA_CONNECTED, function(T)
		Log("STA_CONNECTED")
	end)

	eventmon.register(eventmon.STA_DISCONNECTED, function(T)
		Log("DISCONNECTED reason %d", T.reason)
		retry()
	end)

	eventmon.register(eventmon.STA_AUTHMODE_CHANGE, function(T)
		Log("AUTHMODE_CHANGE")
	end)

	-- this is not expected - we do not use dhcp
	eventmon.register(eventmon.STA_DHCP_TIMEOUT, function(T)
		Log("STA_DHCP_TIMEOUT")
		retry()
	end)

	-- in case we were too late and missed the STA_GOT_IP event
	if wifi.STA_GOTIP == sta.status() then
		Log ("already connected")
		have_connection()
		return
	end

	Log("set main  wifi timeout %dms", wifi_timeout)
	timeout:alarm(wifi_timeout, tmr.ALARM_SINGLE, function()
		Log("connection timeout, status=%d", sta.status())
		retry()
	end)
end

local function show_reason()
	local _, reset_reason, EXCCAUSE, EPC1, EPC2, EPC3, EXCVADDR, depc= node.bootreason()
	if (reset_reason~=0 and reset_reason~=5 and reset_reason~=6) then
		if (reset_reason==2) then
			print(string.format("\treset_reason:%i EXCCAUSE:%i EPC1:%X EPC2:%X EPC3:%X EXCVADDR:%X DEPC:%i", reset_reason, EXCCAUSE, EPC1, EPC2, EPC3, EXCVADDR, depc))
		else
			print(string.format("\treset_reason:%i", reset_reason))
		end
	end  
end

local magic_pin = 1	-- gpio5 or D1

gpio.mode (magic_pin, gpio.INPUT, gpio.PULLUP)
if 0 == gpio.read (magic_pin) then
	Log ("aborting by magic")
else
	show_reason()
	dowifi()
end

