<#
.SYNOPSIS
    Aggregates monitoring data and generates unified operational reports.
.DESCRIPTION
    Calls AD, endpoint, and server health reports, then builds HTML and JSON outputs.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputHtml,

    [Parameter(Mandatory=$false)]
    [string]$OutputJson,

    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

if (-not $OutputHtml) {
    $OutputHtml = Join-Path -Path $PSScriptRoot -ChildPath '..\output\enterprise-report.html'
}
if (-not $OutputJson) {
    $OutputJson = Join-Path -Path $PSScriptRoot -ChildPath '..\output\enterprise-report.json'
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
    Write-Output $entry
}

function Get-ColorClass {
    param (
        [string]$Status
    )
    switch ($Status) {
        'Compliant' { return 'green' }
        'Active'    { return 'green' }
        'OK'        { return 'green' }
        'WARN'      { return 'yellow' }
        'Inactive'  { return 'yellow' }
        'NonCompliant' { return 'red' }
        'FAIL'      { return 'red' }
        default     { return 'gray' }
    }
}

try {
    Write-MonitorLog -Script 'Invoke-ReportAggregator' -Status 'OK' -Message 'Starting aggregation process.'

    $adReport = & "$PSScriptRoot\Get-ADReport.ps1" -LogPath $LogPath
    $endpointReport = & "$PSScriptRoot\Get-EndpointReport.ps1" -LogPath $LogPath
    $serverHealth = & "$PSScriptRoot\Get-ServerHealth.ps1" -LogPath $LogPath

    $summary = [PSCustomObject]@{
        ReportGenerated   = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        TotalUsers        = $adReport.Count
        ActiveUsers       = ($adReport | Where-Object { $_.Status -eq 'Active' }).Count
        InactiveUsers     = ($adReport | Where-Object { $_.Status -eq 'Inactive' }).Count
        TotalEndpoints    = $endpointReport.Count
        CompliantDevices  = ($endpointReport | Where-Object { $_.ComplianceStatus -eq 'Compliant' }).Count
        NonCompliantDevices = ($endpointReport | Where-Object { $_.ComplianceStatus -eq 'NonCompliant' }).Count
        TotalServers      = $serverHealth.Count
        CriticalServers   = ($serverHealth | Where-Object { $_.DiskStatus -eq 'FAIL' -or $_.ServiceStatus -eq 'FAIL' }).Count
    }

    $reportObject = [PSCustomObject]@{
        Summary       = $summary
        ADUsers       = $adReport
        EndpointStatus = $endpointReport
        ServerHealth  = $serverHealth
    }

    $json = $reportObject | ConvertTo-Json -Depth 5
    $json | Out-File -FilePath $OutputJson -Encoding utf8

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Enterprise Monitoring Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 24px; }
        .section { margin-bottom: 32px; }
        .header { font-size: 24px; margin-bottom: 12px; }
        .badge { padding: 4px 8px; border-radius: 4px; color: #fff; }
        .green { background-color: #28a745; }
        .yellow { background-color: #ffc107; color: #000; }
        .red { background-color: #dc3545; }
        .gray { background-color: #6c757d; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background: #f4f4f4; }
    </style>
</head>
<body>
    <div class="section">
        <div class="header">Enterprise Monitoring Report</div>
        <div>Generated: $($summary.ReportGenerated)</div>
    </div>

    <div class="section">
        <div class="header">Summary</div>
        <ul>
            <li>Total AD users: $($summary.TotalUsers)</li>
            <li>Active users: $($summary.ActiveUsers)</li>
            <li>Inactive users: $($summary.InactiveUsers)</li>
            <li>Total endpoints: $($summary.TotalEndpoints)</li>
            <li>Compliant devices: $($summary.CompliantDevices)</li>
            <li>Non-compliant devices: $($summary.NonCompliantDevices)</li>
            <li>Total servers: $($summary.TotalServers)</li>
            <li>Critical servers: $($summary.CriticalServers)</li>
        </ul>
    </div>

    <div class="section">
        <div class="header">Active Directory Users</div>
        <table>
            <thead><tr><th>Username</th><th>Department</th><th>Status</th></tr></thead>
            <tbody>
"@
    foreach ($user in $adReport) {
        $color = Get-ColorClass -Status $user.Status
        $html += "            <tr><td>$($user.Username)</td><td>$($user.Department)</td><td><span class='badge $color'>$($user.Status)</span></td></tr>`n"
    }
    $html += @"
            </tbody>
        </table>
    </div>

    <div class="section">
        <div class="header">Endpoint Compliance</div>
        <table>
            <thead><tr><th>Device Name</th><th>Compliance Status</th><th>Last Check-In</th></tr></thead>
            <tbody>
"@
    foreach ($endpoint in $endpointReport) {
        $color = Get-ColorClass -Status $endpoint.ComplianceStatus
        $html += "            <tr><td>$($endpoint.DeviceName)</td><td><span class='badge $color'>$($endpoint.ComplianceStatus)</span></td><td>$($endpoint.LastCheckIn)</td></tr>`n"
    }
    $html += @"
            </tbody>
        </table>
    </div>

    <div class="section">
        <div class="header">Server Health Summary</div>
        <table>
            <thead><tr><th>Server</th><th>CPU %</th><th>Memory %</th><th>Disk Status</th><th>Service Status</th></tr></thead>
            <tbody>
"@
    foreach ($server in $serverHealth) {
        $diskColor = Get-ColorClass -Status $server.DiskStatus
        $serviceColor = Get-ColorClass -Status $server.ServiceStatus
        $html += "            <tr><td>$($server.ServerName)</td><td>$($server.CPUUsage)</td><td>$($server.MemoryUsage)</td><td><span class='badge $diskColor'>$($server.DiskStatus)</span></td><td><span class='badge $serviceColor'>$($server.ServiceStatus)</span></td></tr>`n"
    }
    $html += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputHtml -Encoding utf8

    Write-MonitorLog -Script 'Invoke-ReportAggregator' -Status 'OK' -Message "Reports written to $OutputHtml and $OutputJson"
}
catch {
    Write-MonitorLog -Script 'Invoke-ReportAggregator' -Status 'FAIL' -Message "$_"
    throw
}
