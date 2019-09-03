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




$SourceDir= "C:\Testing\backup"
$DestDir= "C:\Testing\NewLocation"
$OpsFile = 'C:\Temp\'+"Ops_LogTime.json"
$logFile = 'C:\Temp\'+"JSON_FileShare_$LogTime.log"

Function ReadJson ($Value)
{
    #  Read the Record file name for Sucessful timestamp
    $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

    Return $file.Successful 
}

Function WriteJson ([String] $Value ,
                    [Boolean] $OpsResult)
{
    $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

    if ($OpsResult){
        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
        $file.Successful = $Value 
        $file.Current = $Value 

    }
    else{
       # the operation was not sucess. Set current only to the today's date to indicate a failure. The next run, will use sucessful to carry on.
        $file.Current = $Value 
    }

    # Close the json file
    $file | ConvertTo-Json | Out-File -FilePath $OpsFile -Encoding utf8 -Force
}

try{
    # Read the last sucessful timestamp
    $SucessTime = ReadJson "Current"

    $SucessTime = '{0:yyyyMMdd}' -f $SucessTime

    robocopy.exe C:\Testing\backup C:\Testing\NewLocation  /MAXAGE:"20190730" /ZB /COPYALL /MIR /R:2 /V /NP /Tee /LOG:$LogFile


    $LogTime = Get-Date -Format "yyyymmdd"

    WriteJson $LogTime
}
catch (){
    
}