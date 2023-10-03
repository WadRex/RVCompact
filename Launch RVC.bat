@echo off

if not "%1"=="Administrator" (
  powershell -Command "Start-Process cmd.exe -ArgumentList '/k cd /d %~dp0 & call "\"Launch RVC.bat"\" Administrator' -Verb RunAs"
  exit
)

cls
title "Launch RVC"

if not "%2"=="Launcher" (
  if not exist ".\RVC" (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/k cd /d %~dp0 & call "\"Full Install & Reinstall.bat"\" Administrator Launcher' -Verb RunAs"
    exit
  )

  if not exist ".\Miniconda" (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/k cd /d %~dp0 & call "\"Full Install & Reinstall.bat"\" Administrator Launcher' -Verb RunAs"
    exit
  )
)

:mode_selection
cls
echo POSSIBLE MODES:
echo 1. Train and Inference
echo 2. Real-Time Inference
set /p "choice=SELECT MODE BY TYPING '1' or '2': "
if /i "%choice%"=="1" (
    cls    
    echo You Selected "Train & Inference"
    cd RVC
    call "go-web.bat"
) else if /i "%choice%"=="2" (
    cls
    echo You Selected "Real-Time Inference"
    cd RVC
    call "go-realtime-gui.bat"
) else (
    goto mode_selection
)