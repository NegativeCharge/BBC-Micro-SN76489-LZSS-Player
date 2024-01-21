@ECHO OFF
cd .\tracks\lzc1
cmd /c "..\..\tools\swram-split.bat"

cd ..\..
BeebAsm.exe -v -i .\main.lfsr.s.asm -title LZSSPLYR -d -labels labels.txt -do .\LZSSPlayer.ssd -opt 3
BeebAsm.exe -v -i .\main.softbass.s.asm -title LZSSPLYR -d -labels labels.txt -do .\LZSSPlayerSB.ssd -opt 3