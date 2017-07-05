local stop = 1  -- gpio5, D1
gpio.mode (stop, gpio.INPUT, gpio.PULLUP)
if 0 ~= gpio.read (stop) then dofile("test-rssi.lua") end
