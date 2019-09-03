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
              
robocopy.exe C:\Testing\backup C:\Testing\NewLocation  /MAXAGE:20190830 /ZB /COPYALL /MIR /R:2 /V /NP /Tee /LOG:$LogFile