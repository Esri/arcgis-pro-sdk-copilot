
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
  # Interview-selected ArcGIS Pro project type.
  [Parameter(Mandatory = $true)]
  [ValidateSet('Addin', 'Configuration', 'CoreHost', 'PluginDatasource')]
  [string]$ProjectType,

  # Normalized project identifier produced by the folder creation step.
  [Parameter(Mandatory = $true)]
  [string]$SafeProjectName,

  # Destination folder produced by the safe-project-name folder step.
  [Parameter(Mandatory = $true)]
  [string]$DestinationFolder,

  # Explicit VS Code workspace folder that owns the new project.
  [Parameter(Mandatory = $true)]
  [string]$WorkspaceRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ==============================
# Workspace Root Resolution
# ==============================
if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
  throw "WorkspaceRoot must be an existing VS Code workspace folder: $WorkspaceRoot"
}

$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path

# ==============================
# Template Source Resolution
# ==============================
# Map interview project type to the asset subfolder under ./.github/.../assets.
$sourceByProjectType = @{
  Addin            = './assets/addin'
  Configuration    = './assets/configuration'
  CoreHost         = './assets/corehost'
  PluginDatasource = './assets/plugin-datasource'
}

$SourceFolder = $sourceByProjectType[$ProjectType]

# Resolve source folder relative to the project-creator skill root.
$normalizedSourceFolder = $SourceFolder -replace '^[.][\\/]', ''
$projectCreatorRoot = Split-Path -Path $PSScriptRoot -Parent

if ([System.IO.Path]::IsPathRooted($SourceFolder)) {
  $templateRoot = $SourceFolder
} else {
  # Use the skill root as the anchor for relative asset paths.
  $templateRoot = Join-Path -Path $projectCreatorRoot -ChildPath $normalizedSourceFolder
}

# ==============================
# Input Validation
# ==============================
# Allow relative destination folders by anchoring them to the workspace root.
if (-not [System.IO.Path]::IsPathRooted($DestinationFolder)) {
  $DestinationFolder = Join-Path -Path $WorkspaceRoot -ChildPath $DestinationFolder
}

# Validate incoming SafeProjectName from the folder creation step.
if ([string]::IsNullOrWhiteSpace($SafeProjectName)) {
  throw 'SafeProjectName is required.'
}

# Fail fast if the computed source folder does not exist.
if (-not (Test-Path -Path $templateRoot)) {
  throw "Source asset folder was not found: $templateRoot"
}

# Ensure destination exists before copying content.
New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null

# ==============================
# Shared Asset Copy
# ==============================
# Copy shared image folders when present.
foreach ($folder in @('Images', 'DarkImages', 'Properties')) {
  $srcFolder = Join-Path -Path $templateRoot -ChildPath $folder
  if (Test-Path -Path $srcFolder) {
    Copy-Item -Path $srcFolder -Destination $DestinationFolder -Recurse -Force
  }
}

# Copy and rename the project file using SafeProjectName.
$projectFile = Join-Path -Path $templateRoot -ChildPath 'Project.csproj'
if (Test-Path -Path $projectFile) {
  Copy-Item -Path $projectFile -Destination (Join-Path -Path $DestinationFolder -ChildPath "$SafeProjectName.csproj") -Force
}

# ==============================
# Pattern-Specific Asset Copy
# ==============================
# Add-in and Configuration assets both include DAML and a module class file.
if ($ProjectType -in @('Addin', 'Configuration')) {
  $configDaml = Join-Path -Path $templateRoot -ChildPath 'Config.daml'
  if (Test-Path -Path $configDaml) {
    Copy-Item -Path $configDaml -Destination (Join-Path -Path $DestinationFolder -ChildPath 'Config.daml') -Force
  }

  # Add-in and Configuration assets both use Module1.cs.
  $modulePath = Join-Path -Path $templateRoot -ChildPath 'Module1.cs'
  if (Test-Path -Path $modulePath) {
    Copy-Item -Path $modulePath -Destination (Join-Path -Path $DestinationFolder -ChildPath 'Module1.cs') -Force
  }
}

# Configuration-only assets.
if ($ProjectType -eq 'Configuration') {
  $uiFolder = Join-Path -Path $templateRoot -ChildPath 'UI'
  if (Test-Path -Path $uiFolder) {
    Copy-Item -Path $uiFolder -Destination $DestinationFolder -Recurse -Force
  }

  $configurationManager = Join-Path -Path $templateRoot -ChildPath 'ConfigurationManager1.cs'
  if (Test-Path -Path $configurationManager) {
    Copy-Item -Path $configurationManager -Destination (Join-Path -Path $DestinationFolder -ChildPath 'ConfigurationManager1.cs') -Force
  }
}

# CoreHost-only asset, renamed to match SafeProjectName.
if ($ProjectType -eq 'CoreHost') {
  $coreHostSource = Join-Path -Path $templateRoot -ChildPath 'ProCoreHost.cs'
  if (Test-Path -Path $coreHostSource) {
    Copy-Item -Path $coreHostSource -Destination (Join-Path -Path $DestinationFolder -ChildPath "$SafeProjectName.cs") -Force
  }
}

# Plugin datasource-specific asset files.
if ($ProjectType -eq 'PluginDatasource') {
  # Keep the plugin asset file list explicit for predictable scaffolding.
  foreach ($fileName in @('Config.xml', 'ProPluginCursorTemplate.cs', 'ProPluginDatasourceTemplate.cs', 'ProPluginTableTemplate.cs')) {
    $sourcePath = Join-Path -Path $templateRoot -ChildPath $fileName
    if (Test-Path -Path $sourcePath) {
      Copy-Item -Path $sourcePath -Destination (Join-Path -Path $DestinationFolder -ChildPath $fileName) -Force
    }
  }
}

# ==============================
# Workspace Settings Merge
# ==============================
# Merge generated entries into workspace files without replacing existing settings.
function Merge-VsCodeConfigurationFile {
  param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$DestinationPath,
    [Parameter(Mandatory = $true)][string]$ArrayProperty,
    [Parameter(Mandatory = $true)][string]$EntryKey
  )

  if (-not (Test-Path -Path $DestinationPath -PathType Leaf)) {
    Copy-Item -Path $SourcePath -Destination $DestinationPath
    return
  }

  try {
    $sourceSettings = Get-Content -Path $SourcePath -Raw | ConvertFrom-Json
    $destinationSettings = Get-Content -Path $DestinationPath -Raw | ConvertFrom-Json
  } catch {
    throw "Unable to merge VS Code settings because a file is not valid JSON: $DestinationPath. $($_.Exception.Message)"
  }

  $sourceArray = $sourceSettings.PSObject.Properties[$ArrayProperty]
  if ($null -eq $sourceArray -or $sourceArray.Value -isnot [System.Array]) {
    throw "Template VS Code settings must contain an '$ArrayProperty' array: $SourcePath"
  }

  $destinationArray = $destinationSettings.PSObject.Properties[$ArrayProperty]
  if ($null -eq $destinationArray) {
    $destinationSettings | Add-Member -MemberType NoteProperty -Name $ArrayProperty -Value @()
    $destinationArray = $destinationSettings.PSObject.Properties[$ArrayProperty]
  } elseif ($destinationArray.Value -isnot [System.Array]) {
    throw "Workspace VS Code settings must contain an '$ArrayProperty' array: $DestinationPath"
  }

  $existingKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($entry in @($destinationArray.Value)) {
    $keyProperty = $entry.PSObject.Properties[$EntryKey]
    if ($null -ne $keyProperty) {
      $resolvedKey = ([string]$keyProperty.Value).Replace('{{SafeProjectName}}', $SafeProjectName)
      [void]$existingKeys.Add($resolvedKey)
    }
  }

  $mergedEntries = @($destinationArray.Value)
  foreach ($entry in @($sourceArray.Value)) {
    $keyProperty = $entry.PSObject.Properties[$EntryKey]
    if ($null -eq $keyProperty) {
      throw "Template entry in '$ArrayProperty' must contain '$EntryKey': $SourcePath"
    }

    $resolvedKey = ([string]$keyProperty.Value).Replace('{{SafeProjectName}}', $SafeProjectName)
    if ($existingKeys.Add($resolvedKey)) {
      $mergedEntries += $entry
    }
  }

  $destinationArray.Value = $mergedEntries
  $destinationSettings | ConvertTo-Json -Depth 100 | Set-Content -Path $DestinationPath -Encoding UTF8
}

$srcVsCode = Join-Path -Path $templateRoot -ChildPath '.vscode'
$dstVsCode = Join-Path -Path $WorkspaceRoot -ChildPath '.vscode'
if (Test-Path -Path $srcVsCode) {
  New-Item -ItemType Directory -Path $dstVsCode -Force | Out-Null

  Merge-VsCodeConfigurationFile `
    -SourcePath (Join-Path -Path $srcVsCode -ChildPath 'tasks.json') `
    -DestinationPath (Join-Path -Path $dstVsCode -ChildPath 'tasks.json') `
    -ArrayProperty 'tasks' `
    -EntryKey 'label'

  Merge-VsCodeConfigurationFile `
    -SourcePath (Join-Path -Path $srcVsCode -ChildPath 'launch.json') `
    -DestinationPath (Join-Path -Path $dstVsCode -ChildPath 'launch.json') `
    -ArrayProperty 'configurations' `
    -EntryKey 'name'
}

# ==============================
# Output Contract
# ==============================
# Return values for later workflow steps and diagnostics.
[pscustomobject]@{
  ProjectType       = $ProjectType
  SourceFolder      = (Resolve-Path -Path $templateRoot).Path
  DestinationFolder = (Resolve-Path -Path $DestinationFolder).Path
  SafeProjectName   = $safeProjectName
}