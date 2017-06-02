REM Read premake5.lua and generate GNU makefiles and vs2015 solution.
premake5.exe vs2017
premake5.exe gmake --os=linux
premake5.exe xcode4
rem pause
