@echo off
setlocal

node -v >nul 2>&1
if %errorlevel% equ 0 (
    cd dashboard
    npm install
    cd dashboard
    npm start
) else (
    echo Node.js is required to launch the dashboard without a standalone binary.
    echo Please download and install Node.js from https://nodejs.org/en/download
)

cmd /k