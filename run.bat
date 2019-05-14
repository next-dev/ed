@echo off
call make.bat
if not errorlevel 1 (
    bin\CSpect.exe -brk -s14 -w3 -sound -map=ed.sna.map -zxnext -mmc=bin ed.sna
    rem call install.bat
)
