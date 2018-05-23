:: Set working dir
cd %~dp0 & cd ..

:user_configuration

:: About AIR application packaging
:: http://livedocs.adobe.com/flex/3/html/help.html?content=CommandLineTools_5.html#1035959
:: http://livedocs.adobe.com/flex/3/html/distributing_apps_4.html#1037515

:: NOTICE: all paths are relative to project root

:: Your certificate information
set CERT_NAME="AS3-Potrace-Workers"
set CERT_PASS=U45PLaRe7WJ2EI7TyXxB8LIs3pglr87EIMQVmDRcZOW1npx96v96tLGuGlF2sZRh2N8p44bBXcMrQJJflIbErRsn6dMGVGm7PSsPA32QmYk4nmOly2iRmxdgAGnIeKKw
set CERT_FILE="bat\AS3-Potrace-Workers.p12"
set SIGNING_OPTIONS=-storetype pkcs12 -keystore %CERT_FILE% -storepass %CERT_PASS%

:: Application descriptor
set APP_XML=application.xml

:: Files to package
set APP_DIR=bin
set FILE_OR_DIR=-C %APP_DIR% .

:: Your application ID (must match <id> of Application descriptor) and remove spaces
for /f "tokens=3 delims=<>" %%a in ('findstr /R /C:"^[ 	]*<id>" %APP_XML%') do set APP_ID=%%a
set APP_ID=%APP_ID: =%

:: Output
set AIR_PATH=air
set AIR_NAME=AS3-Potrace-Workers

:validation
findstr /C:"<id>%APP_ID%</id>" "%APP_XML%" > NUL
if errorlevel 1 goto badid
goto end

:badid
echo.
echo ERROR: 
echo   Application ID in 'bat\SetupApp.bat' (APP_ID) 
echo   does NOT match Application descriptor '%APP_XML%' (id)
echo.
if %PAUSE_ERRORS%==1 pause
exit

:end
