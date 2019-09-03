$LogTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"

#  Log file name:
$Path = 'C:\Temp\'+"JSON_FileShare.log"

$path = $Path
$raw = Get-Content $path -raw

$obj = ConvertFrom-Json $raw
$obj.Current = $LogTime
$obj.Sucessful = $LogTime    

Write-Host $obj   

Set-Content $path $obj



