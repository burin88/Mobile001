@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\build-appdistribution.ps1" %*
exit /b %ERRORLEVEL%
