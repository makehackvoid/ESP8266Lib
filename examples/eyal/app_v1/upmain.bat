set d=20%DATE:~6%%DATE:~3,2%%DATE:~0,2%
set t=%TIME::=%
set t=%t: =0%
set p=%CD:\=/%
c:\bin\sed "s|#VERSION#|%D%%T:~0,6% %P%|" main.lua >main_ver.lua
call %up% main_ver.lua main.lua
del main_ver.lua

set d=
set t=
set p=
