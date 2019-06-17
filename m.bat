@echo off
bin\snasm src\ed.s
bin\hdfmonkey put \sdcard\cspect-next-2gb.img ed.nex
rem sjasmplus lom.s 
