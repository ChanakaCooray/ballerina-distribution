@echo off

set BALPOS=windows
set WIXDIST=resources\wix
set ICONDIST=resources\icons
set SIGNTOOLLOC="%programfiles(x86)%\Windows Kits\10\bin\10.0.16299.0\x64\signtool.exe"
set CERTLOC="resources\cert\ballerina-digicert.pfx"

:argumentLoop
IF NOT "%1"=="" (
    IF "%1"=="--dist" (
        SET DIST=%2
        SHIFT
    )
    IF "%1"=="--version" (
        SET BALLERINA_VERSION=%2
        SHIFT
    )
	IF "%1"=="--path" (
        SET DISTLOC=%2
        SHIFT
    )
	SHIFT
	goto argumentLoop
) 


IF "%DIST%"==""  (
	set DIST=all
	rem echo The syntax of the command is incorrect. Missing argument dist.
	rem goto EOF
)

IF "%DISTLOC%"==""  (
	set DISTLOC=resources\dist
	rem echo The syntax of the command is incorrect. Missing argument dist.
	rem goto EOF
)

IF NOT "%DIST%"=="all" IF NOT "%DIST%"=="ballerina-platform" IF NOT "%DIST%"=="ballerina-runtime" (
	echo The syntax of the command is incorrect. Possible arguments for dist - all, ballerina-platform, ballerina-runtime.
	echo Ex: --dist ballerina-platform
	goto EOF
)

IF "%BALLERINA_VERSION%"==""  (
	echo The syntax of the command is incorrect. Missing argument version.
	goto EOF
)

for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set %%x
set UTC_TIME=%Year%-%Month%-%Day% %Hour%:%Minute%:%Second% UTC

rmdir ballerina-runtime-windows-%BALLERINA_VERSION% /s /q >nul 2>&1
rmdir ballerina-platform-windows-%BALLERINA_VERSION% /s /q >nul 2>&1
rmdir target /s /q >nul 2>&1

IF "%DIST%"=="all" (
	call :createballerina-platformWin64Installer
	rem call :createballerina-platformWin586Installer
	call :createballerina-runtimeWin64Installer
	rem call :createballerina-runtimeWin586Installer
) ELSE (
	call :create%DIST%Win64Installer
)

goto EOF


:createballerina-platformWin64Installer
set BALZIP=%DISTLOC%\ballerina-platform-windows-%BALLERINA_VERSION%.zip
set BALDIST=ballerina-platform-windows-%BALLERINA_VERSION%
set BALPARCH=x64
set INSTALLERPARCH=amd64
set MSI=ballerina-platform-%BALPOS%-installer-%BALPARCH%-%BALLERINA_VERSION%.msi
call :createInstaller
goto EOF

:createballerina-platformWin586Installer
set BALZIP=%DISTLOC%\ballerina-platform-windows-%BALLERINA_VERSION%.zip
set BALDIST=ballerina-platform-windows-%BALLERINA_VERSION%
set BALPARCH=i586
set INSTALLERPARCH=386
set MSI=ballerina-platform-%BALPOS%-installer-%BALPARCH%-%BALLERINA_VERSION%.msi
call :createInstaller
goto EOF

:createballerina-runtimeWin64Installer
set BALZIP=%DISTLOC%\ballerina-runtime-windows-%BALLERINA_VERSION%.zip
set BALDIST=ballerina-runtime-windows-%BALLERINA_VERSION%
set BALPARCH=x64
set INSTALLERPARCH=amd64
set MSI=ballerina-runtime-%BALPOS%-installer-%BALPARCH%-%BALLERINA_VERSION%.msi
call :createInstaller
goto EOF

:createballerina-runtimeWin586Installer
set BALZIP=%DISTLOC%\ballerina-runtime-windows-%BALLERINA_VERSION%.zip
set BALDIST=ballerina-runtime-windows-%BALLERINA_VERSION%
set BALPARCH=i586
set INSTALLERPARCH=386
set MSI=ballerina-runtime-%BALPOS%-installer-%BALPARCH%-%BALLERINA_VERSION%.msi
call :createInstaller
goto EOF

:createInstaller
rem jar -xf %BALZIP%
rmdir target\installer-resources /s /q >nul 2>&1
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('%BALZIP%', '.'); }"
xcopy  %ICONDIST% %BALDIST%\icons /e /i >nul 2>&1

echo %BALDIST% build started at '%UTC_TIME%' for %BALPOS% %BALPARCH%

echo Creating the Installer...

%WIXDIST%\heat dir %BALDIST% -nologo -v -gg -g1 -srd -sfrag -sreg -cg AppFiles -template fragment -dr INSTALLDIR -var var.SourceDir -out target\installer-resources\AppFiles.wxs
%WIXDIST%\candle -nologo -sw -dbalVersion=%BALLERINA_VERSION% -dWixbalVersion=1.0.0.0 -dArch=%INSTALLERPARCH% -dSourceDir=%BALDIST% -out target\installer-resources\ -ext WixUtilExtension resources\installer.wxs target\installer-resources\AppFiles.wxs
%WIXDIST%\light -nologo -dcl:high -sw -ext WixUIExtension -ext WixUtilExtension -loc resources\en-us.wxl target\installer-resources\AppFiles.wixobj target\installer-resources\installer.wixobj -o target\msi\%MSI%

%SIGNTOOLLOC% sign /f %CERTLOC% /p wuminit /t http://timestamp.verisign.com/scripts/timstamp.dll target\msi\%MSI%

rmdir ballerina-runtime-windows-%BALLERINA_VERSION% /s /q >nul 2>&1
rmdir ballerina-platform-windows-%BALLERINA_VERSION% /s /q >nul 2>&1

echo %BALDIST% build completed at '%UTC_TIME%' for %BALPOS% %BALPARCH%

echo.
goto EOF

:EOF
