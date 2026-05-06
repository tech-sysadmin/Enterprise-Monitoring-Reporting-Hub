<#
.SYNOPSIS
    Simulates Active Directory user lifecycle reporting.
.DESCRIPTION
    Reads a CSV of AD users and returns objects for aggregation.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath,

    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

if (-not $DataPath) {
    $DataPath = Join-Path -Path $PSScriptRoot -ChildPath '..\data\ad-users.csv'
}
if (-not $LogPath) {
    $LogPath = Join-Path -Path $PSScriptRoot -ChildPath '..\logs\monitoring-log.txt'
}

function Write-MonitorLog {
    param (
        [string]$Script,
        [string]$Status,
        [string]$Message
    )
    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Script] [$Status] $Message"
    $entry | Out-File -FilePath $LogPath -Append -Encoding utf8
}

try {
    if (-not (Test-Path -Path $DataPath)) {
        throw "AD data file not found: $DataPath"
    }

    $users = Import-Csv -Path $DataPath | Select-Object Username, Department, Status
    Write-MonitorLog -Script 'Get-ADReport' -Status 'OK' -Message "AD report generated with $($users.Count) users"
    return $users
}
catch {
    Write-MonitorLog -Script 'Get-ADReport' -Status 'FAIL' -Message "$_"
    throw
}
