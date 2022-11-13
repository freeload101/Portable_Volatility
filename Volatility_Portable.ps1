<# 
-RedirectStandardOutput RedirectStandardOutput.txt -RedirectStandardError RedirectStandardError.txt
start RedirectStandardOutput.txt 
start RedirectStandardError.txt

TODO: 
*warn about existing python env ...
* check for existing python env
* delete files:
c:\users\administrator\appdata\local\pip
c:\users\administrator\appdata\roaming\python\


#> 

# set current directory
$VARCD = (Get-Location)

Set-Location -Path "$VARCD"
Write-Host "`n[+] Current Working Directory $VARCD"
 
# env 
# Path python
$env:Path = "$env:Path;$VARCD\python\tools\Scripts;$VARCD\python\tools;python\tools\Lib\site-packages"
 
# python
$env:PYTHONHOME="$VARCD\python\tools"
$env:PYTHONPATH="$VARCD\python\tools\Lib\site-packages"

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

################################# FUNCTIONS


############# downloadFile
function downloadFile($url, $targetFile)
{
    Write-Host "`n[+] Downloading $url"
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 10KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0)
    {
        #[System.Console]::CursorLeft = 0
        #[System.Console]::Write("`nDownloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
    }
   Write-Host "`n[+] Finished Download"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

############# CompileVol
function CompileVol
{
    Write-Host "[+] Building Volatility" 
    Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\volatility3-develop\" -ArgumentList " setup.py build " -wait -NoNewWindow
    Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\volatility3-develop\" -ArgumentList " setup.py install " -wait -NoNewWindow

    Write-Host "`n[+] Current Working Directory $VARCD\volatility3-develop\volatility3"
    Start-Process -FilePath "$VARCD\python\tools\Scripts\pyinstaller.exe" -WorkingDirectory "$VARCD\volatility3-develop\volatility3" -ArgumentList "  --upx-dir `"$VARCD\upx-3.96-win64`" ..\vol.spec " -wait -NoNewWindow
    
    Write-Host "[+] Downloading Volatility Symbols ~800MB" 
    downloadFile "https://downloads.volatilityfoundation.org/volatility3/symbols/windows.zip" "$VARCD\windows.zip"
    New-Item -Path "$VARCD\volatility3-develop\volatility3\dist\symbols" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null

    Write-Host "`n[+] Extracting Volatility Symbols"    
    [System.IO.Compression.ZipFile]::ExtractToDirectory( "$VARCD\windows.zip", "$VARCD\volatility3-develop\volatility3\dist\symbols")


}

############# CHECK PYTHON
Function CheckPython {
   if (-not(Test-Path -Path "$VARCD\python" )) { 
        try {
            Write-Host "[+] Downloading Python nuget package" 
            downloadFile "https://www.nuget.org/api/v2/package/python/3.7.8" "$VARCD\python.zip"
            New-Item -Path "$VARCD\python" -ItemType Directory  -ErrorAction SilentlyContinue |Out-Null
            Write-Host "[+] Extracting Python nuget package" 
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            Add-Type -AssemblyName System.IO.Compression
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\python.zip", "$VARCD\python")

            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install install --upgrade pip " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install wheel " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install pyinstaller " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install pefile " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install capstone " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install pycryptodome " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install leechcorepyc " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install python-snappy==0.6.0 " -wait -NoNewWindow
            Start-Process -FilePath "$VARCD\python\tools\python.exe" -WorkingDirectory "$VARCD\python\tools" -ArgumentList " -m pip install yara-python " -wait -NoNewWindow
            
            }
                catch {
                    throw $_.Exception.Message
                }
            }
        else {
            Write-Host "[+] $VARCD\python already exists"
            }
} 


### MAIN ###

Write-Host "`n[+] Downloading volatility3"
downloadFile "https://github.com/volatilityfoundation/volatility3/archive/refs/heads/develop.zip" "$VARCD\develop.zip"
[System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\develop.zip", "$VARCD\")

Write-Host "`n[+] Downloading upx-3.96-win64.zip"
downloadFile "https://github.com/upx/upx/releases/download/v3.96/upx-3.96-win64.zip" "$VARCD\upx.zip"
[System.IO.Compression.ZipFile]::ExtractToDirectory("$VARCD\upx.zip", "$VARCD\")

CheckPython
CompileVol

Write-Host "`n[+] Complete opening volatility3 folder"
explorer "$VARCD\volatility3-develop\volatility3\dist"