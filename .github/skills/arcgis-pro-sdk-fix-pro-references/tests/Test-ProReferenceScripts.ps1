# Copyright 2026 Esri
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

<#
.SYNOPSIS
Runs isolated fixture evaluations for the ArcGIS Pro reference repair scripts.

.DESCRIPTION
Creates temporary ArcGIS Pro and project fixtures, exercises repair variants,
project discovery, verification, rollback, detection rejection, and successful
and failed builds. Workspace files are not changed, and fixture backups are
cleaned after the run.

.EXAMPLE
& ./tests/Test-ProReferenceScripts.ps1
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$findProjectsScript = Join-Path $skillRoot 'scripts\00-find-arcgis-pro-projects.ps1'
$detectScript = Join-Path $skillRoot 'scripts\01-detect-arcgis-pro.ps1'
$fixScript = Join-Path $skillRoot 'scripts\02-fix-pro-references.ps1'
$verifyScript = Join-Path $skillRoot 'scripts\03-verify-pro-references.ps1'
$buildScript = Join-Path $skillRoot 'scripts\04-build-project.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('ArcGISProReferenceEvaluations-{0}' -f [guid]::NewGuid().ToString('N'))
$results = New-Object System.Collections.Generic.List[object]

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-LatestSdkRuntimeTfm {
    $sdkLines = @(& dotnet --list-sdks 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet --list-sdks failed: $($sdkLines -join ', ')"
    }

    $versions = @(
        foreach ($line in $sdkLines) {
            $match = [regex]::Match($line, '^(?<version>\d+\.\d+\.\d+)')
            if ($match.Success) {
                [version]$match.Groups['version'].Value
            }
        }
    )
    if ($versions.Count -eq 0) {
        throw 'No installed .NET SDK was detected.'
    }

    $latest = $versions | Sort-Object -Descending | Select-Object -First 1
    return "net$($latest.Major).$($latest.Minor)"
}

function New-FakeProInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$RuntimeTfm
    )

    $binPath = Join-Path $Path 'bin'
    [void](New-Item -ItemType Directory -Path $binPath -Force)
    foreach ($fileName in @(
        'ArcGISPro.exe',
        'ArcGIS.Desktop.Framework.xsd'
    )) {
        [System.IO.File]::WriteAllText((Join-Path $binPath $fileName), 'fixture')
    }
    $targetsXml = '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" />'
    [System.IO.File]::WriteAllText(
        (Join-Path $binPath 'Esri.ProApp.SDK.Desktop.targets'),
        $targetsXml
    )
    $runtimeConfig = '{"runtimeOptions":{"tfm":"' + $RuntimeTfm + '"}}'
    [System.IO.File]::WriteAllText(
        (Join-Path $binPath 'ArcGISPro.runtimeconfig.json'),
        $runtimeConfig
    )

    $assemblySource = Join-Path $Path 'fixture-assembly'
    [void](New-Item -ItemType Directory -Path $assemblySource -Force)
    $assemblyProject = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>$RuntimeTfm</TargetFramework>
    <AssemblyName>ArcGIS.Core</AssemblyName>
  </PropertyGroup>
</Project>
"@
    [System.IO.File]::WriteAllText(
        (Join-Path $assemblySource 'ArcGIS.Core.csproj'),
        $assemblyProject
    )
    [System.IO.File]::WriteAllText(
        (Join-Path $assemblySource 'ArcGISCore.cs'),
        'namespace ArcGIS.Core { public sealed class FixtureType { } }'
    )
    $assemblyBuildOutput = @(
        & dotnet build (Join-Path $assemblySource 'ArcGIS.Core.csproj') --nologo 2>&1 |
            ForEach-Object { $_.ToString() }
    )
    if ($LASTEXITCODE -ne 0) {
        throw "Could not build the ArcGIS.Core fixture assembly: $($assemblyBuildOutput -join [Environment]::NewLine)"
    }
    Copy-Item `
        -LiteralPath (Join-Path $assemblySource "bin\Debug\$RuntimeTfm\ArcGIS.Core.dll") `
        -Destination (Join-Path $binPath 'ArcGIS.Core.dll')
}

function New-ProjectFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [ValidateSet('.csproj', '.vbproj')]
        [string]$ProjectExtension = '.csproj',

        [AllowEmptyString()]
        [string]$ManifestName = 'Config.daml',

        [AllowEmptyString()]
        [string]$LaunchFile = '.vscode\launch.json',

        [switch]$MalformedManifest,

        [switch]$NoDesktopImport
    )

    [void](New-Item -ItemType Directory -Path $Path -Force)
    $projectPath = Join-Path $Path "Fixture$ProjectExtension"
    $desktopImport = if ($NoDesktopImport) {
        ''
    } else {
        '  <Import Project="C:\LegacyPro\bin\Esri.ProApp.SDK.Desktop.targets" Condition="Exists(''C:\LegacyPro\bin\Esri.ProApp.SDK.Desktop.targets'')" />'
    }
    $projectXml = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0-windows</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="ArcGIS.Core">
      <HintPath>C:\LegacyPro\bin\ArcGIS.Core.dll</HintPath>
    </Reference>
    <Reference Include="System.Xml" />
  </ItemGroup>
$desktopImport
</Project>
"@
    [System.IO.File]::WriteAllText($projectPath, $projectXml)

        if (-not [string]::IsNullOrWhiteSpace($ManifestName)) {
                $manifest = if ($MalformedManifest) {
                        '<ArcGIS><broken>'
                } else {
                        @'
<ArcGIS xmlns="http://schemas.esri.com/DADF/Registry"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://schemas.esri.com/DADF/Registry file:///C:/LegacyPro/bin/ArcGIS.Desktop.Framework.xsd" />
'@
                }
                [System.IO.File]::WriteAllText((Join-Path $Path $ManifestName), $manifest)
    }

        if (-not [string]::IsNullOrWhiteSpace($LaunchFile)) {
                $launchJson = if ($LaunchFile -eq 'Properties\launchSettings.json') {
                        @'
{
    "profiles": {
        "ArcGIS Pro": {
            "executablePath": "C:\\LegacyPro\\bin\\ArcGISPro.exe",
            "workingDirectory": "C:\\LegacyPro\\bin"
        },
        "Other Tool": {
            "executablePath": "C:\\Tools\\Other.exe"
        }
    }
}
'@
                } else {
                        @'
{
  // JSONC and a trailing comma are intentional fixture coverage.
  "configurations": [
    {
      "name": "ArcGIS Pro",
      "program": "C:\\LegacyPro\\bin\\ArcGISPro.exe",
      "cwd": "C:\\LegacyPro\\bin",
    },
    {
      "name": "Other Tool",
      "program": "C:\\Tools\\Other.exe"
    }
  ]
}
'@
                }
                $launchPath = Join-Path $Path $LaunchFile
                [void](New-Item -ItemType Directory -Path (Split-Path -Parent $launchPath) -Force)
                [System.IO.File]::WriteAllText($launchPath, $launchJson)
        }
    return $projectPath
}

function Invoke-Evaluation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )

    try {
        & $Test
        $results.Add([pscustomobject]@{ Scenario = $Name; Passed = $true; Detail = 'Assertions passed.' })
    } catch {
        $caughtError = $_
        $results.Add([pscustomobject]@{
            Scenario = $Name
            Passed = $false
            Detail = $caughtError.Exception.Message
        })
    }
}

try {
    [void](New-Item -ItemType Directory -Path $tempRoot -Force)
    $runtimeTfm = Get-LatestSdkRuntimeTfm
    $expectedTargetFramework = "$runtimeTfm-windows"
    $proInstallDir = Join-Path $tempRoot 'ArcGISPro'
    New-FakeProInstallation -Path $proInstallDir -RuntimeTfm $runtimeTfm
    $proBin = Join-Path $proInstallDir 'bin'

    Invoke-Evaluation -Name 'Repair and verify an Add-in fixture' -Test {
        $workspaceRoot = Join-Path $tempRoot 'AddInWorkspace'
        $projectRoot = Join-Path $workspaceRoot 'src\AddIn'
        $projectPath = New-ProjectFixture -Path $projectRoot
        $projectLaunchPath = Join-Path $projectRoot '.vscode\launch.json'
        $workspaceLaunchPath = Join-Path $workspaceRoot '.vscode\launch.json'
        $projectRootLaunchPath = Join-Path $projectRoot 'launch.json'
        [void](New-Item -ItemType Directory -Path (Split-Path -Parent $workspaceLaunchPath) -Force)
        Copy-Item -LiteralPath $projectLaunchPath -Destination $workspaceLaunchPath
        Copy-Item -LiteralPath $projectLaunchPath -Destination $projectRootLaunchPath
        $backupDirectory = Join-Path $tempRoot 'Backups\AddIn'
        $repair = & $fixScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -ArcGISProVersion '3.5.0' `
            -WorkspacePath $workspaceRoot `
            -BackupDirectory $backupDirectory `
            -UpdateTargetFramework
        $verification = & $verifyScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -WorkspacePath $workspaceRoot `
            -ExpectedTargetFramework $expectedTargetFramework `
            -ThrowOnFailure

        $projectDocument = [xml](Get-Content -LiteralPath $projectPath -Raw)
        $arcGisHintPath = [string]$projectDocument.Project.ItemGroup.Reference[0].HintPath
        $nonArcGisInclude = [string]$projectDocument.Project.ItemGroup.Reference[1].Include
        Assert-Condition -Condition $verification.IsValid -Message 'Verification did not return IsValid.'
        Assert-Condition -Condition ($repair.FilesUpdated -eq 5) `
            -Message "Expected five updated files but found $($repair.FilesUpdated)."
        Assert-Condition -Condition ($arcGisHintPath -eq (Join-Path $proBin 'ArcGIS.Core.dll')) `
            -Message 'The ArcGIS.Core HintPath was not updated to the fixture installation.'
        Assert-Condition -Condition ($nonArcGisInclude -eq 'System.Xml') `
            -Message 'The non-ArcGIS reference was not preserved.'
        Assert-Condition -Condition (Test-Path -LiteralPath $repair.BackupDirectory -PathType Container) `
            -Message 'The repair did not return an existing backup directory.'
        foreach ($launchPath in @($workspaceLaunchPath, $projectLaunchPath, $projectRootLaunchPath)) {
            $launch = Get-Content -LiteralPath $launchPath -Raw | ConvertFrom-Json
            Assert-Condition -Condition ($launch.configurations[0].program -eq (Join-Path $proBin 'ArcGISPro.exe')) `
                -Message "ArcGISPro.exe was not updated in '$launchPath'."
            Assert-Condition -Condition ($launch.configurations[0].cwd -eq $proBin) `
                -Message "The working directory was not updated in '$launchPath'."
        }
        foreach ($relativeBackupPath in @(
            '.vscode\launch.json',
            'src\AddIn\.vscode\launch.json',
            'src\AddIn\launch.json'
        )) {
            Assert-Condition `
                -Condition (Test-Path -LiteralPath (Join-Path $backupDirectory $relativeBackupPath) -PathType Leaf) `
                -Message "The launch.json backup is missing: $relativeBackupPath"
        }
        $buildResult = & $buildScript -ProjectPath $projectPath -Confirm:$false
        Assert-Condition -Condition ($buildResult.Succeeded -and $buildResult.ExitCode -eq 0) `
            -Message 'The repaired and verified Add-in fixture did not build successfully.'
    }

    Invoke-Evaluation -Name 'Repair and verify a Managed Configuration VB fixture' -Test {
        $projectRoot = Join-Path $tempRoot 'ManagedConfiguration'
        $projectPath = New-ProjectFixture `
            -Path $projectRoot `
            -ProjectExtension '.vbproj' `
            -ManifestName 'Config.xml' `
            -LaunchFile 'Properties\launchSettings.json'
        $repair = & $fixScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -ArcGISProVersion '3.5.0' `
            -BackupDirectory (Join-Path $tempRoot 'Backups\ManagedConfiguration') `
            -UpdateTargetFramework
        $verification = & $verifyScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -ExpectedTargetFramework $expectedTargetFramework `
            -ThrowOnFailure

        Assert-Condition -Condition $verification.IsValid `
            -Message 'Managed Configuration verification did not return IsValid.'
        Assert-Condition -Condition ($repair.FilesUpdated -eq 3) `
            -Message "Expected three Managed Configuration files to change but found $($repair.FilesUpdated)."
        $launch = Get-Content -LiteralPath (Join-Path $projectRoot 'Properties\launchSettings.json') -Raw |
            ConvertFrom-Json
        Assert-Condition -Condition ($launch.profiles.'Other Tool'.executablePath -eq 'C:\Tools\Other.exe') `
            -Message 'The non-ArcGIS launchSettings profile was not preserved.'
    }

    Invoke-Evaluation -Name 'Repair and verify a Plugin Datasource fixture' -Test {
        $projectRoot = Join-Path $tempRoot 'PluginDatasource'
        $projectPath = New-ProjectFixture `
            -Path $projectRoot `
            -LaunchFile 'Properties\launchSettings.json'
        $repair = & $fixScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -ArcGISProVersion '3.5.0' `
            -BackupDirectory (Join-Path $tempRoot 'Backups\PluginDatasource')
        $verification = & $verifyScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -ThrowOnFailure

        Assert-Condition -Condition $verification.IsValid `
            -Message 'Plugin Datasource verification did not return IsValid.'
        Assert-Condition -Condition ($repair.FilesUpdated -eq 3) `
            -Message "Expected three Plugin Datasource files to change but found $($repair.FilesUpdated)."
    }

    Invoke-Evaluation -Name 'Repair, verify, and build a manifest-free CoreHost fixture' -Test {
        $projectRoot = Join-Path $tempRoot 'CoreHost'
        $projectPath = New-ProjectFixture `
            -Path $projectRoot `
            -ManifestName '' `
            -LaunchFile '' `
            -NoDesktopImport
        $repair = & $fixScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -ArcGISProVersion '3.5.0' `
            -BackupDirectory (Join-Path $tempRoot 'Backups\CoreHost') `
            -UpdateTargetFramework

        Assert-Condition -Condition ($repair.FilesUpdated -eq 1) `
            -Message "Expected only the CoreHost project to change but found $($repair.FilesUpdated) files."
        Assert-Condition -Condition ($repair.TargetFramework -eq $expectedTargetFramework) `
            -Message 'The CoreHost target framework was not aligned.'
        $verification = & $verifyScript `
            -ProjectPath $projectPath `
            -ProInstallDir $proInstallDir `
            -ExpectedTargetFramework $expectedTargetFramework `
            -ThrowOnFailure
        Assert-Condition -Condition $verification.IsValid `
            -Message 'Manifest-free CoreHost verification did not return IsValid.'
        Assert-Condition -Condition ($verification.Errors.Count -eq 0) `
            -Message 'Manifest-free CoreHost verification returned errors.'
        $buildResult = & $buildScript -ProjectPath $projectPath -Confirm:$false
        Assert-Condition -Condition ($buildResult.Succeeded -and $buildResult.ExitCode -eq 0) `
            -Message 'The repaired and verified CoreHost fixture did not build successfully.'
    }

    Invoke-Evaluation -Name 'Enforce verification project contracts' -Test {
        $ordinaryRoot = Join-Path $tempRoot 'VerificationContracts\Ordinary'
        [void](New-Item -ItemType Directory -Path $ordinaryRoot -Force)
        $ordinaryProject = Join-Path $ordinaryRoot 'Ordinary.csproj'
        [System.IO.File]::WriteAllText(
            $ordinaryProject,
            "<Project Sdk=`"Microsoft.NET.Sdk`"><PropertyGroup><TargetFramework>$runtimeTfm</TargetFramework></PropertyGroup></Project>"
        )
        $ordinaryResult = & $verifyScript `
            -ProjectPath $ordinaryProject `
            -ProInstallDir $proInstallDir
        $ordinaryErrors = @($ordinaryResult.Errors) -join ' | '
        Assert-Condition -Condition (-not $ordinaryResult.IsValid) `
            -Message 'An ordinary .NET project passed ArcGIS verification.'
        Assert-Condition -Condition ($ordinaryErrors -like '*no ArcGIS references*') `
            -Message 'An ordinary .NET project did not return the unsupported-project reason.'

        $desktopRoot = Join-Path $tempRoot 'VerificationContracts\MissingManifest'
        $desktopProject = New-ProjectFixture `
            -Path $desktopRoot `
            -ManifestName '' `
            -LaunchFile ''
        & $fixScript `
            -ProjectPath $desktopProject `
            -ProInstallDir $proInstallDir `
            -ArcGISProVersion '3.5.0' `
            -BackupDirectory (Join-Path $tempRoot 'Backups\MissingManifest') | Out-Null
        $desktopResult = & $verifyScript `
            -ProjectPath $desktopProject `
            -ProInstallDir $proInstallDir
        $desktopErrors = @($desktopResult.Errors) -join ' | '
        Assert-Condition -Condition (-not $desktopResult.IsValid) `
            -Message 'A Desktop project without a manifest passed verification.'
        Assert-Condition -Condition ($desktopErrors -like '*has no Config.daml or Config.xml*') `
            -Message 'A Desktop project without a manifest did not return the missing-manifest reason.'

        $throwMessage = $null
        try {
            & $verifyScript `
                -ProjectPath $desktopProject `
                -ProInstallDir $proInstallDir `
                -ThrowOnFailure | Out-Null
        } catch {
            $caughtError = $_
            $throwMessage = $caughtError.Exception.Message
        }
        Assert-Condition -Condition ($throwMessage -like '*has no Config.daml or Config.xml*') `
            -Message 'ThrowOnFailure omitted the actionable missing-manifest reason.'

        $badCoreRoot = Join-Path $tempRoot 'VerificationContracts\BadCoreHost'
        $badCoreProject = New-ProjectFixture `
            -Path $badCoreRoot `
            -ManifestName '' `
            -LaunchFile '' `
            -NoDesktopImport
        $badCoreResult = & $verifyScript `
            -ProjectPath $badCoreProject `
            -ProInstallDir $proInstallDir
        Assert-Condition -Condition (-not $badCoreResult.IsValid) `
            -Message 'A CoreHost project with a stale HintPath passed verification.'
        Assert-Condition -Condition ((@($badCoreResult.Errors) -join ' | ') -like '*points outside*') `
            -Message 'A CoreHost project with a stale HintPath did not return the path reason.'
    }

    Invoke-Evaluation -Name 'Restore changes after malformed manifest XML' -Test {
        $projectRoot = Join-Path $tempRoot 'Rollback'
        $projectPath = New-ProjectFixture -Path $projectRoot -MalformedManifest
        $backupDirectory = Join-Path $tempRoot 'Backups\Rollback'
        $beforeHash = (Get-FileHash -LiteralPath $projectPath).Hash
        $failureMessage = $null
        try {
            & $fixScript `
                -ProjectPath $projectPath `
                -ProInstallDir $proInstallDir `
                -ArcGISProVersion '3.5.0' `
                -BackupDirectory $backupDirectory | Out-Null
        } catch {
            $caughtError = $_
            $failureMessage = $caughtError.Exception.Message
        }
        $afterHash = (Get-FileHash -LiteralPath $projectPath).Hash

        Assert-Condition -Condition ($beforeHash -eq $afterHash) `
            -Message 'The project file hash changed despite rollback.'
        Assert-Condition -Condition ($failureMessage -like '*all modified files were restored*') `
            -Message 'The failure did not report that modified files were restored.'
    }

    Invoke-Evaluation -Name 'Reject an incomplete installation candidate' -Test {
        $invalidInstall = Join-Path $tempRoot 'IncompleteArcGISPro'
        [void](New-Item -ItemType Directory -Path (Join-Path $invalidInstall 'bin') -Force)
        [System.IO.File]::WriteAllText((Join-Path $invalidInstall 'bin\ArcGISPro.exe'), 'fixture')
        $warnings = @()
        $detected = & $detectScript -InstallationCandidates @(
            [pscustomobject]@{
                RegistryPath = 'fixture'
                InstallLocation = $invalidInstall
                DisplayVersion = '3.5.0'
            }
        ) -WarningVariable warnings -WarningAction SilentlyContinue

        Assert-Condition -Condition ($null -eq $detected) `
            -Message 'Detection accepted an incomplete ArcGIS Pro installation.'
        Assert-Condition -Condition ($warnings.Count -gt 0) `
            -Message 'Detection rejected the installation without an actionable warning.'
    }

    Invoke-Evaluation -Name 'Select ArcGIS projects from a mixed workspace' -Test {
        $workspaceRoot = Join-Path $tempRoot 'MixedWorkspace'
        $arcGisProject = New-ProjectFixture `
            -Path (Join-Path $workspaceRoot 'ArcGISProject') `
            -ManifestName '' `
            -LaunchFile '' `
            -NoDesktopImport
        $ordinaryRoot = Join-Path $workspaceRoot 'OrdinaryProject'
        [void](New-Item -ItemType Directory -Path $ordinaryRoot -Force)
        $ordinaryProject = Join-Path $ordinaryRoot 'Ordinary.csproj'
        [System.IO.File]::WriteAllText(
            $ordinaryProject,
            "<Project Sdk=`"Microsoft.NET.Sdk`"><PropertyGroup><TargetFramework>$runtimeTfm</TargetFramework></PropertyGroup></Project>"
        )
        $generatedRoot = Join-Path $workspaceRoot 'obj\Generated'
        [void](New-Item -ItemType Directory -Path $generatedRoot -Force)
        Copy-Item -LiteralPath $arcGisProject -Destination (Join-Path $generatedRoot 'Generated.csproj')
        $githubProject = New-ProjectFixture `
            -Path (Join-Path $workspaceRoot '.github\skills\Template') `
            -ManifestName '' `
            -LaunchFile '' `
            -NoDesktopImport

        $discovered = @(& $findProjectsScript -WorkspacePath $workspaceRoot)
        Assert-Condition -Condition ($discovered.Count -eq 1) `
            -Message "Expected one ArcGIS project but discovered $($discovered.Count)."
        Assert-Condition -Condition ($discovered[0].ProjectPath -eq $arcGisProject) `
            -Message 'Discovery did not return the expected ArcGIS project.'
        Assert-Condition -Condition ($discovered.ProjectPath -notcontains $ordinaryProject) `
            -Message 'Discovery included an ordinary .NET project.'
        Assert-Condition -Condition ($discovered.ProjectPath -notcontains $githubProject) `
            -Message 'Discovery included a project under .github.'

        $githubWorkspaceError = $null
        try {
            @(& $findProjectsScript -WorkspacePath (Join-Path $workspaceRoot '.github')) | Out-Null
        } catch {
            $caughtError = $_
            $githubWorkspaceError = $caughtError.Exception.Message
        }
        Assert-Condition -Condition ($githubWorkspaceError -like 'WorkspacePath cannot be inside the .github directory.*') `
            -Message 'Discovery did not reject a workspace root inside .github.'
    }

    Invoke-Evaluation -Name 'Block a failed project build' -Test {
        $buildRoot = Join-Path $tempRoot 'Build'
        [void](New-Item -ItemType Directory -Path $buildRoot -Force)
        $invalidProject = Join-Path $buildRoot 'Invalid.csproj'
        [System.IO.File]::WriteAllText($invalidProject, '<Project><broken></Project>')
        $failureMessage = $null
        try {
            & $buildScript -ProjectPath $invalidProject -Confirm:$false | Out-Null
        } catch {
            $caughtError = $_
            $failureMessage = $caughtError.Exception.Message
        }
        Assert-Condition -Condition ($failureMessage -like 'Project build failed with exit code*') `
            -Message 'A failed build did not produce the expected blocking diagnostic.'
    }
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$results | Format-List
$failures = @($results | Where-Object { -not $_.Passed })
if ($failures.Count -gt 0) {
    throw "Evaluation failures: $($failures.Scenario -join ', ')"
}
$global:LASTEXITCODE = 0