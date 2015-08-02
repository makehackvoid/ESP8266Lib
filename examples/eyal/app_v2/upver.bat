set upgm=%1
set d=20%DATE:~6%%DATE:~3,2%%DATE:~0,2%
set t=%TIME::=%
set t=%t: =0%
set p=%CD:\=/%
for %%x in (%p%) do set p=%%~nxx
c:\bin\sed "s|#VERSION#|%D%%T:~0,6% %P%|" %upgm%.lua >%upgm%_ver.lua
call %up% %upgm%_ver.lua %upgm%.lua
del %upgm%_ver.lua

set upgm=
set d=
set t=
set p=
