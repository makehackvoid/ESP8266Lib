:: uploadall [flash]

set pgm=%CD%

if "flash" == "%1" goto flash
goto upload

:flash
set flash=%2
if "" == "%flash%" set flash=20150413-2308-eyal+test
set dir=%fw%\bin\%flash%
if not exist "%dir%" goto nodir
cd "%dir%"
call "%fw%\flash"
goto upload

:nodir
echo "no dir '%dir%'"
goto :eof

:upload

cd %pgm%

call %up% init.lua i.lua

call %up% funcs.lua

call upmain

:: call %up% read-ds3231.lua
:: call %up% ds3231.lua
:: call %up% i2clib.lua

call %up% read-ds18b20.lua
call %up% ds18b20.lua

call %up% wifi.lua

call %up% first.lua

call %up% save-tcp.lua
call %up% save-udp.lua

call %up% compile.lua

goto :eof
