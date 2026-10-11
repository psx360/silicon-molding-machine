# Run with Windows PowerShell 5.1 or PowerShell 7 on the Windows host.
[CmdletBinding()]
param(
    [string]$FlutterRoot = (Join-Path $env:LOCALAPPDATA 'SiliconMolding\flutter-3.47.7')
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($env:OS -ne 'Windows_NT') { throw 'Run this script in Windows PowerShell, not Linux Flutter.' }

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
}
function Install-Package {
    param([string]$Id, [string]$Override = '')
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'winget is missing. Install/update Microsoft App Installer, then rerun.'
    }
    $arguments = @('install', '--id', $Id, '--exact', '--source', 'winget',
        '--accept-source-agreements', '--accept-package-agreements')
    if ($Override) { $arguments += @('--override', $Override) }
    & winget.exe @arguments
    if ($LASTEXITCODE -eq 3010) {
        throw 'Installation requires a Windows restart. Restart and rerun this script.'
    }
    if ($LASTEXITCODE -ne 0) {
        throw "winget installation of $Id failed ($LASTEXITCODE). Resolve installer errors and rerun."
    }
    Refresh-Path
}

if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Install-Package -Id 'Git.Git'
}
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw 'Git is unavailable after installation.' }

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$visualStudio = ''
if (Test-Path $vswhere) {
    $visualStudio = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
}
if (-not $visualStudio) {
    # UAC may require a local confirmation. Do not restart Windows automatically.
    $existingStudio = ''
    if (Test-Path $vswhere) {
        $existingStudio = & $vswhere -latest -property installationPath
    }
    if ($existingStudio) {
        $installer = Join-Path (Split-Path $vswhere -Parent) 'setup.exe'
        $arguments = 'modify --installPath "' + $existingStudio + '" --passive --norestart --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended'
        $process = Start-Process -FilePath $installer -ArgumentList $arguments -Verb RunAs -Wait -PassThru
        if ($process.ExitCode -eq 3010) { throw 'Restart Windows and rerun setup to finish Visual Studio installation.' }
        if ($process.ExitCode -ne 0) { throw "Visual Studio modification failed ($($process.ExitCode))." }
    } else {
        Install-Package -Id 'Microsoft.VisualStudio.2022.Community' -Override '--passive --wait --norestart --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended'
    }
}

$flutter = Join-Path $FlutterRoot 'bin\flutter.bat'
if (-not (Test-Path $flutter)) {
    if (Test-Path $FlutterRoot) { throw "Existing incomplete SDK at $FlutterRoot. Inspect it; it will not be overwritten." }
    New-Item -ItemType Directory -Force -Path (Split-Path $FlutterRoot -Parent) | Out-Null
    Invoke-Checked -Program 'git.exe' -Arguments @('clone', '--depth', '1', '--branch', '3.47.7',
        'https://github.com/flutter/flutter.git', $FlutterRoot)
}
$flutterBin = Join-Path $FlutterRoot 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (@($userPath -split ';') -notcontains $flutterBin) {
    [Environment]::SetEnvironmentVariable('Path', ($flutterBin + ';' + $userPath), 'User')
}
Refresh-Path
# Explicit path avoids selecting a different pre-existing SDK from PATH.
Invoke-Checked -Program $flutter -Arguments @('--version')
Invoke-Checked -Program $flutter -Arguments @('precache', '--windows')
Invoke-Checked -Program $flutter -Arguments @('doctor', '-v')
Write-Host "SDK ready: $flutter"
Write-Host 'Android tooling is not required for this Windows demo. Check the Windows and Visual Studio doctor sections.'
