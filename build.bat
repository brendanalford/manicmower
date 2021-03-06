@echo off
echo Building Manic Mower...

sjasmplus loader.sjasm
if %errorlevel% neq 0 goto :end
bin2tap -a 25000 loader.bin

sjasmplus turboloader.sjasm
if %errorlevel% neq 0 goto :end
bin2tap -a 45824 turboloader.bin

bin2hltap loading_screen.bin

sjasmplus musicassets.sjasm
if %errorlevel% neq 0 goto :end
bin2hltap musicassets.bin

sjasmplus musicassets2.sjasm
if %errorlevel% neq 0 goto :end
bin2hltap musicassets2.bin

sjasmplus manicmower.sjasm --lst=manicmower.lst --lstlab
if %errorlevel% neq 0 goto :end
bin2hltap manicmower.bin main.tap

echo Building TAP image...
copy /b mowerloader.tap + loader.tap + loading_screen.tap + main.tap + musicassets.tap + musicassets2.tap manicmower.tap

echo Building TZX image...
buildtzx manicmower.tzx mowerloader_turbo.tap turboloader.tap loading_screen.bin manicmower.bin musicassets.bin musicassets2.bin
:end
exit /b errorlevel
