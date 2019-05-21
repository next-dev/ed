@echo off
call m.bat
if not errorlevel 1 (
    bin\CSpect.exe -s14 -w3 -sound -map=ed.sna.map -zxnext -mmc=bin ed.sna
    rem call install.bat
)
