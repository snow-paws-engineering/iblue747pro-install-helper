@echo off
setlocal
title Unofficial i-Blue 747Pro GPS Install Helper
set "GPS_SETUP_ROOT=%~dp0"
set "GPS_SETUP_SELF=%~f0"
powershell.exe -NoProfile -Command "if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -ne 'X64') { exit 1 }"
if errorlevel 1 (
 echo This package requires x64 Windows. ARM64 is not supported.
 pause
 exit /b 1
)
powershell.exe -NoProfile -Command "$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()); if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){exit 1}"
if errorlevel 1 (
 echo Requesting administrator permission...
 powershell.exe -NoProfile -Command "try { Start-Process -FilePath $env:GPS_SETUP_SELF -Verb RunAs -ErrorAction Stop } catch { Write-Host $_; exit 1 }"
 if errorlevel 1 pause
 exit /b
)
if not exist "%~dp0driver\Locosys_x64.inf" goto missing
if not exist "%~dp0driver\ls_gps_x64.cat" goto missing
echo Checking user-supplied driver integrity and Microsoft signature...
powershell.exe -NoProfile -Command "$ErrorActionPreference='Stop'; try { $d=Join-Path $env:GPS_SETUP_ROOT 'driver'; $i=Join-Path $d 'Locosys_x64.inf'; $c=Join-Path $d 'ls_gps_x64.cat'; if((Get-FileHash -LiteralPath $i).Hash -ne '145DDCDF2FF2DC2EDE7B7DDC86E35F09E1CFD6896BE8D71DF6CB6298AF18C116'){throw 'INF integrity check failed'}; if((Get-FileHash -LiteralPath $c).Hash -ne 'D17614AC70091DBB626F905B27289B1861CFD4833882E0561C1CA9088803B64E'){throw 'CAT integrity check failed'}; $s=Get-AuthenticodeSignature -LiteralPath $c; if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notlike 'CN=Microsoft Windows Hardware Compatibility Publisher,*'){throw 'Signature validation failed'}; Write-Host 'Verified.' } catch { Write-Host $_; exit 1 }"
if errorlevel 1 (
 echo Installation stopped. No security settings were changed.
 pause
 exit /b 1
)
echo Installing signed driver for USB VID_0E8D PID_3329...
"%SystemRoot%\System32\pnputil.exe" /add-driver "%~dp0driver\Locosys_x64.inf" /install
set "GPS_SETUP_RESULT=%ERRORLEVEL%"
if "%GPS_SETUP_RESULT%"=="3010" goto reboot
if not "%GPS_SETUP_RESULT%"=="0" (
 echo Installation failed. Error: %GPS_SETUP_RESULT%
 echo See C:\Windows\INF\setupapi.dev.log for details.
 pause
 exit /b %GPS_SETUP_RESULT%
)
echo Driver package installed. Connect and switch on the GPS.
echo The COM number differs between PCs.
"%SystemRoot%\System32\pnputil.exe" /enum-devices /connected /deviceid "USB\VID_0E8D&PID_3329"
echo Use the displayed COM port at 115200 baud, 8N1.
pause
exit /b 0
:reboot
echo Driver installed. Restart Windows to complete setup.
pause
exit /b 3010

:missing
echo No driver files are bundled with this helper.
echo Obtain and extract the driver yourself as described in README.md.
echo Put Locosys_x64.inf and ls_gps_x64.cat in the driver folder.
pause
exit /b 1
