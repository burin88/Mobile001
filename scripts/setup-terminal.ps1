#requires -Version 5.1
# Install into npm's existing command directory so open terminals can find it.
$ErrorActionPreference = 'Stop'
$npmCommand = Get-Command npm.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $npmCommand) {
    throw 'npm is required to install the terminal command. Install Node.js first.'
}
$prefixOutput = & $npmCommand.Source config get prefix
if ($LASTEXITCODE -ne 0) {
    throw 'Could not find the npm global command directory.'
}
$commandDirectory = ($prefixOutput -join '').Trim()
if (-not [IO.Path]::IsPathRooted($commandDirectory)) {
    throw "Expected an absolute npm prefix, got: $commandDirectory"
}
$launcherPath = Join-Path $commandDirectory 'build-appdistribution.cmd'
$buildScript = Join-Path $PSScriptRoot 'build-appdistribution.ps1'
$launcherMarker = 'REM Flutter App Distribution launcher'
if (Test-Path -LiteralPath $launcherPath) {
    $existingLauncher = Get-Content -LiteralPath $launcherPath -Raw
    if (-not $existingLauncher.Contains($launcherMarker)) {
        throw "A different command already exists at $launcherPath. It has not been changed."
    }
}
[void](New-Item -ItemType Directory -Path $commandDirectory -Force)
$launcherText = @(
    '@echo off'
    $launcherMarker
    ('powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" %*' -f $buildScript)
    'exit /b %ERRORLEVEL%'
    ''
) -join "`r`n"
[IO.File]::WriteAllText($launcherPath, $launcherText, [Text.UTF8Encoding]::new($false))

# Most users already have this directory on PATH for firebase and npm tools.
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$userEntries = @($userPath -split ';' | Where-Object { $_.Trim() })
if (@($userEntries | Where-Object { $_.TrimEnd('\') -ieq $commandDirectory.TrimEnd('\') }).Count -eq 0) {
    $updatedUserPath = (@($userEntries) + $commandDirectory) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $updatedUserPath, 'User')
}

$processEntries = @($env:Path -split ';' | Where-Object { $_.Trim() })
if (@($processEntries | Where-Object { $_.TrimEnd('\') -ieq $commandDirectory.TrimEnd('\') }).Count -eq 0) {
    $env:Path = (@($processEntries) + $commandDirectory) -join ';'
}

Write-Host 'Terminal command ready: build-appdistribution'
Write-Host "Installed launcher: $launcherPath"
Write-Host 'Version: uses version from pubspec.yaml'
Write-Host 'Build:  build-appdistribution'
Write-Host "Upload: build-appdistribution -Upload -ReleaseNotes 'Test build'"
