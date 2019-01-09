#requires -version 2
<#
.SYNOPSIS
	Deletes log files that have already been parsed.
.DESCRIPTION
	This script deletes logfiles that have already been parsed by the ParseLogFiles.ps1 script. 
	
	This is a non-interactive script and can be run as a scheduled task. 
	
.NOTES
	Version:		1.0
	Author:			Robbie Crash
	Written: 		2014-09-14
	Version Notes:	Initial script.
	
.LINK
	https://robbiecrash.me/scriptz/CleanOldLogs.ps1
#>
$StillToDelete = @()
$DeleteList = "L:\DeletableLogs.txt"
$DeletableLogs = get-content $DeleteList

Function Close-LockedFile{
Param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][String[]]$Filename
)
Begin{
    $HandleApp = 'C:\sysinternals\Handle64.exe'
    If(!(Test-Path $HandleApp)){Write-Host "Handle.exe not found at $HandleApp`nPlease download it from www.sysinternals.com and save it in the afore mentioned location.";break}
}
Process{
    $HandleOut = Invoke-Expression ($HandleApp+' '+$Filename)
    $Locks = $HandleOut |?{$_ -match "(.+?)\s+pid: (\d+?)\s+type: File\s+(\w+?): (.+)\s*$"}|%{
        [PSCustomObject]@{
            'AppName' = $Matches[1]
            'PID' = $Matches[2]
            'FileHandle' = $Matches[3]
            'FilePath' = $Matches[4]
        }
    }
    ForEach($Lock in $Locks){
        Invoke-Expression ($HandleApp + " -p " + $Lock.PID + " -c " + $Lock.FileHandle + " -y") | Out-Null
    If ( ! $LastexitCode ) { "Successfully closed " + $Lock.AppName + "'s lock on " + $Lock.FilePath}
    }
}
}

foreach ($log in $DeletableLogs) {
	try {
		remove-item $log -ErrorAction stop
		}
	catch [System.Management.Automation.ItemNotFoundException]{
			continue
		}
	catch [system.IO.IOException]{
		try {
			Close-LockedFile $log
			remote-item $log -ErrorAction stop
			}
		catch [exception]{
			$StillToDelete += $log
			}
		}
	}

write-output $StillToDelete > $DeleteList
exit
