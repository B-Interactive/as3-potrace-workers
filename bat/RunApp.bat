@echo off

:: Set working dir
cd %~dp0 & cd ..

set PAUSE_ERRORS=1

:: Clear bin folder and copy over assets to be packaged.
for /D %%p IN ("bin\*.*") DO rmdir "%%p" /s /q
xcopy "assets" "bin" /s /c /y /i /q

call bat\SetupSDK.bat
call bat\SetupApp.bat

echo.
echo Starting AIR Debug Launcher...
echo.

adl "%APP_XML%" "%APP_DIR%" -extdir lib/
if errorlevel 1 goto error
goto end

:error
pause

:end
