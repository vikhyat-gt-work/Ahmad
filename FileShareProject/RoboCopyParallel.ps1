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
$DestDir= "C:\Testing\NewLocation13"
$OpsFile = 'C:\Temp\'+"Ops_LogTime.json"
$logFile = "_JSON_FileShare_$LogTime.log"
$LogfileDir = 'C:\Temp\' 
$RefDate = '18710101'
$Sucess = "Sucessfull Operation"
$Running = "Running"
$ErrorMsg = "Error"
$Successful = "Successful"
$Current = "Current"
$Status = "Status"
$ServerList  = ""

enum OpsStatus
{
    Complete
    Running
    Stopped
    Exception
    Warnings
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

    return $result 
   }

   catch{
        WriteJson $ServerName $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"        
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
    }
    catch {
        WriteJson $ServerName $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"        
    }
}


Function ReadJson ([String] $ServerName)
{
    #  Read the Record file name for Sucessful timestamp
    $file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)

    Return $file.Successful 
}

Function WriteJson ([String] $ServerName,
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

                    if ($OpsStatus -eq $Sucess){
                        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
                        $property.Value.Successful = $Value 
                        $property.Value.Current = $Value 
                        $property.Value.Status = $Sucess
                        $property.Value.RoboCopyErrDesc = $RoboCopyErrDesc

                    }
                    elseif ($OpsStatus -eq $Running){
                        # the operation was a sucess. Set current and sucessful to the same value indicating the sucess
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
    }
    catch {
        WriteJson $ServerName $LogTime $false  "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"        
    }
}



Function ProcessRoboCopy ([String] $ServerName, [String] $SourceDir , [String] $DestDir)
{

    try{
   

        # Read the last sucessful timestamp
        $SucessTime = ReadJson 
        # --- By inclusing /MT:32, we are dicating a thread of 32. to change the number of retries, use the /R switch, 
        #and to change the wait time between retries, use the /W switch. 

        $LogTime = (Get-Date).ToString('yyyyMMdd')
        # --- Set the start point of the process
        WriteJson $ServerName $LogTime ([OpsStatus]::Running) 0 0

        $ServerLogFile = $ServerName + $LogFile
        $ServerLogFile = $LogfileDir + $ServerLogFile

        #throw [System.IO.FileNotFoundException] "$A fuilure has occured."
        robocopy.exe $SourceDir $DestDir  /MAXAGE:$SucessTime /ZB /COPYALL /MIR /V /NP  /R:1 /W:1 /B /MT:132 /Tee /LOG:$ServerLogFile
        
        $LogTime = (Get-Date).ToString('yyyyMMdd')
        
          $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        if ($lastexitcode -eq 0)
        {
              WriteJson $ServerName $LogTime ([OpsStatus]::Complete) $lastexitcode $lastExitDesc $errMsg
        }
        else
        {
             WriteJson $ServerName $LogTime ([OpsStatus]::Warnings) $lastexitcode $lastExitDesc $errMsg
        }

        
        
    }
    catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException]
    {
        # there was a failure. 
        $LogTime = (Get-Date).ToString('yyyyMMdd')
         $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        WriteJson $ServerName $LogTime ([OpsStatus]::Exception)  $lastexitcode  $lastExitDesc "$ErrorMsg :Date-$LogTime , The path or file was not found: [$SourceDir]"
    
    }
    catch [System.IO.IOException]
    {
        # there was a failure. 
        $LogTime = (Get-Date).ToString('yyyyMMdd') 
        $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        WriteJson $ServerName $LogTime ([OpsStatus]::Exception)   $lastexitcode $lastExitDesc "$ErrorMsg :Date-$LogTime , IO error exception has occured."
    

    }
    # --- General Error
    catch {
         $lastExitDesc = GetRoboCopyCodeDsc  $lastexitcode
        # there was a failure. 
        $LogTime = (Get-Date).ToString('yyyyMMdd')
        WriteJson $ServerName $LogTime ([OpsStatus]::Exception)   $lastexitcode  $lastExitDesc "$ErrorMsg :Date-$LogTime , Robocopy operation resulted in an error."
        
    }


}


# --- Check the initialization of the json values
InitJson $OpsFile

# Get file and set som vars

$file = ([System.IO.File]::ReadAllText($OpsFile)  | ConvertFrom-Json)
 

foreach ($property in $file.PSObject.Properties) {
   
   Write-Output $property.Value.ServerName
   Write-Output $property.Value.Successful
   Write-Output $property.Value.Current
   Write-Output $property.Value.RoboCopyExitCode
   Write-Output $property.Value.ErrDesc
   Write-Output $property.Value.Status

   $SvrName = $property.Value.ServerName
   $SourceDir = $property.Value.SourceDir
   $DestDir = $property.Value.DestDir

   ProcessRoboCopy $SvrName $SourceDir $DestDir
}
 



# --- Here based on the list of servers (read from a text or json file), within a loop, the above function is called that in return will call the operation on each servers.

#foreach($line in Get-Content $logFile) {
#    if($line -match $regex){
        ### Read the content of a json file that holds the names of the servers along with the path to the location of the files on the servers.
        #ProcessRoboCopy $ServerName $SourceDir $DestDir
    #}
#}
