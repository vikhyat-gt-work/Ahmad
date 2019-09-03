# this is how the current and sucessful should work. The first time the system starts. both are empty. Then, the operation starts and current gets updated. if for any reasons, there is a service 
#intruption here, current and sucessful are different. This means that there is was an operational issue. Once, the operation sucessfully finishes. Both Current and sucessful are set
#to one timestamp. The next operation will first compare sucessful and current. If there is a mismatch, this means that the last operation was a failure. In this case, sucessful is used for processing.
#If there was no mismatch, then, still sucessful is used for comparison. Once, the operation starts, current is updated with the up-to-date timestamp. Once the operation finishes, current and 
#sucessfull are both updated with the up-to-date timestamp.

Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
Write-Output "++++++++++++++++++++++++++++++++"
$LogTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"

#  Log file name:
$LogFile = 'C:\Temp\'+"LOG_"+$LogTime+".log"
              

              $LogTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"

$filePath = 'C:\Temp\'+"JSON_FileShare.log"

$file = ([System.IO.File]::ReadAllText($filePath)  | ConvertFrom-Json)

Write-Host $file.Successful


$file.Successful = $LogTime 
$file.Current = $LogTime 

$file | ConvertTo-Json | Out-File -FilePath $filePath -Encoding utf8 -Force

robocopy.exe C:\Testing\backup C:\Testing\NewLocation  /MAXAGE:20190830 /ZB /COPYALL /MIR /R:2 /V /NP /Tee /LOG:$LogFile