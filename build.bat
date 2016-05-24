@echo off
echo Building Manic Mower...
sjasmplus bankloader.sjasm
if %errorlevel% neq 0 goto :end
bin2tap -a 25000 bankloader.bin
sjasmplus manicmower.sjasm --lst=manicmower.lst --lstlab
if %errorlevel% neq 0 goto :end
echo Building tape image...
bin2tap -a 32768 manicmower.bin -o main.tap
bin2tap -a 49152 tune.bin
bin2tap -a 49152 tune2.bin
copy /b mowerloader.tap + bankloader.tap + main.tap + tune.tap + tune2.tap manicmower.tap
:end

exit /b errorlevel
