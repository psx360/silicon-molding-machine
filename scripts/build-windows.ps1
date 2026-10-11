[CmdletBinding()]
param(
    [string]$FlutterRoot = (Join-Path $env:LOCALAPPDATA 'SiliconMolding\flutter-3.47.7'),
    [switch]$Run
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($env:OS -ne 'Windows_NT') { throw 'Windows Flutter is required.' }
$flutter = Join-Path $FlutterRoot 'bin\flutter.bat'
if (-not (Test-Path $flutter)) { throw 'Run scripts/setup-windows.ps1 first, or supply -FlutterRoot.' }
$app = Join-Path (Split-Path $PSScriptRoot -Parent) 'control-app'
function Invoke-Flutter {
    param([string[]]$Arguments)
    & $flutter @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Flutter failed: $($Arguments -join ' ') ($LASTEXITCODE)" }
}
Push-Location $app
try {
    Invoke-Flutter -Arguments @('pub', 'get')
    Invoke-Flutter -Arguments @('analyze')
    Invoke-Flutter -Arguments @('test')
    Invoke-Flutter -Arguments @('build', 'windows', '--release')
    $executables = @(Get-ChildItem -Path (Join-Path $app 'build\windows') -Filter 'silicon_control.exe' -Recurse |
        Where-Object { $_.Directory.Name -eq 'Release' -and $_.Directory.Parent.Name -eq 'runner' } |
        Sort-Object LastWriteTime -Descending)
    if ($executables.Count -eq 0) { throw 'Build succeeded but the release executable was not found.' }
    $executable = $executables[0]
    Write-Host "Release folder: $($executable.Directory.FullName)"
    Write-Host 'Distribute this entire folder, including DLLs and data.'
    if ($Run) {
        $process = Start-Process -FilePath $executable.FullName -WorkingDirectory $executable.Directory.FullName -PassThru
        Start-Sleep -Seconds 3
        $process.Refresh()
        if ($process.HasExited) { throw "Application exited immediately ($($process.ExitCode)). Inspect the Windows runtime environment." }
        Write-Host "Application process started: PID $($process.Id). Verify the visible window locally."
    }
} finally {
    Pop-Location
}
