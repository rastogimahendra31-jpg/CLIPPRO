@echo off
rem Clipora: double-click to install everything (first time) and start the app.
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title Clipora
echo.
echo   Clipora  -  setting up and starting. First time takes 5-15 minutes.
echo.

rem 1. Python 3.9-3.12
set "PY="
py -3.12 -c "import sys" >nul 2>nul && set "PY=py -3.12"
if not defined PY python -c "import sys; sys.exit(0 if (3,9)<=sys.version_info[:2]<=(3,12) else 1)" >nul 2>nul && set "PY=python"
if not defined PY (
  echo   [1/4] Python not found. Installing Python 3.12...
  where winget >nul 2>nul || (echo   Please install Python 3.12 from https://www.python.org/downloads/ ^(tick "Add python.exe to PATH"^), then run Start.bat again. & pause & exit /b)
  winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
  echo.
  echo   Python is installed. Close this window and double-click Start.bat again.
  pause & exit /b
)
echo   [1/4] Python ok

rem 2. ffmpeg (cuts and checks the videos)
call :findff
where ffprobe >nul 2>nul
if errorlevel 1 (
  echo   [2/4] Installing ffmpeg...
  winget install -e --id Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
  call :findff
)
where ffprobe >nul 2>nul || (echo   ffmpeg could not be installed. Install it from https://www.gyan.dev/ffmpeg/builds/ and run Start.bat again. & pause & exit /b)
echo   [2/4] ffmpeg ok

rem 3. Libraries in a private folder (.venv), only the first time
if not exist ".venv\Scripts\python.exe" %PY% -m venv .venv
if not exist ".venv\installed.txt" (
  echo   [3/4] Installing libraries. This is the long part...
  ".venv\Scripts\python.exe" -m pip install --upgrade pip >nul
  ".venv\Scripts\python.exe" -m pip install -r requirements.txt || (echo   Library install failed. Check your internet and run Start.bat again. & pause & exit /b)
  ".venv\Scripts\python.exe" -m pip install --no-deps -r requirements-translate.txt
  where nvidia-smi >nul 2>nul && (echo   NVIDIA card found: adding the faster GPU libraries... & ".venv\Scripts\python.exe" -m pip install -r requirements-gpu.txt)
  echo done> ".venv\installed.txt"
)
echo   [3/4] Libraries ok

rem 4. Start
if not exist workspace mkdir workspace
echo   [4/4] Starting Clipora. Your browser opens at http://localhost:8765
echo.
echo   Keep this window open while you use Clipora. Close it to stop.
echo.
".venv\Scripts\python.exe" app.py workspace
pause
exit /b

:findff
rem a winget ffmpeg from an earlier install, even if this window's PATH does not know it yet
set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WinGet\Links"
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg*") do for /d %%B in ("%%D\*") do if exist "%%B\bin\ffprobe.exe" set "PATH=%%B\bin;!PATH!"
exit /b
