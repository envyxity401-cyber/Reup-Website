@echo off
:: reup website pusher
:: stages everything in this folder, commits, pushes to the live repo. if the
:: repo isnt init'd yet it sets up origin pointing at the github remote first.
:: pass a commit message as the first arg, otherwise it uses a timestamp.

setlocal EnableDelayedExpansion

cd /d "%~dp0"

set "REMOTE=https://github.com/simplykur/reup-website.git"
set "MSG=%~1"
if "%MSG%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%I"
    if defined DT (
        set "MSG=update !DT:~0,4!-!DT:~4,2!-!DT:~6,2! !DT:~8,2!:!DT:~10,2!"
    ) else (
        set "MSG=update"
    )
)

echo.
echo reup website pusher
echo    remote: %REMOTE%
echo    message: %MSG%
echo.

:: 1 git available?
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: git is not on PATH. install git for windows then run this again.
    pause
    exit /b 1
)

:: 2 init repo if needed and wire up origin
if not exist ".git" (
    echo ^>^>^> initialising new git repo
    git init -b main
    if errorlevel 1 (
        echo ERROR: git init failed
        pause
        exit /b 1
    )
    git remote add origin "%REMOTE%"
) else (
    :: make sure origin matches the expected remote, fix it silently if not
    for /f "delims=" %%U in ('git remote get-url origin 2^>nul') do set "CURURL=%%U"
    if not defined CURURL (
        git remote add origin "%REMOTE%"
    ) else if /i not "!CURURL!"=="%REMOTE%" (
        echo ^>^>^> updating origin url
        git remote set-url origin "%REMOTE%"
    )
)

:: 3 stage and commit
echo ^>^>^> staging changes
git add -A
git diff --cached --quiet
if not errorlevel 1 (
    echo    nothing to commit
) else (
    echo ^>^>^> committing
    git commit -m "%MSG%"
    if errorlevel 1 (
        echo ERROR: commit failed
        pause
        exit /b 1
    )
)

:: 4 push to main. if the remote has diverged (this folder is a fresh clone/init
:: so its history doesn't match the remote's), a normal push is rejected. since
:: this folder IS the source of truth for the site, force-update main to match it.
echo ^>^>^> pushing to origin (main)
git push -u origin main
if errorlevel 1 (
    echo.
    echo ^>^>^> normal push was rejected, the remote has a different history
    echo ^>^>^> force-updating the site to match this folder...
    git push -u origin main --force
    if errorlevel 1 (
        echo ERROR: push failed. check the remote url + your github auth ^(a browser/login window may have opened^).
        pause
        exit /b 1
    )
)

echo.
echo done. site usually updates in under a minute.
echo.
pause
endlocal
