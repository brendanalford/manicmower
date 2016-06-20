@echo off
echo Building Manic Mower...

sjasmplus loader.sjasm
if %errorlevel% neq 0 goto :end
bin2tap -a 25000 loader.bin

sjasmplus musicassets.sjasm
if %errorlevel% neq 0 goto :end
bin2hltap musicassets.bin

sjasmplus musicassets2.sjasm
if %errorlevel% neq 0 goto :end
bin2hltap musicassets2.bin

sjasmplus manicmower.sjasm --lst=manicmower.lst --lstlab
if %errorlevel% neq 0 goto :end
bin2hltap manicmower.bin main.tap

echo Building tape image...
copy /b mowerloader.tap + loader.tap + main.tap + musicassets.tap + musicassets2.tap manicmower.tap
:end

exit /b errorlevel
