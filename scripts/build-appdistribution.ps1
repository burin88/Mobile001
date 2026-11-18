#requires -Version 5.1
<#
.SYNOPSIS
Build a release APK for burin-test and optionally upload it to App Distribution.
.DESCRIPTION
Uses version from pubspec.yaml for both the version name and build number.
.EXAMPLE
.\scripts\build-appdistribution.ps1
.EXAMPLE
.\scripts\build-appdistribution.ps1 -Upload -ReleaseNotes 'Fix notifications'
.EXAMPLE
.\scripts\build-appdistribution.ps1 -Upload -Groups 'qa-team' -ReleaseNotesFile .\release-notes.txt
#>
[CmdletBinding()]
param(
    [switch]$Upload,
    [string]$FirebaseAccount = 'Burin@infsystemsgroup.com',
    [string]$ReleaseNotes,
    [string]$ReleaseNotesFile,
    [string]$Groups,
    [string]$Testers
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$firebaseProject = 'burin-test'
$packageName = 'com.example.flutter_application_1'
$apkPath = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'

if ($ReleaseNotes -and $ReleaseNotesFile) {
    throw 'Use either -ReleaseNotes or -ReleaseNotesFile, not both.'
}
if (-not $Upload -and ($ReleaseNotes -or $ReleaseNotesFile -or $Groups -or $Testers)) {
    throw 'Release notes, groups, and testers require -Upload.'
}
# Resolve the notes before changing directory, relative to the caller.
if ($ReleaseNotesFile) {
    if (-not (Test-Path -LiteralPath $ReleaseNotesFile -PathType Leaf)) {
        throw "Release notes file not found: $ReleaseNotesFile"
    }
    $ReleaseNotesFile = (Resolve-Path -LiteralPath $ReleaseNotesFile).Path
}

$configPath = Join-Path $projectRoot 'android\app\google-services.json'
$firebaseConfig = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if ($firebaseConfig.project_info.project_id -ne $firebaseProject) {
    throw "google-services.json must belong to Firebase project $firebaseProject."
}
$clients = @($firebaseConfig.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq $packageName
})
if ($clients.Count -ne 1 -or -not $clients[0].client_info.mobilesdk_app_id) {
    throw "Expected one Firebase Android app for $packageName in google-services.json."
}
$appId = $clients[0].client_info.mobilesdk_app_id

# Load this workspace's local Flutter/Android/Java tools when available.
$workspaceRoot = Split-Path -Parent (Split-Path -Parent $projectRoot)
$activateScript = Join-Path $workspaceRoot 'activate.ps1'
if (Test-Path -LiteralPath $activateScript -PathType Leaf) {
    . $activateScript
}
$flutterCommand = Get-Command flutter -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $flutterCommand) {
    throw 'Flutter is not on PATH. Install Flutter or load the workspace activate.ps1.'
}
if ($Upload) {
    $firebaseCommand = Get-Command firebase -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $firebaseCommand) {
        throw 'Firebase CLI is required for -Upload. Run: npm install -g firebase-tools; then: firebase login'
    }
}

Push-Location -LiteralPath $projectRoot
try {
    Write-Host "Firebase project: $firebaseProject"
    Write-Host "Android package: $packageName"
    Write-Host "Firebase App ID: $appId"
    Write-Host 'App version and build number: from version in pubspec.yaml'

    if ($Upload) {
        $accessArguments = @('apps:list', 'ANDROID', '--project', $firebaseProject, '--non-interactive')
        if ($FirebaseAccount) {
            $accessArguments += @('--account', $FirebaseAccount)
        }
        Write-Host 'Checking Firebase project access before building...'
        & $firebaseCommand.Source @accessArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Firebase access check failed. Run 'firebase login:add' and choose $FirebaseAccount. To use a different authorized account, specify -FirebaseAccount 'your-email'."
        }
    }

    & $flutterCommand.Source pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed (exit $LASTEXITCODE)."
    }

    # Flutter reads versionName and versionCode from pubspec.yaml's version.
    & $flutterCommand.Source build apk --release --no-pub
    if ($LASTEXITCODE -ne 0) {
        throw "APK build failed (exit $LASTEXITCODE)."
    }
    if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "Build finished without the expected APK: $apkPath"
    }

    $apk = Get-Item -LiteralPath $apkPath
    Write-Host ("APK ready: {0} ({1:N1} MB)" -f $apk.FullName, ($apk.Length / 1MB))

    if ($Upload) {
        $uploadArguments = @(
            'appdistribution:distribute', $apkPath,
            '--app', $appId,
            '--project', $firebaseProject,
            '--non-interactive'
        )
        if ($FirebaseAccount) { $uploadArguments += @('--account', $FirebaseAccount) }
        if ($ReleaseNotes) { $uploadArguments += @('--release-notes', $ReleaseNotes) }
        if ($ReleaseNotesFile) { $uploadArguments += @('--release-notes-file', $ReleaseNotesFile) }
        if ($Groups) { $uploadArguments += @('--groups', $Groups) }
        if ($Testers) { $uploadArguments += @('--testers', $Testers) }

        & $firebaseCommand.Source @uploadArguments
        if ($LASTEXITCODE -ne 0) {
            throw "App Distribution upload failed (exit $LASTEXITCODE). Check Firebase login and project access. APK remains at: $apkPath"
        }
        Write-Host 'Upload to Firebase App Distribution completed.'
    }
}
finally {
    Pop-Location
}
