local fname = "runCount"

if nil == file.open (fname, "r") then
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
