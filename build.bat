@echo off
echo Building Manic Mower...

sjasmplus bankloader.sjasm
if %errorlevel% neq 0 goto :end
bin2tap -a 25000 bankloader.bin

sjasmplus musicassets.sjasm
if %errorlevel% neq 0 goto :end
bin2tap -a 49152 musicassets.bin

sjasmplus musicassets2.sjasm
if %errorlevel% neq 0 goto :end
bin2tap -a 49152 musicassets2.bin

sjasmplus manicmower.sjasm --lst=manicmower.lst --lstlab
if %errorlevel% neq 0 goto :end

echo Building tape image...
bin2tap -a 32768 manicmower.bin -o main.tap
bin2tap -a 49152 musicassets.bin
copy /b mowerloader.tap + bankloader.tap + main.tap + musicassets.tap + musicassets2.tap manicmower.tap
:end

exit /b errorlevel
