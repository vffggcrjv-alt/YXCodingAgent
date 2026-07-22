$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $name, $value = $line.Split("=", 2)
            [Environment]::SetEnvironmentVariable($name.Trim(), $value.Trim().Trim('"').Trim("'"), "Process")
        }
    }
}

if (-not (Test-Path ".yx\config.yaml")) {
    Write-Host "Missing .yx\config.yaml. Copy .yx\config.yaml.example and fill in your provider settings." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path ".venv\Scripts\python.exe")) {
    Write-Host "Creating Python environment..."
    uv sync --no-dev
}

Write-Host "Starting YXCodingAgent..."
uv run yx
