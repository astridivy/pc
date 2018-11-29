@echo off
cd %1
cls
svn info | grep -Po "(?<=URL: http://svn.simpleviewinc.com:8080/svn/code/dashboard/).*"
pause > NUL
exit
