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

#$SourceDir= "C:\Testing\backup"
$SourceDir=  "C:\Windows\System32"
$DestDir= "C:\Testing\NewLocation14"
$OpsFile = 'C:\Temp\'+"Ops_LogTime.json"
$logFile = 'C:\Temp\'+"JSON_FileShare_$LogTime.log"
$RefDate = '20000101'
$Sucess = "Sucessfull Operation"
$Running = "Running"
$ErrorMsg = "Error"
$Successful = "Successful"
$Current = "Current"
$Status = "Status"

Function InitJson ()
{
    $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

    if ($file.Successful -eq ""){
        # --- Json file needs update
        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
        $file.Successful = $RefDate 
        
        # Close the json file
        $file | ConvertTo-Json | Out-File -FilePath $OpsFile -Encoding utf8 -Force
    }
}


Function ReadJson ()
{
    #  Read the Record file name for Sucessful timestamp
    $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

    Return $file.Successful 
}

Function WriteJson ([String] $Value ,
                    [String] $OpsStatus,
                    [String] $Msg)
{
    $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

    if ($OpsStatus -eq $Sucess){
        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
        $file.Successful = $Value 
        $file.Current = $Value 
        $file.Status = $Sucess

    }
    elseif ($OpsStatus -eq $Running){
        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
        $file.Current = $Value 
        $file.Status = $Running

    }else{
       # the operation was not sucess. Set current only the today's date to indicate a failure. The next run, will use sucessful to carry on.
        $file.Current = $Value 
        $file.Status = $Msg
    }

    # Close the json file
    $file | ConvertTo-Json | Out-File -FilePath $OpsFile -Encoding utf8 -Force
}




try{
    #--- Make sure flags are reset
    InitJson

    # Read the last sucessful timestamp
    $SucessTime = ReadJson 
    # --- By inclusing /MT:32, we are dicating a thread of 32. to change the number of retries, use the /R switch, 
    #and to change the wait time between retries, use the /W switch. 

    # --- Set the start point of the process
    WriteJson $LogTime $Running 

    #throw [System.IO.FileNotFoundException] "$A fuilure has occured."
    robocopy.exe $SourceDir $DestDir  /MAXAGE:$SucessTime /ZB /COPYALL /MIR /V /NP  /R:1 /W:1 /B /MT:132 /Tee /LOG:$LogFile
 if ($lastexitcode -eq 0)
 {
      write-host "Robocopy succeeded"
 }
else
{
      write-host "Robocopy failed with exit code:" $lastexitcode
}
    $LogTime = (Get-Date).ToString('yyyyMMdd')
    #
    WriteJson $LogTime $Sucess
}
catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException]
{
    # there was a failure. 
    $LogTime = (Get-Date).ToString('yyyyMMdd')
    WriteJson $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"
    
}
catch [System.IO.IOException]
{
    # there was a failure. 
    $LogTime = (Get-Date).ToString('yyyyMMdd')
    WriteJson $LogTime $false  "$ErrorMsg :Date-$LogTime , IO error exception has occured."
    

}
# --- General Error
catch {
        
    # there was a failure. 
    $LogTime = (Get-Date).ToString('yyyyMMdd')
    WriteJson $LogTime $false  "$ErrorMsg :Date-$LogTime , Robocopy operation resulted in an error."
        
}


