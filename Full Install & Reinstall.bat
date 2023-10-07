@echo off

if not "%1"=="Administrator" (
  powershell -Command "Start-Process cmd.exe -ArgumentList '/k cd /d %~dp0 & call "\"Full Install & Reinstall.bat"\" Administrator' -Verb RunAs"
  exit
)

cls
title "Full Install & Reinstall - Warning"
mode con:cols=71 lines=12
color 4
echo  =====================================================================
echo                                [WARNING]
echo.
echo    This operation will remove ALL files and folders in the current 
echo    directory where this script is located. 
echo.
echo    PLEASE ENSURE this script is not placed in a directory containing
echo    important files and folders as they will be PERMANENTLY DELETED.
echo.
echo  =====================================================================
echo.

set /p "choice=To continue type in the phrase: 'Yes, do as I say!': "
if /i not "%choice%"=="Yes, do as I say!" goto terminate

cls
title "Full Install & Reinstall - In Progress"
mode con:cols=120 lines=30
color 7
echo Starting Installation / Reinstallation

for %%F in ("%~dp0*.*") do (
    if not "%%~nxF"=="Full Install & Reinstall.bat" if not "%%~nxF"=="Launch RVC.bat" if not "%%~nxF"=="README.md" del "%%F"
)
for /d %%D in ("%~dp0*") do (
    if /i not "%%~nxD"==".git" rd /s /q "%%D"
)

mkdir "Temporary Files"
bitsadmin /transfer "Download Microsoft Visual C++ Redistributable" /download /priority normal "https://aka.ms/vs/17/release/vc_redist.x64.exe" "%~dp0\Temporary Files\vc_redist.x64.exe"
start /wait "" ".\Temporary Files\vc_redist.x64.exe" /install /quiet /norestart
rd /s /q ".\Temporary Files"

mkdir "Temporary Files"
bitsadmin /transfer "Download Miniconda" /download /priority normal "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe" "%~dp0\Temporary Files\Miniconda3-latest-Windows-x86_64.exe"
start /wait "" ".\Temporary Files\Miniconda3-latest-Windows-x86_64.exe" /InstallationType=JustMe /AddToPath=0 /RegisterPython=0 /S /D=%cd%\Miniconda
rd /s /q ".\Temporary Files"

echo y | .\Miniconda\Scripts\conda.exe create --prefix .\Miniconda\envs python=3.10
CALL .\Miniconda\Scripts\activate.bat .\Miniconda\envs

echo y | .\Miniconda\Scripts\conda.exe install git==2.41.0 -c conda-forge
echo y | .\Miniconda\Scripts\conda.exe install ffmpeg==6.0.0 -c conda-forge
echo y | .\Miniconda\Scripts\conda.exe install cudatoolkit==11.8.0 -c conda-forge
echo y | .\Miniconda\Scripts\conda.exe install pytorch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 pytorch-cuda==11.8.0 -c pytorch -c nvidia

git clone https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI.git RVC
git -C RVC checkout 9f2f0559e6932c10c48642d404e7d2e771d9db43

if exist ".\RVC\go-web_temporary.bat" del /f /q ".\RVC\go-web_temporary.bat"
for /f "delims=: tokens=1,*" %%a in ('findstr /n .* ".\RVC\go-web.bat"') do (
    if "%%a"=="1" (
        echo...\Miniconda\envs\python.exe infer-web.py --pycmd ..\Miniconda\envs\python.exe --port 7897 --noautoopen >>".\RVC\go-web_temporary.bat"
    ) else (
        echo.%%b >>".\RVC\go-web_temporary.bat"
    )
)
move /y ".\RVC\go-web_temporary.bat" ".\RVC\go-web.bat"

if exist ".\RVC\go-realtime-gui_temporary.bat" del /f /q ".\RVC\go-realtime-gui_temporary.bat"
for /f "delims=: tokens=1,*" %%a in ('findstr /n .* ".\RVC\go-realtime-gui.bat"') do (
    if "%%a"=="1" (
        echo...\Miniconda\envs\python.exe gui_v1.py >>".\RVC\go-realtime-gui_temporary.bat"
    ) else (
        echo.%%b >>".\RVC\go-realtime-gui_temporary.bat"
    )
)
move /y ".\RVC\go-realtime-gui_temporary.bat" ".\RVC\go-realtime-gui.bat"

if exist ".\RVC\infer\modules\uvr5\modules_temp.py" del /f /q ".\RVC\infer\modules\uvr5\modules_temp.py"
for /f "delims=: tokens=1,*" %%a in ('findstr /n .* ".\RVC\infer\modules\uvr5\modules.py"') do (
    if "%%a"=="1" (
        echo.%%b>>".\RVC\infer\modules\uvr5\modules_temp.py"
        echo.import shutil>>".\RVC\infer\modules\uvr5\modules_temp.py"
    ) else if "%%a"=="44" (
        echo.%%b>>".\RVC\infer\modules\uvr5\modules_temp.py"
        (
            echo             shutil.move^(inp_path, os.path.abspath^(^"./") + "/TEMP/" + os.path.basename(inp_path) + ".reformatted.wav")
        ) >".\RVC\infer\modules\uvr5\line_temp.txt"
        type ".\RVC\infer\modules\uvr5\line_temp.txt" >>".\RVC\infer\modules\uvr5\modules_temp.py"
    ) else if "%%a"=="73" (
        echo.                    pre_fun._path_audio_(>>".\RVC\infer\modules\uvr5\modules_temp.py"
    ) else if "%%a"=="94" (
        echo.%%b>>".\RVC\infer\modules\uvr5\modules_temp.py"
        (
            echo         os.remove^(os.path.abspath^(^"./") + "/TEMP/" + os.path.basename(inp_path))
        ) >".\RVC\infer\modules\uvr5\line_temp.txt"
        type ".\RVC\infer\modules\uvr5\line_temp.txt" >>".\RVC\infer\modules\uvr5\modules_temp.py"
    ) else (
        echo.%%b>>".\RVC\infer\modules\uvr5\modules_temp.py"
    )
)
move /y ".\RVC\infer\modules\uvr5\modules_temp.py" ".\RVC\infer\modules\uvr5\modules.py"
if exist ".\RVC\infer\modules\uvr5\line_temp.txt" del /f /q ".\RVC\infer\modules\uvr5\line_temp.txt"

echo y | pip install -r ".\RVC\requirements.txt"
echo y | pip install -r ".\RVC\requirements-win-for-realtime_vc_gui.txt"

bitsadmin /transfer "Download 'hubert_base.pt'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/hubert_base.pt" "%~dp0\RVC\assets\hubert\hubert_base.pt"

bitsadmin /transfer "Download 'D32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/D32k.pth" "%~dp0\RVC\assets\pretrained\D32k.pth"
bitsadmin /transfer "Download 'D40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/D40k.pth" "%~dp0\RVC\assets\pretrained\D40k.pth"
bitsadmin /transfer "Download 'D48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/D48k.pth" "%~dp0\RVC\assets\pretrained\D48k.pth"
bitsadmin /transfer "Download 'G32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/G32k.pth" "%~dp0\RVC\assets\pretrained\G32k.pth"
bitsadmin /transfer "Download 'G40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/G40k.pth" "%~dp0\RVC\assets\pretrained\G40k.pth"
bitsadmin /transfer "Download 'G48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/G48k.pth" "%~dp0\RVC\assets\pretrained\G48k.pth"
bitsadmin /transfer "Download 'f0D32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0D32k.pth" "%~dp0\RVC\assets\pretrained\f0D32k.pth"
bitsadmin /transfer "Download 'f0D40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0D40k.pth" "%~dp0\RVC\assets\pretrained\f0D40k.pth"
bitsadmin /transfer "Download 'f0D48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0D48k.pth" "%~dp0\RVC\assets\pretrained\f0D48k.pth"
bitsadmin /transfer "Download 'f0G32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0G32k.pth" "%~dp0\RVC\assets\pretrained\f0G32k.pth"
bitsadmin /transfer "Download 'f0G40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0G40k.pth" "%~dp0\RVC\assets\pretrained\f0G40k.pth"
bitsadmin /transfer "Download 'f0G48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained/f0G48k.pth" "%~dp0\RVC\assets\pretrained\f0G48k.pth"

bitsadmin /transfer "Download 'HP2-人声vocals+非人声instrumentals.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP2-%E4%BA%BA%E5%A3%B0vocals%2B%E9%9D%9E%E4%BA%BA%E5%A3%B0instrumentals.pth" "%~dp0\RVC\assets\uvr5_weights\HP2-人声vocals+非人声instrumentals.pth"
bitsadmin /transfer "Download 'HP2_all_vocals.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP2_all_vocals.pth" "%~dp0\RVC\assets\uvr5_weights\HP2_all_vocals.pth"
bitsadmin /transfer "Download 'HP3_all_vocals.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP3_all_vocals.pth" "%~dp0\RVC\assets\uvr5_weights\HP3_all_vocals.pth"
bitsadmin /transfer "Download 'HP5-主旋律人声vocals+其他instrumentals.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP5-%E4%B8%BB%E6%97%8B%E5%BE%8B%E4%BA%BA%E5%A3%B0vocals%2B%E5%85%B6%E4%BB%96instrumentals.pth" "%~dp0\RVC\assets\uvr5_weights\HP5-主旋律人声vocals+其他instrumentals.pth"
bitsadmin /transfer "Download 'HP5_only_main_vocal.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/HP5_only_main_vocal.pth" "%~dp0\RVC\assets\uvr5_weights\HP5_only_main_vocal.pth"
bitsadmin /transfer "Download 'VR-DeEchoAggressive.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/VR-DeEchoAggressive.pth" "%~dp0\RVC\assets\uvr5_weights\VR-DeEchoAggressive.pth"
bitsadmin /transfer "Download 'VR-DeEchoDeReverb.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/VR-DeEchoDeReverb.pth" "%~dp0\RVC\assets\uvr5_weights\VR-DeEchoDeReverb.pth"
bitsadmin /transfer "Download 'VR-DeEchoNormal.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/uvr5_weights/VR-DeEchoNormal.pth" "%~dp0\RVC\assets\uvr5_weights\VR-DeEchoNormal.pth"

bitsadmin /transfer "Download 'D32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/D32k.pth" "%~dp0\RVC\assets\pretrained_v2\D32k.pth"
bitsadmin /transfer "Download 'D40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/D40k.pth" "%~dp0\RVC\assets\pretrained_v2\D40k.pth"
bitsadmin /transfer "Download 'D48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/D48k.pth" "%~dp0\RVC\assets\pretrained_v2\D48k.pth"
bitsadmin /transfer "Download 'G32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/G32k.pth" "%~dp0\RVC\assets\pretrained_v2\G32k.pth"
bitsadmin /transfer "Download 'G40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/G40k.pth" "%~dp0\RVC\assets\pretrained_v2\G40k.pth"
bitsadmin /transfer "Download 'G48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/G48k.pth" "%~dp0\RVC\assets\pretrained_v2\G48k.pth"
bitsadmin /transfer "Download 'f0D32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0D32k.pth" "%~dp0\RVC\assets\pretrained_v2\f0D32k.pth"
bitsadmin /transfer "Download 'f0D40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0D40k.pth" "%~dp0\RVC\assets\pretrained_v2\f0D40k.pth"
bitsadmin /transfer "Download 'f0D48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0D48k.pth" "%~dp0\RVC\assets\pretrained_v2\f0D48k.pth"
bitsadmin /transfer "Download 'f0G32k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0G32k.pth" "%~dp0\RVC\assets\pretrained_v2\f0G32k.pth"
bitsadmin /transfer "Download 'f0G40k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0G40k.pth" "%~dp0\RVC\assets\pretrained_v2\f0G40k.pth"
bitsadmin /transfer "Download 'f0G48k.pth'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/pretrained_v2/f0G48k.pth" "%~dp0\RVC\assets\pretrained_v2\f0G48k.pth"

bitsadmin /transfer "Download 'ffmpeg.exe'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/ffmpeg.exe" "%~dp0\RVC\ffmpeg.exe"

bitsadmin /transfer "Download 'ffprobe.exe'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/ffprobe.exe" "%~dp0\RVC\ffprobe.exe"

bitsadmin /transfer "Download 'rmvpe.pt'" /download /priority normal "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/rmvpe.pt" "%~dp0\RVC\assets\rmvpe\rmvpe.pt"

cls
title "Full Install & Reinstall - Completed"
mode con:cols=71 lines=9
color 2
echo  =====================================================================
echo                               [COMPLETED]
echo.
echo               The installation has successfully completed.
echo.
echo          This window will close automatically after 10 seconds.
echo.
echo  =====================================================================
timeout /t 10 /nobreak > nul
if "%2"=="Launcher" (
  powershell -Command "Start-Process cmd.exe -ArgumentList '/k cd /d %~dp0 & call "\"Launch RVC.bat"\" Administrator Launcher' -Verb RunAs"
)
exit

:terminate
cls
title "Full Install & Reinstall - Terminated"
mode con:cols=71 lines=11
color 6
echo  =====================================================================
echo                              [TERMINATED]
echo.
echo            You have chosen not to proceed with the operation.
echo.
echo                Your files and folders were NOT affected.
echo.
echo          This window will close automatically after 10 seconds.
echo.
echo  =====================================================================
timeout /t 10 /nobreak > nul
exit