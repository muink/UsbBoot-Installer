:: usbboot launcher
:: Launcher program in 32-bit or 64-bit
:: Author: muink

@echo off&title usbboot launcher
:init
set "program=installer.bat"
pushd %~dp0
for /f "tokens=2 delims=[]" %%a in ('ver^|findstr /i "\<[0-9]*\.[0-9,.]*\]\>"') do (
   for /f "tokens=2 delims= " %%b in ("%%a") do (
      for /f "tokens=1-2 delims=." %%c in ("%%b") do (
         if %%c%%d lss 60 (
            color 6F
            echo.
            echo.Can not runing this system.
            echo.
            echo.Press any key to exit.&pause>nul
            exit
         )
      )
   )
)
rem X64 system redirector
if "%processor_architecture%"=="x86" if exist "%windir%\SysWOW64" "%windir%\SysNative\cmd" /c %~f0&exit
mshta vbscript:createobject("shell.application").shellexecute("%program%","","","runas",1)(window.close)
exit