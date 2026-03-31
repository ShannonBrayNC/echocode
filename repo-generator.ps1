param(
    [string]$SpecPath = ".\repo-spec.json",
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-RepoFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [bool]$Overwrite = $false
    )

    $dir = Split-Path -Path $Path -Parent

    if (-not [string]::IsNullOrWhiteSpace($dir)) {
        Ensure-Directory -Path $dir
    }

    if ((Test-Path -LiteralPath $Path) -and (-not $Overwrite)) {
        Write-Host "Skipping existing file: $Path" -ForegroundColor Yellow
        return
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Wrote file: $Path" -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $SpecPath)) {
    throw "Spec file not found: $SpecPath"
}

$raw = Get-Content -LiteralPath $SpecPath -Raw -Encoding UTF8
$spec = $raw | ConvertFrom-Json -Depth 100

$root = if ([string]::IsNullOrWhiteSpace($spec.root)) { "." } else { [string]$spec.root }

Write-Host "Using repo root: $root" -ForegroundColor Cyan
Ensure-Directory -Path $root

foreach ($dir in $spec.directories) {
    $targetDir = Join-Path $root $dir
    Ensure-Directory -Path $targetDir
    Write-Host "Ensured dir: $targetDir" -ForegroundColor DarkCyan
}

foreach ($file in $spec.files) {
    $targetFile = Join-Path $root ([string]$file.path)
    $content = if ($null -eq $file.content) { "" } else { [string]$file.content }
    Write-RepoFile -Path $targetFile -Content $content -Overwrite:$Force.IsPresent
}

Write-Host ""
Write-Host "Repo generation complete." -ForegroundColor Cyan
