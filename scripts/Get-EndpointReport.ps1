<#
.SYNOPSIS
    Simulates endpoint compliance reporting.
.DESCRIPTION
    Reads a CSV of endpoint status and returns structured objects.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath,

    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

if (-not $DataPath) {
    $DataPath = Join-Path -Path $PSScriptRoot -ChildPath '..\data\endpoint-status.csv'
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
        throw "Endpoint data file not found: $DataPath"
    }

    $endpoints = Import-Csv -Path $DataPath | Select-Object DeviceName, ComplianceStatus, LastCheckIn
    Write-MonitorLog -Script 'Get-EndpointReport' -Status 'OK' -Message "Endpoint report generated with $($endpoints.Count) devices"
    return $endpoints
}
catch {
    Write-MonitorLog -Script 'Get-EndpointReport' -Status 'FAIL' -Message "$_"
    throw
}
