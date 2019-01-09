#requires -version 2
<#
.SYNOPSIS
	Moves files which have not been modified in 4 or more years, copies them to secondary storage and creates a symlink
.DESCRIPTION
	Scans a particular directory, and all subdirectories for files that haven't been modified in 4 years. Any detected 
	files are moved to a secondary storage location, and a symlink is created to the new file location.
	
.NOTES
	Version:		1.0
	Author:			Robbie Crash
	Written: 		2014-02-13
	Version Notes:	Initial script.
	
	REQUIRES: 		This script requires that you set SymlinkEvaluation to allow remote transversal. You can do this 
					by opening an admin command prompt and running the following command:
						fsutil behavior set SymlinkEvaluation r2r:1
					You can verify this worked by running:
						fsutil behavior query SymlinkEvaluation
					This behaviour can also be set via GPO:
						Computer Configuration > Policies > Administrative Templates > System > File System >
							Selectively allow the evaluation of a symbolic link
						Then set Remote to Remote to Enabled.						
	
.LINK
	https://robbiecrash.me/scriptz/ArchiveAndLink.ps1
#>

param(
    [string]$Dir = "",
    [string]$ArchiveDrive = ""
    )

if ($ArchiveDrive -eq ""){
    $hostname = hostname
    $ArchiveDrive = "\\Archives\"+$hostname+"\"+$Dir[0]+"\"
    }

import-module PSCX
import-module new-symlink

$FileList = @()

$SourceDrive = $dir[0] + ":\"

$date = Get-Date -Format yyyy-MM-dd
$ErrLog = "C:\ErrorLog $date.txt"
$DelLog = "C:\DelLog $date.txt"
$PathWarning = "C:\_PROBLEMS DETECTED.txt" 

function BuildLists($dir){
    $FileList = @()
    $DirList = (dir $dir -recurse)
    foreach ($item in $DirList){
        if ( ((get-date).Subtract($item.LastWriteTime).Days-gt 1460) -eq $True) { 

            $FileList += $item
            }
        else {write-verbose "$item is modified recently"}
        }
    return $FileList
    }

function CheckPathLength($file){
    if ($File.FullName.Length -ge 220){
        copy $PathWarning $File.DirectoryName}
    }

function ArchiveFile($SourceFile){
    $DestFile = ($SourceFile.fullname.replace($SourceDrive, $ArchiveDrive))
    $DestDir = ($SourceFile.DirectoryName.replace($SourceDrive, $ArchiveDrive))
    mkdir -Path $DestDir 2>$ErrLog
    copy $SourceFile.FullName $DestFile
    }

function HashCheckFile($SourceFile){
    $DestFile = $SourceFile.FullName.replace($SourceDrive, $ArchiveDrive)
    $SourceHash = get-hash($SourceFile.fullname)
    $DestHash = get-hash("$DestFile")
    return $SourceHash.HashString -eq $DestHash.HashString
    }

function DeleteFIle($File){
    del $file.fullname 
    }

function LinkFile($Sourcefile){
    $SourceFilePath = $Sourcefile.fullname
    $DestFile = ($sourcefilepath.replace($SourceDrive, $ArchiveDrive))
    New-Symlink -path $DestFile $SourceFile.fullname -file 1>$errlog
    }


function CheckPathLength($file){
    if ($File.FullName.Length -ge 220){
        copy $PathWarning $File.DirectoryName}
    }

function ReplicateFile($file){
    if ($file.Attributes -eq "Directory"){continue}
    ArchiveFile($File)
    if (HashCheckFile($File)){
        DeleteFile($File)
        LinkFile($File)
        }
    }

function Archive($FileList){
    foreach ($File in $FileList){
        CheckPathLength($file)
        ReplicateFile($File)
        }
    }

function RunArchiving($dir){
    $FileList = BuildLists($dir)
    Archive($FileList)
    }

RunArchiving($dir)
