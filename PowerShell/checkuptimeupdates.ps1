#requires -version 2

<#
.SYNOPSIS
	Queries list of computers to find their uptime and when the last time Windows Updates were installed.
.DESCRIPTION
	Goes through a list of computers, remotely runs sysinternals Uptime then connects to their registry to check when 
	the last time Windows Updates were successfully installed. Logs all details to a logfile. 
	
.NOTES
	Version:		1.0
	Author:			Robbie Crash
	Written: 		2014-10-20
	Version Notes:	Initial script.
	
	REQUIRES: Sysinternals uptime tool to be in the same directory, or your path!
	
.LINK
	https://robbiecrash.me/scriptz/checkuptimeupdates.ps1
#>

$serverlist = 
@("ALL YOUR SERVERS GO HERE IN A LIST") 
$logfile = "~\Desktop\uptimelog.txt"

$today = Get-Date
$marker = "
-------------
$today
-------------
"
write-output $marker >> $logfile

oreach($server in $serverlist) {
	$installdate = 0
	$lastmonth = (Get-Date).adddays(-30) 
	$tooold = $lastmonth.ToString("yyyy-MM-dd hh:mm:ss")

	$full = uptime $server
	$split = $full.split(" ")
	try {
		if([int]$split[5] -gt 30) {
			$dayno = ([int]$split[5] - 15)
			$output = "$server is over uptime by $dayno days." 
			write-output $output >> $logfile }
		}
	catch [Exception]{
		$output = "$server could not be queried. Is it up?" 
		write-output $output >> $logfile}

	try {
		$keyname = "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install"	
		$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $server)
		$regkey = $reg.OpenSubKey($keyname)
		}
	catch [Exception]{
		$output = "Could not query registry on $server"
		write-output $output >> $logfile}
		
	try {
		$installdate = $regkey.GetValue("LastSuccessTime")
		if ($installdate -lt $tooold) 
			{$output = "$server last updated $installdate"
			write-output $output >> $logfile}
		} 
	catch [Exception]{
		$output = "$server Has not been updated. Ever." 
		write-output $output >> $logfile}
		
	try {
		$errorstatus = $regkey.GetValue("LastError")
		if ($errorstatus -ne 0)
			{$output = "$server reported Windows Update error $errorstatus"
			write-output $output >> $logfile}
		}
	catch [Exception]{} #Do nothing because it's already been reported that no updates have been installed.
}
