@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0db.ps1" %*
exit /b %ERRORLEVEL%
