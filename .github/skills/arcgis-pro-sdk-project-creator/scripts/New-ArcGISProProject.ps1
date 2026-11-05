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
	[ValidateSet('Addin', 'Add-in', 'Configuration', 'Managed Configuration', 'ManagedConfiguration', 'CoreHost', 'PluginDatasource', 'Plugin Datasource')]
	[string]$ProjectType,

	[Parameter(Mandatory = $true)]
	[string]$ProjectName,

	[Parameter(Mandatory = $false)]
	[string]$FolderName,

	[Parameter(Mandatory = $true)]
	[string]$FolderRoot,

	[Parameter(Mandatory = $false)]
	[switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectType = switch ($ProjectType) {
	'Add-in' { 'Addin' }
	'Managed Configuration' { 'Configuration' }
	'ManagedConfiguration' { 'Configuration' }
	'Plugin Datasource' { 'PluginDatasource' }
	default { $ProjectType }
}

if ([string]::IsNullOrWhiteSpace($FolderName)) {
	$FolderName = $ProjectName
}

$detection = & (Join-Path -Path $PSScriptRoot -ChildPath '01-detect-arcgis-pro.ps1')
if ($null -eq $detection) {
	throw 'ArcGIS Pro is required but was not detected.'
}

$folderParameters = @{
	ProjectType = $ProjectType
	ProjectName = $ProjectName
	FolderName  = $FolderName
	FolderRoot  = $FolderRoot
}

$folder = & (Join-Path -Path $PSScriptRoot -ChildPath '02-create-safe-project-name-folder.ps1') @folderParameters
$copy = & (Join-Path -Path $PSScriptRoot -ChildPath '03-copy-asset-files.ps1') `
	-ProjectType $ProjectType `
	-SafeProjectName $folder.SafeProjectName `
	-DestinationFolder $folder.DestinationFolder `
	-WorkspaceRoot $FolderRoot
$substitution = & (Join-Path -Path $PSScriptRoot -ChildPath '04-apply-substitution-rules.ps1') `
	-DestinationFolder $folder.DestinationFolder `
	-WorkspaceRoot $FolderRoot `
	-ProInstallDir $detection.ProInstallDir `
	-ArcGISProVersion $detection.ArcGISProVersion `
	-SafeProjectName $folder.SafeProjectName `
	-ProjectType $ProjectType
$verification = & (Join-Path -Path $PSScriptRoot -ChildPath '05-verify-project.ps1') `
	-ProjectType $ProjectType `
	-DestinationFolder $folder.DestinationFolder `
	-SafeProjectName $folder.SafeProjectName `
	-ProInstallDir $detection.ProInstallDir `
	-ScannedRoots $substitution.ScannedRoots `
	-SkipBuild:$SkipBuild

$success = (
	$verification.Success -and
	$substitution.RequiredTokensMissing.Count -eq 0 -and
	$substitution.UnresolvedTokens.Count -eq 0
)

[pscustomobject]@{
	Success                  = $success
	ProjectType              = $ProjectType
	ProjectName              = $ProjectName
	SafeProjectName          = $folder.SafeProjectName
	DestinationFolder        = $folder.DestinationFolder
	ProjectFile              = $verification.ProjectFile
	ProInstallDir            = $detection.ProInstallDir
	ArcGISProVersion         = $detection.ArcGISProVersion
	SourceFolder             = $copy.SourceFolder
	ScannedRoots             = $substitution.ScannedRoots
	FilesScanned             = $substitution.FilesScanned
	FilesUpdated             = $substitution.FilesUpdated
	ReplacementsByToken      = $substitution.ReplacementsByToken
	RequiredTokensMissing    = $substitution.RequiredTokensMissing
	UnusedAvailableTokens    = $substitution.UnusedAvailableTokens
	UnresolvedTokens         = $substitution.UnresolvedTokens
	MissingFiles             = $verification.MissingFiles
	MissingReferences        = $verification.MissingReferences
	OutsideInstallReferences = $verification.OutsideInstallReferences
	BuildSkipped             = $verification.BuildSkipped
	BuildSucceeded           = $verification.BuildSucceeded
	BuildExitCode            = $verification.BuildExitCode
	BuildOutput              = $verification.BuildOutput
}