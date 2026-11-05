# Copyright 2026 Esri
 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
 
#     https://www.apache.org/licenses/LICENSE-2.0
 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# license: Apache-2.0
# metadata:
# author: Esri, Inc.
# version: "1.0.0"

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidateSet('Addin', 'Configuration', 'CoreHost', 'PluginDatasource')]
	[string]$ProjectType,

	[Parameter(Mandatory = $true)]
	[string]$DestinationFolder,

	[Parameter(Mandatory = $true)]
	[string]$SafeProjectName,

	[Parameter(Mandatory = $true)]
	[string]$ProInstallDir,

	[Parameter(Mandatory = $false)]
	[string[]]$ScannedRoots = @(),

	[Parameter(Mandatory = $false)]
	[switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$destinationPath = (Resolve-Path -LiteralPath $DestinationFolder -ErrorAction Stop).Path
$installPath = (Resolve-Path -LiteralPath $ProInstallDir -ErrorAction Stop).Path.TrimEnd(
	[System.IO.Path]::DirectorySeparatorChar,
	[System.IO.Path]::AltDirectorySeparatorChar
)
$projectFile = Join-Path -Path $destinationPath -ChildPath "$SafeProjectName.csproj"

$requiredFilesByProjectType = @{
	Addin            = @("$SafeProjectName.csproj", 'Config.daml', 'Module1.cs', 'Images', 'DarkImages', 'Properties\launchSettings.json')
	Configuration    = @("$SafeProjectName.csproj", 'Config.daml', 'Module1.cs', 'ConfigurationManager1.cs', 'UI', 'Images', 'DarkImages', 'Properties\launchSettings.json')
	CoreHost         = @("$SafeProjectName.csproj", "$SafeProjectName.cs", 'Properties\launchSettings.json')
	PluginDatasource = @("$SafeProjectName.csproj", 'Config.xml', 'ProPluginCursorTemplate.cs', 'ProPluginDatasourceTemplate.cs', 'ProPluginTableTemplate.cs', 'Properties\launchSettings.json')
}

$missingFiles = @(
	$requiredFilesByProjectType[$ProjectType] |
		Where-Object { -not (Test-Path -LiteralPath (Join-Path -Path $destinationPath -ChildPath $_)) }
)

$textExtensions = @(
	'.daml', '.json', '.xml', '.cs', '.xaml', '.csproj',
	'.config', '.props', '.targets', '.resx', '.txt', '.md',
	'.yml', '.yaml', '.editorconfig', '.sln', '.cmd', '.ps1'
)
$resolvedScanRoots = @(
	@($destinationPath) + @($ScannedRoots) |
		Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } |
		ForEach-Object { (Resolve-Path -LiteralPath $_).Path } |
		Select-Object -Unique
)
$remainingTokens = @(
	Get-ChildItem -LiteralPath $resolvedScanRoots -Recurse -File |
		Where-Object { $textExtensions -contains $_.Extension.ToLowerInvariant() } |
		Select-String -Pattern '\{\{[^}]+\}\}' |
		ForEach-Object {
			[pscustomobject]@{
				FilePath   = $_.Path
				LineNumber = $_.LineNumber
				Token      = $_.Matches.Value
			}
		}
)

$missingReferences = @()
$outsideInstallReferences = @()
if (Test-Path -LiteralPath $projectFile -PathType Leaf) {
	[xml]$projectXml = Get-Content -LiteralPath $projectFile -Raw
	$projectPaths = @(
		$projectXml.SelectNodes('//Reference/HintPath') | ForEach-Object { $_.InnerText }
	) + @(
		$projectXml.SelectNodes('//Import') | ForEach-Object { $_.GetAttribute('Project') }
	)
	foreach ($projectPath in ($projectPaths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })) {
		$path = [Environment]::ExpandEnvironmentVariables([string]$projectPath)
		if (-not [System.IO.Path]::IsPathRooted($path)) {
			$path = Join-Path -Path $destinationPath -ChildPath $path
		}

		$fullPath = [System.IO.Path]::GetFullPath($path)
		if (-not $fullPath.StartsWith($installPath + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
			$outsideInstallReferences += $fullPath
		}
		if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
			$missingReferences += $fullPath
		}
	}
}

$buildSucceeded = $null
$buildExitCode = $null
$buildOutput = @()
if (-not $SkipBuild -and (Test-Path -LiteralPath $projectFile -PathType Leaf)) {
	$buildOutput = @(& dotnet build $projectFile -c Debug 2>&1 | ForEach-Object { $_.ToString() })
	$buildExitCode = $LASTEXITCODE
	$buildSucceeded = $buildExitCode -eq 0
}

$success = (
	$missingFiles.Count -eq 0 -and
	$remainingTokens.Count -eq 0 -and
	$missingReferences.Count -eq 0 -and
	$outsideInstallReferences.Count -eq 0 -and
	($SkipBuild -or $buildSucceeded)
)

[pscustomobject]@{
	Success                  = $success
	ProjectType              = $ProjectType
	DestinationFolder        = $destinationPath
	SafeProjectName          = $SafeProjectName
	ProjectFile              = $projectFile
	MissingFiles             = $missingFiles
	UnresolvedTokens         = $remainingTokens
	MissingReferences        = $missingReferences
	OutsideInstallReferences = $outsideInstallReferences
	BuildSkipped             = [bool]$SkipBuild
	BuildSucceeded           = $buildSucceeded
	BuildExitCode            = $buildExitCode
	BuildOutput              = $buildOutput
}