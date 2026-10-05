@echo off
chcp 65001 >nul
echo.
echo  === El Despertar: instalador del cliente ===
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_CLIENTE.ps1"
echo.
pause
