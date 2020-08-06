@echo off
chcp 1251
cls
echo --------------------------------- > runscript.log
sqlplus SCOTT/TIGER@XE @runscript.PDC >> runscript.log
echo %DATE:~0,2%.%DATE:~3,2%.%DATE:~6,4% %TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2% >> runscript.log
