$LogTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"

$filePath = 'C:\Temp\'+"JSON_FileShare.log"

$file = ([System.IO.File]::ReadAllText($filePath)  | ConvertFrom-Json)

Write-Host $file.Successful


$file.Successful = $LogTime 
$file.Current = $LogTime 

$file | ConvertTo-Json | Out-File -FilePath $filePath -Encoding utf8 -Force



