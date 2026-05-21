@echo off

echo.
echo  COMSOL Server Installer Work-around Script
echo           2016 TeAM SolidSQUAD-SSQ
echo.

REM Detecting if we are administrators

sfc 2>&1 1>"%TEMP%\testme.txt"
find /i "/SCANNOW" "%TEMP%\testme.txt" >nul
if %errorlevel% NEQ 0 goto no_admin

del /Q "%TEMP%\testme.txt"

echo.
echo Detecting SERVER installation...

REM We dont expect COMSOL to fix this bug fast...
for %%a in (50 51 52 52a 52b 55 53a 53b 54 54a 54b) do ( 
  if not "x%COMSOLROOT%x"=="xx" goto skip
  for /F "tokens=3" %%b in ('reg query HKLM\SOFTWARE\Comsol\COMSOL%%aServer /v COMSOLROOT 2^>nul ^| findstr "COMSOLROOT"') do set "COMSOLROOT=%%b" && set "COMSOLSERVERVER=%%a"
  :skip
  echo.>NUL
)

echo COMSOL %COMSOLSERVERVER% Server = %COMSOLROOT%
echo.
echo Detecting installation source...

REM Let's find comsolsetup.log

if not exist "%COMSOLROOT%\comsolsetup.log" goto no_source

REM OK it is found - parse it to find "cs.installroot"

for /F "tokens=3,4,5,6" %%a in ('findstr /B "cs.installroot" "%COMSOLROOT%\comsolsetup.log"') do set "COMSOLDVD=%%a%%b%%c%%d"

echo COMSOL Installation Source = %COMSOLDVD%

REM Check if the source is accessible

if not exist "%COMSOLDVD%\setupconfig.ini" goto no_source

REM Now copy the requiredfiles into temp dir

set "COMSOLTEMPDIR=%TEMP%\comsolworkaround"
mkdir "%COMSOLTEMPDIR%"

REM Now copy the files from install source to tempdir renaming it to .tar.gz

for %%a in (fl fl_jvm_win64 fl_win64) do (
  copy /b "%COMSOLDVD%\archives\%%a.isa" "%COMSOLTEMPDIR%\%%a.isa"
  "%~dp07z.exe" x "%COMSOLTEMPDIR%\%%a.isa" -o"%COMSOLTEMPDIR%\">nul
  "%~dp07z.exe" x "%COMSOLTEMPDIR%\%%a" -o"%COMSOLROOT%\">nul
)

REM copy bin\tomcat\conf\login.win.config to bin\tomcat\conf\login.config
copy /b "%COMSOLROOT%\bin\tomcat\conf\login.win.config" "%COMSOLROOT%\bin\tomcat\conf\login.config"

REM Null the bin\tomcat\conf\login.properties
echo.>"%COMSOLROOT%\bin\tomcat\conf\login.properties"

REM Restart the COMSOL Server service
sc stop "COMSOL%COMSOLSERVERVER%Service"
sc start "COMSOL%COMSOLSERVERVER%Service"

REM Mission complete
rd /s /q "%COMSOLTEMPDIR%"
echo.
echo All done! Enjoy!
echo.
pause
goto:eof

REM Error handlers

REM No source can be detected (no comsolsetup.log)

:no_source
echo Cannot detect COMSOL Installation Source!
echo Make sure it is accessible (like virtual or real DVD-ROM)
echo.
pause
goto:eof

:no_admin

echo.
echo No administrator rights detected!
echo Running this batch script from non-administrator rights
echo does only set the per-user environment variable.
echo.
echo To install or remove services, run it as Administrator,
echo right-clicking on this script and selecting Run As Administrator
echo.
del /Q "%TEMP%\testme.txt"
pause
goto:eof