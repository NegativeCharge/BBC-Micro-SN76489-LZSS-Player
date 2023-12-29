for %%x in (*.lzc) do ..\..\tools\split.exe -b 16384 -d "%%x" "%%~nx"
del *.lzc