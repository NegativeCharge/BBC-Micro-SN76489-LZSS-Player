@ECHO OFF
cd .\tracks\lzc1
cmd /c "..\..\tools\swram-split.bat"

cd ..\..
BeebAsm.exe -v -i .\main.s.asm -title LZSSPLYR -d -labels labels.txt -do .\LZSSPlayer.ssd -opt 3