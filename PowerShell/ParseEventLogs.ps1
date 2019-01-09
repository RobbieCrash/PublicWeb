#requires -version 2
<#
.SYNOPSIS
	Finds permissions changes events in the local eventlog
.DESCRIPTION
	Goes through local security logs and finds who changed permissions on what files, what the ACL was, and what it is
	now. Creates a list of logfiles that have been parsed and marks them as ready for deletion. 
	
	This is a non-interactive script and can be run as a scheduled task. 
	
.NOTES
	Version:		1.0
	Author:			Robbie Crash
	Written: 		2014-09-14
	Version Notes:	Initial script.
	
.LINK
	https://robbiecrash.me/scriptz/ParseEventLogs.ps1
#>
$XPath = @'
*[System[Provider/@Name='Microsoft-Windows-Security-Auditing']]
and
*[System/EventID=4670]
'@

$today = (get-date -format g).split()[0]
$DeletableLogs = @()
$logfile = "L:\Permissions Changes\$today.txt"
$DeleteList = "L:\DeletableLogs.txt"
try {
    $ParsedLogs = get-content $DeleteList -erroraction stop
    }
catch [System.Management.Automation.ItemNotFoundException]{}
$AdminUsers = @(List,of,admin,users)

Function LogPermissionChange($PermChanges){
    ForEach($PermChange in $PermChanges){
        $Change = @{}
	$Change.ChangedBy = $PermChange.properties[1].value.tostring()

	# Filter out normal non-admin users to prevent catching people 
	# making their own files.
	if ($AdminUsers -notcontains $Change.ChangedBy){continue} 
	$Change.FileChanged = $PermChange.properties[6].value.tostring()
	#Ignore temporary files
	if ($Change.FileChanged.EndsWith(".tmp")){continue}
	elseif ($Change.FileChanged.EndsWith(".partial")){continue}
		
	$Change.MadeOn = $PermChange.TimeCreated.tostring()
	$Change.OriginalPermissions = $PermChange.properties[8].value.tostring()
	$Change.NewPermissions = $PermChange.properties[9].value.tostring()
		
	write-output "{" >> $logfile
	write-output ("Changed By           : "+ $Change.ChangedBy) >> $logfile
	write-output ("File Changed         : "+ $Change.FileChanged) >> $logfile
	write-output ("Change Made          : "+ $Change.MadeOn) >> $logfile
	write-output ("Original Permissions : "+ $Change.OriginalPermissions) >> $logfile
	write-output ("New Permissions      : "+ $Change.NewPermissions) >> $logfile
	write-output "}
" >> $logfile
    }
}
	
Get-ChildItem -include Archive-Security*.evtx -path L:\Security\ -recurse | ForEach-Object{
    $log = $_
    if ($ParsedLogs -contains $log){
		return
	}
    Try{
		$PermChanges = Get-WinEvent -Path $_ -FilterXPath $XPath -ErrorAction Stop
	}
    Catch [Exception]{
		if ($_.Exception -match "No events were found that match the specified selection criteria."){
		}else {
			Throw $_
		}
	}
    LogPermissionChange($PermChanges)
    $PermChanges = $Null 
    $DeletableLogs += $_
}

foreach ($log in $DeletableLogs){
    $Timer = 0
    Try{
    	remove-item $log -ErrorAction Stop
	}
    Catch [Exception]{
		write-output $log.FullName >> $DeleteList
	}
}
