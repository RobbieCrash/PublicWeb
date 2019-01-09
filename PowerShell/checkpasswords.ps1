#requires -version 2
<#
.SYNOPSIS
	Finds AD accounts which use commonly set passwords from Helpdesk people, as well as a custom list.
.DESCRIPTION
	Finds AD accounts which have a password that is in the list of banned passwords. The Banned password list 
	is created by tossing a bunch of commonly used password bases with a year, and a filler character on the
	end. 
	
	You can also supply your own list of other banned passwords which will all also be checked. Will disable
	users that use one of those bad passwords, or have set their account to PasswordNeverExpires. 
	
	Sends an email containing the action information at the end of it.
	
.NOTES
	Version:		1.0
	Author:			Robbie Crash
	Written: 		2014-0-14
	Version Notes:	Initial script.
	
.LINK
	https://robbiecrash.me/scriptz/checkpasswords.ps1
#>

import-module ac*
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$Domain = "DOMAIN"
$Context = [System.DirectoryServices.AccountManagement.ContextType]::Domain
$PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $Context,$Domain
$logfile = "~\Desktop\PWLog.txt"
 
function BuildUserList(){
	$OUPull = @(get-aduser -filter * -searchbase "OU=WHATEVER, DC=DOMAIN, DC=com")
	$EnabledAccounts = @()
	$ITStaff = @()

	foreach($user in $OUPull){
		if($user.enabled -eq $True){
			$ITstaff += $user.samaccountname
			}
		}
	return $ITStaff
	}
	
function BuildPasswordList(){
	$seasons = @("Summer","Fall","Autumn","Winter","Spring","January","February","March","April","May","June","July","August","September","October","November","December")
	$years = @("2011","2012","2013","2014","2015")
	$filler = @("1","2","!","9","0")
	$BadPasswords = @("USE YOUR BANNED PASSWORDS HERE")
	
	foreach($season in $seasons){
		foreach($year in $years){
			$password = $season + $year
			$BadPasswords += $Password
			}
		}
	
	foreach($BadPass in $BadPasswords){
		foreach($fill in $filler){
			$password = $BadPass + $fill
			$BadPasswords += $password
			}
		}
	return $badpasswords
	}
	
Function EmailAlert($reason){
	$uzr = get-aduser -identity $user
	$fullname = $uzr.name
	$mailServer = "EMAIL SERVER HERE"
	$email = new-object Net.Mail.SMTPClient($mailServer)
	$message = new-object Net.Mail.MailMessage
	
	$message.From = "SENDER@DOMAIN.COM"
	$message.ReplyTo = "REPLYTO@DOMAIN.COM"
	$message.To.Add("RECIPIENT@DOMAIN.COM")
	$message.subject = "$fullname account disabled."
	
	$message.body= "The account $user has been disabled for $reason."
	
	$email.send($message)
	}
	
Function CheckExpires($user){
	$DoesntExpire = Get-ADUser -Properties passwordneverexpires $user
	if ($DoesntExpire.PasswordNeverExpires -eq $True){
		$reason = "setting password to never expire."
		set-aduser -identity $user -description "Disabled for $reason"
		Disable-ADAccount -identity $user
		EmailAlert($reason)
		continue
		}
	}
		
function CheckPasswords($user){	
	foreach($password in $badpasswords){
		if ($PrincipalContext.ValidateCredentials($User,$password) -eq $True){
			try {
				$reason = "using $password as their password."
				set-aduser -identity $user -description $reason
				Disable-ADAccount -identity $user 
				EmailAlert($reason)
				write-output "$user disabled for $reason" >> $logfile
				}
			catch [exception]{write-output "Could not disable account $user" >> $logfile}
				}
		unlock-adaccount -identity $user
		}
	}

	
Function main(){
	start-sleep -s 3
	$today = Get-Date
	$marker = "
------------
	$today
------------
"
	write-output $marker >> $logfile
	$ITStaff = BuildUserList
	$badpasswords = BuildPasswordList
	foreach($user in $ITStaff){
		CheckExpires($User)
		CheckPasswords($User)
		}
	}

main
