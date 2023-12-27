@ECHO OFF
cd .\tracks\7chs
cmd /c "..\..\tools\swram-split.bat"

cd ..\..
BeebAsm.exe -v -i .\main.s.asm -title LZSSPLYR -d -labels labels.txt -do .\LZSSPlayer.ssd -opt 3