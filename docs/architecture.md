# Architecture: Enterprise Monitoring Reporting Hub

This project is designed as a unified monitoring and reporting platform for simulated enterprise data.

## Components

- `data/ad-users.csv`
  - Simulated Active Directory user lifecycle data.

- `data/endpoint-status.csv`
  - Simulated endpoint compliance records.

- `data/server-health.csv`
  - Simulated server health metrics and service status.

- `scripts/Get-ADReport.ps1`
  - Reads AD user data and returns structured objects.

- `scripts/Get-EndpointReport.ps1`
  - Reads endpoint compliance data and returns structured objects.

- `scripts/Get-ServerHealth.ps1`
  - Reads server health data and returns structured objects.

- `scripts/Invoke-ReportAggregator.ps1`
  - Aggregates all reports into a unified dataset.
  - Generates HTML and JSON output.
  - Writes centralized operation logs.

- `logs/monitoring-log.txt`
  - Central log file for all monitoring operations.

## Data Flow

1. Each script reads its respective CSV source.
2. The aggregator script imports all data.
3. Data is merged into a single report dataset.
4. Output artifacts are generated in the `output` folder.
5. Execution steps are logged to the monitoring log.

## Enterprise Realism

The architecture mimics real monitoring systems by separating data ingestion, aggregation, and report generation. It enables future integration with real AD, endpoint management, and server telemetry sources.
