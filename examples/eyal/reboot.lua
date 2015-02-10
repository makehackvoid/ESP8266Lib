gpio5 = 1
magic_pin = gpio5	-- LOW on this pin will stop the program

function getRunCount ()
	local fname = "runCount"

	f = file.open (fname, "r")
	if nil == f then
		runCount = 0
	else
		runCount = file.read()
		file.close()
	end

	runCount = runCount + 1

	file.open (fname, "w")
	file.write (runCount)
	file.close ()

	print ("run " .. runCount)
end

gpio.mode (magic_pin, gpio.INPUT);
if 0 == gpio.read (magic_pin) then
	print ("aborting by magic")
else
	getRunCount ()
	node.dsleep(5*1000000)
end

