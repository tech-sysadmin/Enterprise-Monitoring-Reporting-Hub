<#
.SYNOPSIS
    Simulates server health monitoring.
.DESCRIPTION
    Reads a CSV of server health metrics and returns objects for aggregation.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath,

    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

if (-not $DataPath) {
    $DataPath = Join-Path -Path $PSScriptRoot -ChildPath '..\data\server-health.csv'
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
        throw "Server health data file not found: $DataPath"
    }

    $servers = Import-Csv -Path $DataPath | Select-Object ServerName, CPUUsage, MemoryUsage, DiskStatus, ServiceStatus
    Write-MonitorLog -Script 'Get-ServerHealth' -Status 'OK' -Message "Server health report generated with $($servers.Count) servers"
    return $servers
}
catch {
    Write-MonitorLog -Script 'Get-ServerHealth' -Status 'FAIL' -Message "$_"
    throw
}
