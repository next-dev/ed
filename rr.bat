@echo off
call m.bat
if not errorlevel 1 (
    bin\CSpect.exe -sound -s14 -w3 -zxnext -nextrom -mmc=\sdcard\cspect-next-2gb.img
    rem call install.bat
)
