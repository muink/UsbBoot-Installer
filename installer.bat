:: UsbBoot Installer
:: Add usb boot suporrt for Windows 7/8/10
:: Author: muink

@echo off&title Add usb boot suporrt for Win7/8/10(Not WTG)
net session>nul 2>nul||color 4F&&echo.Please run as Administrator&&pause>nul&&goto END
:init
cd /d %~dp0
set "reg_system_path=HKLM\SYSTEM"
set "reg_software_path=HKLM\SOFTWARE"
del /f /q UsbBootWatcher.conf>nul 2>nul
null>UsbBootWatcher.conf 2>nul
set "bootflag_win8=0x14"
set "bootflag_win7=0x6"
set "bootflag_winxp=0"
:choise_install_mode
cls
echo.Choise the installation mode (Default 1)
echo.     0. Exit
echo.     1. Add usb boot support for the current system
echo.     2. Add usb boot support for other windows system
set "install_mode=1"
set /p install_mode=Choise: 
if not "%install_mode%"=="0" (
   if not "%install_mode%"=="1" (
      if not "%install_mode%"=="2" (
         goto choise_install_mode
      ) else goto menu_2
   ) else goto menu_1
) else cls&goto END

:menu_1
cls
set "install_volume=%SystemDrive:~0,1%"
::checksystem
set install_version=
call:[CheckSystem] install_version
goto install_support

:menu_2
cls
echo.
set "install_volume=0"
set /p install_volume=Enter drive letter of the system: 
echo.%install_volume%|findstr /i "\<[a-z,A-Z]\>">nul||goto menu_2
echo.%install_volume%|findstr /i "\<[c,C]\>">nul&&goto menu_2
::checksystem
set "reg_system_path=HKLM\USBOSYS"
set "reg_system_file=%install_volume%:\Windows\System32\config\SYSTEM"
set "reg_software_path=HKLM\USBOSOFT"
set "reg_software_file=%install_volume%:\Windows\System32\config\SOFTWARE"
set install_version=
set error_m2=
call:[CheckSystem] install_version error_m2 reg_system_path reg_system_file reg_software_path reg_software_file
if "%error_m2%"=="2" (
   echo.
   echo.This volume no available system exist or system registry corrupted.
   echo.
   echo.Press any key to back.&pause>nul
   goto menu_2
)
if "%error_m2%"=="8" (
   echo.
   echo.This volume no available system exist or system registry corrupted.
   echo.
   echo.Press any key to back.&pause>nul
   goto menu_2
)
goto install_support

:install_support
call:[Install] %install_version%
if not "%install_version%"=="winxp" (
rem Force detection HAL at boot
(echo.@echo off
echo.%%~1 ver^|findstr "5\."^>nul^&^&goto :adt
echo.%%~1 mshta vbscript:createobject("shell.application"^).shellexecute("%%~s0","rem","","runas",1^)(window.close^)^&goto :eof
echo.
echo.:adt
echo.bcdedit /set {current} detecthal on^>nul
echo.del /f /q "%%~f0"^>nul
)>"%install_volume%:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\force_detection_hal.bat"
rem Make sysprep script
(echo.@echo off
echo.%%~1 ver^|findstr "5\."^>nul^&^&goto :adt
echo.%%~1 mshta vbscript:createobject("shell.application"^).shellexecute("%%~s0","rem","","runas",1^)(window.close^)^&goto :eof
echo.
echo.:adt
echo.set "ny=n"
echo.set /p ny=Start Sysprep? [y/n]
echo.echo.
echo.if "%%ny%%"=="y" (
echo.   set "ny=n"
echo.   set /p ny=Are you sure? [y/n]
echo.^)
echo.if "%%ny%%"=="y" "%%windir%%\System32\sysprep\sysprep.exe" /oobe /generalize /shutdown
)>"%install_volume%:\Users\Public\Desktop\run_sysprep.bat"
)
::install server program
copy /y UsbBootWatcher.conf "%install_volume%:\Windows\System32">nul
if exist "%install_volume%:\Windows\SysWOW64" (
   copy /y UsbBootWatcher.exe "%install_volume%:\Windows\System32">nul
) else copy /y UsbBootWatcherx86.exe "%install_volume%:\Windows\System32\UsbBootWatcher.exe">nul

goto COMPLETE





:[CheckSystem]
setlocal enabledelayedexpansion
if "%install_mode%"=="1" (
   set "syspath=%reg_system_path%"
   set "softpath=%reg_software_path%"
) else (
   set "syspath=!%~3!"
   set "sysfile=!%~4!"
   set "softpath=!%~5!"
   set "softfile=!%~6!"
   rem File Check
   if not exist "!sysfile!" (
      for /f %%i in ("2") do endlocal&set "%~2=%%i"&goto :eof
   )
   if not exist "!softfile!" (
      for /f %%i in ("8") do endlocal&set "%~2=%%i"&goto :eof
   ) else reg load !softpath! "!softfile!">nul
)
call:[VerifySystemVersion] vers %softpath% ProductName EditionID CurrentVersion
for /f "delims=" %%i in ("%vers%") do endlocal&set "%~1=%%i"
goto :eof


:[VerifySystemVersion]
setlocal enabledelayedexpansion
call:[CatNTInfo] %~2 %~3 name
call:[CatNTInfo] %~2 %~4 edition
call:[CatNTInfo] %~2 %~5 version
if not "%install_mode%"=="1" reg unload %~2>nul
echo.%version%|findstr "\<[0-9,.]*\>">nul&&(
   for /f "tokens=1-2 delims=." %%i in ("%version%") do (
      set "version=%%i%%j"
   )
)||set /a "version+=0"
::Return version code
if %version% lss 51 (
   set "oldlb=1"
   set "version=winxp"
) else (
   if %version% lss 60 (
      set "version=winxp"
   ) else (
      if %version% lss 62 (
         set "version=win7"
      ) else (
         if %version% leq 63 (
            set "version=win8"
         ) else (
            if %version% gtr 63 (
               set "version=win11"
               set "newlb=1"
            )
         )
      )
   )
)
:[VerifySystemVersion]loop
cls
echo.&echo.Identified system is "%name%" edition is "%edition%"&echo.
if defined oldlb color CF&echo.Warning: This system is too old may not support this feature.&echo.
if defined newlb color CF&echo.Warning: Not support this system now.&goto END
set "ny=n"
set /p ny=Whether continue? [y/n]
color 07
if not "%ny%"=="n" (
   if not "%ny%"=="y" goto %~0loop
) else cls&goto END
for /f "delims=" %%i in ("%version%") do endlocal&set "%~1=%%i"
goto :eof


:[CatNTInfo]
setlocal enabledelayedexpansion
for /f "tokens=2* delims= " %%i in ('reg query "%~1\Microsoft\Windows NT\CurrentVersion" /v %~2 2^>nul^|findstr /i /c:" %~2 "') do set "%~3=%%j"
if not defined %~3 set "%~3=NULL"
for /f "delims=" %%i in ("!%~3!") do endlocal&set "%~3=%%i"
goto :eof


:[Install]
setlocal enabledelayedexpansion
set /a "bootdriverflag=bootflag_%~1"
if not "%install_mode%"=="1" reg load %reg_system_path% "%reg_system_file%"
::Can not runing XP
for /f "tokens=2* delims= " %%i in ('reg query %reg_system_path%\select /v current /t reg_dword^|findstr /i current') do set /a "conum=%%j"
set "selectcontrol=%reg_system_path%\ControlSet00%conum%"
call:[InstallServer] %bootdriverflag%
call:[EnableAHCI]
call:[Install20]
call:[Install30]
call:[InstallIntel30]
call:[InstallAMD30]
call:[InstallASMedia30]
if not "%install_mode%"=="1" reg unload %reg_system_path%
endlocal
goto :eof


::Definition UsbBootWatcher server
:[InstallServer]
rem Before handing over control to load the usb drive to memory
if not "%~1"=="0" (
   reg add "%selectcontrol%\Control" /v BootDriverFlags /t reg_dword /d %~1 /f
   for /f "tokens=2* delims= " %%i in ('reg query "%selectcontrol%\Control\PnP" /v PollBootPartitionTimeout^|findstr /i PollBootPartitionTimeout') do (
      if "%%j"=="0x0" reg add "%selectcontrol%\Control\PnP" /v PollBootPartitionTimeout /t reg_dword /d 30000 /f
   )
)
::Registry services
reg add "%selectcontrol%\services\Usb Boot Watcher Service" /v ImagePath /t reg_expand_sz /d %%SystemRoot%%\system32\UsbBootWatcher.exe /f
reg add "%selectcontrol%\services\Usb Boot Watcher Service" /v ObjectName /t reg_sz /d LocalSystem /f
reg add "%selectcontrol%\services\Usb Boot Watcher Service" /v Start /t reg_dword /d 2 /f
reg add "%selectcontrol%\services\Usb Boot Watcher Service" /v Type /t reg_dword /d 0x20 /f
reg add "%selectcontrol%\services\Usb Boot Watcher Service" /v ErrorControl /t reg_dword /d 1 /f
::Registry safe mode services
reg add "%selectcontrol%\Control\SafeBoot\Minimal\Usb Boot Watcher Service" /ve /t reg_sz /d Service /f
reg add "%selectcontrol%\Control\SafeBoot\Network\Usb Boot Watcher Service" /ve /t reg_sz /d Service /f
::Disable Blue Screen Automatic Restart
reg add "%selectcontrol%\Control\CrashControl" /v AutoReboot /t reg_dword /d 0 /f
goto :eof


::Enable AHCI
:[EnableAHCI]
reg query "%selectcontrol%\services\msahci">nul 2>nul&&reg add "%selectcontrol%\services\msahci" /v Start /t reg_dword /d 0 /f
goto :eof


::Definition internal usb2.0 drive
:[Install20]
call:[DeviceSet] "usbccgp,usbehci,usbhub,usbohci,USBSTOR,usbuhci"
goto :eof


::Definition native usb3.0 drive (if have)
:[Install30]
call:[DeviceSet] "USBHUB3,USBXHCI"
goto :eof


::Definition Intel usb3.0 drive (if have)
:[InstallIntel30]
call:[DeviceSet] "iusb3hub,iusb3xhc"
goto :eof


::Definition AMD usb3.0/3.1 drive (if have)
:[InstallAMD30]
call:[DeviceSet] "amdhub3,amdxhci,amdhub30,amdxhc,amdhub31,amdxhc31"
goto :eof


::Definition ASMedia usb3.0 drive (if have)
:[InstallASMedia30]
call:[DeviceSet] "asmthub3,asmtxhci"
goto :eof


:[DeviceSet]
setlocal enabledelayedexpansion
set "device=%~1"
:[DeviceSet]loop
for /f "tokens=1* delims=," %%i in ("%device%") do (
   reg query "%selectcontrol%\services\%%i">nul 2>nul&&(
      reg add "%selectcontrol%\services\%%i" /v Start /t reg_dword /d 0 /f
      reg add "%selectcontrol%\services\%%i" /v Group /t reg_sz /d "Boot Bus Extender" /f
      (echo.[%%i]
      echo.Start@REG_DWORD=0
      echo.Group@REG_SZ="Boot Bus Extender"
      )>>UsbBootWatcher.conf
   )
   set "device=%%j"
   goto %~0loop
)
endlocal
goto :eof





:COMPLETE
cls
echo.
echo.Installation completed!
:END
echo.
echo.Press any key to exit.&pause>nul
echo."%~dp0"|findstr /i "%temp%">nul 2>nul&&rd /s /q "%~dp0">nul 2>nul
exit





::Version Reference
ver | find "4.0." >nul && echo.win95
ver | find "4.10." >nul && echo.win98
ver | find "4.90." >nul && echo.win_me
ver | find "3.51." >nul && echo.win_Nt_3_5
ver | find "5.0." >nul && echo.win2000
ver | find "5.1." >nul && echo.win_xp
ver | find "5.2." >nul && echo.win2003
ver | find "6.0." >nul && echo.vista
ver | find "6.1." >nul && echo.win7
ver | find "6.2." >nul && echo.win8
ver | find "6.3." >nul && echo.win8.1 or win10
::BootDriverFlags (Standard 7 Package Reference)
0: No special boot drivers are loaded.
1: Loads Internet SCSI (iSCSI) boot drivers.
2: Loads Microsoft Virtual Hard Disk (VHD) and Secure Digital (SD) boot drivers.
4: Loads USB boot drivers.
6: Loads VHD, SD, and USB boot drivers.
