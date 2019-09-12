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

$OpsFile = "Ops_LogTime.json"
$FolderPath=Get-Location
$OpsFile = "$PSScriptRoot\$OpsFile"
$logFile = "_JSON_FileShare_$LogTime.log"
$LogTime = (Get-Date).ToString('yyyyMMdd')
$MainLogFile = "MainLog_$LogTime.log" 
$LogfileDir = 'C:\temp\RoboCopyLogs\'
$RefDate = '18710101'
$TempSource = '\\svcdr\g$\svnatt\2016\F\DATA'

$MainLogFile = $LogfileDir + $MainLogFile
enum OpsStatus
{
    Complete
    Running
    Stopped
    Exception
    Warnings
    Error
}

function GetRoboCopyCodeDsc ([string] $errCode){
    try{
        switch ( $errCode )
        {
            0 {$result = 'No errors occurred, and no copying was done. The source and destination directory trees are completely synchronized.'} 
            1 {$result = 'One or more files were copied successfully (that is, new files have arrived).'}
            2 {$result = 'Some Extra files or directories were detected. No files were copied Examine the output log for details. '}
            3 {$result = 'Some files were copied. Additional files were present. No failure was encountered.'}
            4 {$result = 'Some Mismatched files or directories were detected. Examine the output log. Housekeeping might be required.'}
            5 {$result = 'Some files were copied. Some files were mismatched. No failure was encountered.'}
            6 {$result = 'Additional files and mismatched files exist. No files were copied and no failures were encountered. This means that the files already exist in the destination directory'}
            7 {$result = 'Files were copied, a file mismatch was present, and additional files were present.'}
            8 {$result = 'Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded). Check these errors further.'}
            16 {$result = 'Serious error. Robocopy did not copy any files.Either a usage error or an error due to insufficient access privileges on the source or destination directories.'}
            default { $result ='Unknown Error code' }
        }
    WriteMainLog $SvrName "GetRoboCopyCodeDsc" $LogTime ([OpsStatus]::Complete) $lastexitcode "Successful operation."
    return $result 
   }

   catch{
        WriteJson $ServerName $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"        
        WriteMainLog $SvrName "GetRoboCopyCodeDsc" $LogTime ([OpsStatus]::Exception) $lastexitcode "The operation resulted in an error."
    }
}


Function InitJson ([String] $ServerName)
{
    try{
        
        $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

        foreach ($property in $file.PSObject.Properties) {

            if ($property.Value.Successful -eq ""){
                # --- Json file needs update
                # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
                $property.Value.Successful = $RefDate 
        
            }
        }
        # Close the json file
        $file | ConvertTo-Json | Out-File -FilePath $OpsFile -Encoding utf8 -Force
        WriteMainLog $SvrName "InitJson" $LogTime ([OpsStatus]::Complete) $lastexitcode "Successful operation."
    }
    catch {
        WriteJson $ServerName $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"        
        WriteMainLog $SvrName "InitJson" $LogTime ([OpsStatus]::Exception) $lastexitcode "The operation resulted in an error."
    }
}

Function ReadJson ([String] $ServerName)
{
    try{
        #  Read the Record file name for Sucessful timestamp
        $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)
        WriteMainLog $SvrName "ReadJson" $LogTime ([OpsStatus]::Complete) $lastexitcode "Successful operation."
        Return $file.Successful 
    }
    catch {
        WriteJson $ServerName $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"        
        WriteMainLog $SvrName "ReadJson" $LogTime ([OpsStatus]::Exception) $lastexitcode "The operation resulted in an error."
    }
}

Function WriteJson ([String] $ServerName,
                    [String] $myUUID ,
                    [String] $Value ,
                    [String] $OpsStatus,
                    [String] $ErrCode,
                    [string] $RoboCopyErrDesc,
                    [String] $Msg
                    )
{
    try{
        $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

           foreach ($property in $file.PSObject.Properties) {

                if ($property.Value.ServerName -eq $ServerName){

                    if ($OpsStatus -eq ([OpsStatus]::Complete)){
                        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
                        $property.Value.UUID = $myUUID
                        $property.Value.Successful = $Value 
                        $property.Value.Current = $Value 
                        $property.Value.Status = $Sucess
                        $property.Value.RoboCopyErrDesc = $RoboCopyErrDesc

                    }
                    elseif ($OpsStatus -eq ([OpsStatus]::Running)){
                        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
                        $property.Value.UUID = $myUUID
                        $property.Value.Current = $Value 
                        $property.Value.Status = $Running
                        $property.Value.RoboCopyErrDesc = $RoboCopyErrDesc

                    }else{
                       # the operation was not sucess. Set current only the today's date to indicate a failure. The next run, will use sucessful to carry on.
                        $property.Value.Current = $Value 
                        $property.Value.Status = $OpsStatus
                        $property.Value.RoboCopyExitCode = $ErrCode
                        $property.Value.RoboCopyErrDesc = $RoboCopyErrDesc
                        $property.Value.OpsErrDesc = $Msg
                    }

                }
            }
            # Close the json file
            $file | ConvertTo-Json | Out-File -FilePath $OpsFile -Encoding utf8 -Force
            WriteMainLog $SvrName "WriteJson" $LogTime ([OpsStatus]::Complete) $lastexitcode "Successful operation."
    }
    catch {
        WriteJson $ServerName $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"        
        WriteMainLog $SvrName "WriteJson" $LogTime ([OpsStatus]::Exception) $lastexitcode "The operation resulted in an error."
    }
}

Function WriteMainLog ([String] $ServerName,
                    [String] $Function_ModuleName ,
                    [String] $Time ,
                    [String] $OpsStatus,
                    [String] $ErrCode,
                    [String] $Msg
                    )
{
    try{
        $DateTime = (get-date).toString("r")
        $LogMsg  = "TimeStamp: $DateTime  `r`nServer Name:  $ServerName `r`nFunction or Module Name: $Function_ModuleName `r`nStatus: $OpsStatus `r`nPossible Error Code: $ErrCode `r`nMessage: $Msg `r`n+++++++++++++++++++++++++++++++++`r`n+++++++++++++++++++++++++++++++++`r`n+++++++++++++++++++++++++++++++++`r`n+++++++++++++++++++++++++++++++++"

        Add-content $MainLogFile -value $LogMsg
    }
    catch {
        WriteMainLog $SvrName "WriteMainLog" $LogTime ([OpsStatus]::Complete) $lastexitcode "The operation resulted in an error."
    }
}
Function ProcessRoboCopy ([String] $ServerName, [String] $SourceDir , [String] $DestDir)
{

    try{
        # Read the last sucessful timestamp
        $SucessTime = ReadJson 
        # --- By inclusing /MT:32, we are dicating a thread of 32. to change the number of retries, use the /R switch, 
        #and to change the wait time between retries, use the /W switch. 

        # --- Create a new UUID for the RoboCopy instance
        $MyUUID = [guid]::NewGuid()

        $LogTime = (Get-Date).ToString('yyyyMMdd')
        # --- Set the start point of the process
        WriteJson $ServerName $MyUUID  $LogTime ([OpsStatus]::Running) 0 0

         
        $ServerLogFile = $ServerName + "_" + $MyUUID + "_" + $LogFile
        $ServerLogFile = $LogfileDir + $ServerLogFile


        #throw [System.IO.FileNotFoundException] "$A fuilure has occured."
        $DestDir = $DestDir + "$ServerName"
        robocopy.exe $SourceDir $DestDir /COPYALL /MAXAGE:$SucessTime /MAX:100000000 /ZB /W:0 /R:0 /MIR /V /NP /B  /Tee  /XF *.exe *.pst *.vbs /LOG:$ServerLogFile        

        
        $LogTime = (Get-Date).ToString('yyyyMMdd')
        
        $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        if ($lastexitcode -eq 0)
        {
              WriteJson $ServerName $MyUUID $LogTime ([OpsStatus]::Complete) $lastexitcode $lastExitDesc $errMsg
        }
        else
        {
             WriteJson $ServerName $MyUUID $LogTime ([OpsStatus]::Warnings) $lastexitcode $lastExitDesc $errMsg
        }
        WriteMainLog $SvrName "ProcessRoboCopy" $LogTime ([OpsStatus]::Complete) $lastexitcode "Success in the operation of the Processing"
    }
    catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException]
    {
        # there was a failure. 
        $LogTime = (Get-Date).ToString('yyyyMMdd')
         $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        WriteJson $ServerName $LogTime ([OpsStatus]::Exception)  $lastexitcode  $lastExitDesc "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"
        WriteMainLog $SvrName "ProcessRoboCopy" $LogTime ([OpsStatus]::Exception) $lastexitcode "The path or file was not found: [$SourceDir]"
    
    }
    catch [System.IO.IOException]
    {
        # there was a failure. 
        $LogTime = (Get-Date).ToString('yyyyMMdd') 
        $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        WriteJson $ServerName $LogTime ([OpsStatus]::Exception)   $lastexitcode $lastExitDesc "$ErrorMsg :Date-$LogTime , IO error exception has occured."
        WriteMainLog $SvrName "ProcessRoboCopy" $LogTime ([OpsStatus]::Exception) $lastexitcode "IO error exception has occured."

    }
    # --- General Error
    catch {
         $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        # there was a failure. 
        $LogTime = (Get-Date).ToString('yyyyMMdd')
        WriteJson $ServerName $LogTime ([OpsStatus]::Exception)   $lastexitcode  $lastExitDesc "$ErrorMsg :Date-$LogTime , Robocopy operation resulted in an error."
        WriteMainLog $SvrName "ProcessRoboCopy" $LogTime ([OpsStatus]::Exception) $lastexitcode "Robocopy operation resulted in an error."
    }
}

try{
    # --- Check the initialization of the json values
    InitJson $OpsFile

    # Get file and set som vars

    $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)
 
    foreach ($property in $file.PSObject.Properties) {
 
           $SvrName = $property.Value.ServerName
          # $SourceDir = $property.Value.SourceDir
           $SourceDir =$TempSource
           $DestDir = $property.Value.DestDir
           # Looping through the list of servers within the json file and call the RoboProcess 
           ProcessRoboCopy $SvrName $SourceDir $DestDir
           $LogTime = (Get-Date).ToString('yyyyMMdd')
        }
        WriteMainLog $SvrName "MainProcessing Module" $LogTime ([OpsStatus]::Complete) $lastexitcode "Success in the operation of the Processing"
    }
 
catch {
        $LogTime = (Get-Date).ToString('yyyyMMdd')
        WriteMainLog $SvrName "MainProcessing" $LogTime ([OpsStatus]::Exception) $lastexitcode "Robocopy operation resulted in an error."
    }