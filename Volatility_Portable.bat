@echo off
Setlocal EnableDelayedExpansion EnableExtensions

echo '-----------------------------------------------------------------------------------------'
echo 'Volatility Portable Builder'
echo 'ver 1.0a'
echo '-----------------------------------------------------------------------------------------'
:: WARNING
:: IF YOU UPDATE THEY PYTHON VERSION FROM 39 YOU NEED TO CHANGE THE PATH SETTING

:: INIT
cd "%~dp0"
set BASE=%~dp0
:: LOCAL CMD TESTING set BASE=%CD%\
:: LOCAL CMD TESTING set PATH=%LOCALAPPDATA%\Programs\Python\Python37\Scripts\;%LOCALAPPDATA%\Programs\Python\Python37\;%LOCALAPPDATA%\Programs\Python\Launcher\;
cd "%BASE%"

echo %date% %time% INFO: Downloading Python
powershell "(New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.7.8/python-3.7.8rc1-amd64.exe', \"%BASE%python_install.exe\")" 

:: DONT TOUCH PYTHON echo %date% %time% INFO: Uninstalling Python
:: DONT TOUCH PYTHON "%BASE%python_install.exe" /uninstall /quiet

:: DONT TOUCH PYTHON echo %date% %time% INFO: Waiting 60 seconds for uninstall
:: DONT TOUCH PYTHON CHOICE /T 60 /C y /CS /D y 1>> output.log 2>&1

:: DONT TOUCH PYTHON echo %date% %time% INFO: Cleaning up Python folder
:: DONT TOUCH PYTHON rd /q/s "%LOCALAPPDATA%\Programs\Python"
:: DONT TOUCH PYTHON rd /q/s "%USERPROFILE%\AppData\Roaming\pyinstaller"

echo %date% %time% INFO: Installing Python
"%BASE%python_install.exe" /quiet InstallAllUsers=0 Include_launcher=1 Include_test=0  SimpleInstall=1 Include_pip=1 Include_launcher=1 SimpleInstallDescription="Volatility Portable"

:: https://docs.python.org/3/using/windows.html

CHOICE /T 5 /C y /CS /D y 1>> output.log 2>&1

echo %date% %time% INFO: Setting Path for Python 37
set PATH=C:\WINDOWS\system32;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;%LOCALAPPDATA%\Programs\Python\Python37\Scripts\;%LOCALAPPDATA%\Programs\Python\Python37\;%LOCALAPPDATA%\Python\Launcher\;
set PYTHONPATH=%LOCALAPPDATA%\Programs\Python\Python37


echo %date% %time% INFO: Downloading Volatility3
powershell "(New-Object Net.WebClient).DownloadFile('https://github.com/volatilityfoundation/volatility3/archive/refs/heads/develop.zip', \"%BASE%develop.zip\")" 

echo %date% %time% INFO: Extracting Volatility3 zip file the FAST WAY
powershell  -command "& {Add-Type -Assembly "System.IO.Compression.Filesystem"; [System.IO.Compression.ZipFile]::ExtractToDirectory(\"%BASE%develop.zip\",  \"%BASE%\\")  }" 1>> output.log 2>&1

echo %date% %time% INFO: Updating pip
pip install --upgrade pip

echo %date% %time% INFO: Installing wheel pip package
pip install wheel --user

echo %date% %time% INFO: Installing Volatility3 requirements.txt
cd "%BASE%volatility3-develop"
pip install -r requirements.txt

echo %date% %time% INFO: Downloadinig latest Pyinstaller
pip install pyinstaller
 
:: DONT NEED IT ? echo %date% %time% INFO: Downloadinig latest Pyinstaller
:: DONT NEED IT ? powershell "(New-Object Net.WebClient).DownloadFile('https://github.com/pyinstaller/pyinstaller/archive/refs/heads/develop.zip', \"%BASE%develop_pyinstaller.zip\")" 
:: DONT NEED IT ? powershell  -command "& {Add-Type -Assembly "System.IO.Compression.Filesystem"; [System.IO.Compression.ZipFile]::ExtractToDirectory(\"%BASE%develop_pyinstaller.zip\",  \"%BASE%\\")  }" 1>> output.log 2>&1

:: DONT NEED IT ? echo %date% %time% INFO: Installing  latest Pyinstaller
:: DONT NEED IT ? cd "%BASE%pyinstaller-develop\"
:: DONT NEED IT ? pip install -r requirements.txt
:: DONT NEED IT ? python setup.py install

echo %date% %time% INFO: Downloading upx-3.96-win64.zip
powershell "(New-Object Net.WebClient).DownloadFile('https://github.com/upx/upx/releases/download/v3.96/upx-3.96-win64.zip', \"%BASE%upx.zip\")" 
powershell  -command "& {Add-Type -Assembly "System.IO.Compression.Filesystem"; [System.IO.Compression.ZipFile]::ExtractToDirectory(\"%BASE%upx.zip\",  \"%BASE%\\")  }" 1>> output.log 2>&1


echo %date% %time% INFO: Installing Volatility3
python setup.py build 1>> output.log 2>&1 
python setup.py install 1>> output.log 2>&1

echo %date% %time% INFO: Compiling Volatility3
cd "%BASE%volatility3-develop\volatility3\"
pyinstaller  --upx-dir "%BASE%upx-3.96-win64" ..\vol.spec 1>> output.log 2>&1


"C:\Windows\explorer.exe" "%BASE%volatility3-develop\volatility3\dist\"

echo %date% %time% INFO: Download Volatility3 Symbols ( like 800 megs )
cd "%BASE%volatility3-develop\volatility3\dist"
powershell "(New-Object Net.WebClient).DownloadFile('https://downloads.volatilityfoundation.org/volatility3/symbols/windows.zip', \"%BASE%windows.zip\")" 

echo %date% %time% INFO: Extracting Volatility3 Symbols FAST WAY
rd /q/s "%BASE%volatility3-develop\volatility3\dist\symbols\windows" 1>> output.log 2>&1
mkdir "%BASE%volatility3-develop\volatility3\dist\symbols"
powershell  -command "& {Add-Type -Assembly "System.IO.Compression.Filesystem"; [System.IO.Compression.ZipFile]::ExtractToDirectory(\"%BASE%windows.zip\",  \"%BASE%\volatility3-develop\volatility3\dist\symbols\")  }" 1>> output.log 2>&1




echo "Example Usage :"
echo ".\vol.exe -s .\symbols\ -f memory.dump hashdump"



pause
