@echo off
svn info | grep -Po "(?<=URL: http://svn.simpleviewinc.com:8080/svn/code/dashboard/).*"
