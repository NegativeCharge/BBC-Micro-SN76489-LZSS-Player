@ECHO OFF
cd .\tracks\7chs
cmd /c "..\..\tools\swram-split.bat"

cd ..\..
cmd /c "BeebAsm.exe -v -i .\main.lfsr.s.asm -title LZSSPLR1 -do .\LZSSPlayer_1.ssd -opt 3"
cmd /c "BeebAsm.exe -v -i .\main.softbass.s.asm -title LZSSPLR1 -do .\LZSSPlayer_2.ssd -opt 3"
cmd /c "BeebAsm.exe -v -i .\disk_2_additional_tracks.s.asm -title LZSSPL2R -do .\LZSSPlayer_3.ssd -opt 3"
cmd /c ".\tools\bbcim.exe -interss sd LZSSPlayer_1.ssd LZSSPlayer_3.ssd LZSSPlayer.dsd"
cmd /c ".\tools\bbcim.exe -interss sd LZSSPlayer_2.ssd LZSSPlayer_3.ssd LZSSPlayerSB.dsd"

cmd /c "del LZSSPlayer_*.ssd"