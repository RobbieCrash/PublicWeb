# T#requires -version 2
<#
.SYNOPSIS
	Goes through a list of servers and finds all service accounts running under other accounts
.DESCRIPTION
	Grabs a list of all Windows Servers from AD, then connects to each and builds a list of all services that
	are running under any account other than the default local accounts such as:
	LocalSystem
	NT Authority\NetworkService
	NT AUTHORITY\LocalService
	
	Formats a list and prints it to screen.
	
.NOTES
	Version:		1.0
	Author:			Robbie Crash
	Written: 		2014-08-28
	Version Notes:	Initial script.
	
.LINK
	https://robbiecrash.me/scriptz/AuditServiceAccounts.ps1
#>


$servers = Get-AdComputer -LDAPFilter "(OperatingSystem=*Server*)"
foreach($server in $servers){$serverlist += $server.name}

foreach($server in $serverlist){
	$services = Get-WmiObject -ComputerName $server win32_service
	foreach($service in $services){
		if ($service.startname -ne "LocalSystem" `
		-And $service.startname -ne "NT AUTHORITY\LocalService" `
		-And $service.startname -ne "NT Authority\NetworkService"){
			$padserver = $server.padright(32)
			$padservicename = $service.name.padright(32)
			write-host $padserver $padservicename $service.startname.padright(32)
			}
		}
	}
