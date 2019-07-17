<#
.SYNOPSIS
Get-CrashFiles.ps1
David Summers
2019.07.17

Get-CrashFiles.ps1 gathers dump files and event logs for delivery to technicians for analysis


.DESCRIPTION
Get-CrashFiles.ps1 gathers dump files and event logs for delivery to technicians for analysis

It returns success (0) nonfatal failure (1), or fatal failure (2).

.PARAMETER dumpDate
Defaults to now, but should be the date and time of the last dump.
Note that this can be approximate. This script moves any minidump and full dump
file it finds into the outFile. This parameter is really used for folder naming
and evt log retrieval purposes.


.PARAMETER outFolder
Defaults to C:\Temp\<dumpDate>,
This is the location all files will be saved in
	
.EXAMPLE
To gather dump files from a crash that happened on 2019.07.16 15:17:00:
.\Get-CrashFiles.ps1 -dumpDate "2019.07.16 15:17:00"
	
#>
[cmdletbinding()]
Param(
	[Parameter(HelpMessage = "Enter the date the crash occured, in format yyyy.mm.dd hh.mm.ss (24 hour time).")]
	[ValidateNotNullorEmpty()]
	[DateTime] $dumpDate=(Get-Date $now)
	,
	[Parameter(HelpMessage = "Enter a folder to save files to.")]
	[ValidateNotNullorEmpty()]
	[string] $outFile=$("C:\temp\$dumpDate")
)

[DateTime]$BeginDate = $dumpDate.AddHours(-1)
[DateTime]$EndDate = $dumpDate.AddHours(1)

#Gather EVT logs
#Should confirm $outFile
$logFile = $outFile + "\System.xml"
Get-EventLog -LogName System -Before $EndDate -After $BeginDate | Export-CliXml -Path $logFile
$logFile = $outFile + "\Application.xml"
Get-EventLog -LogName Application -Before $EndDate -After $BeginDate | Export-CliXml -Path $logFile
$logFile = $outFile + "\Security.xml"
Get-EventLog -LogName Security -Before $EndDate -After $BeginDate | Export-CliXml -Path $logFile

#Gather dump files, if they exist
if (Test-Path "C:\WINDOWS\MEMORY.DMP")
{
    $dest = $outFile + "\MEMORY.DMP"
    Move-Item -Path "C:\WINDOWS\MEMORY.DMP" -Destination $dest
}
else 
{
    Write-Host "Could not find a dump file at C:\WINDOWS\MEMORY.DMP"
}

if (Test-Path "C:\WINDOWS\Minidump")
{
    $dest = $outFile
    Get-ChildItem -Path "C:\WINDOWS\Minidump" -Recurse | Move-Item -Destination $dest
}
else 
{
    Write-Host "Could not find a minidump folder at C:\WINDOWS\Minidump"
}

<# for future improvement
PS C:\Crashes\2019.07.16> $SourceACL = Get-ACL -Path .\
PS C:\Crashes\2019.07.16> $SourceACL.SetAccessRuleProtection($false,$true)
PS C:\Crashes\2019.07.16> $SourceACL = Get-ACL -Path .\MEMORY.DMP
PS C:\Crashes\2019.07.16> $SourceACL.SetAccessRuleProtection($false,$true)
PS C:\Crashes\2019.07.16> Set-Acl -Path .\MEMORY.DMP -AclObject $SourceACL
#>
