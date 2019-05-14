..\snasm -map beast.asm beast.sna
if ERRORLEVEL 1 goto doexit

rem simple 48k model
..\CSpect.exe -s14 -map=beast.sna.map -zxnext -mmc=.\ beast.sna

:doexit