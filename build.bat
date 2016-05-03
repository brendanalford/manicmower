@echo off
echo Building Manic Mower...
sjasmplus manicmower.sjasm --lst=manicmower.lst --lstlab
if %errorlevel% neq 0 goto :end
echo Building tape image...
bin2tap -b -a 32768 -c 25855 -r 32768 manicmower.bin

:end

exit /b errorlevel
