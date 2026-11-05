
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
	# Pattern selected during the project-type interview step.
	[Parameter(Mandatory = $true)]
	[ValidateSet('Addin', 'Configuration', 'CoreHost', 'PluginDatasource')]
	[string]$ProjectType,

	# User-facing project name before normalization.
	[Parameter(Mandatory = $true)]
	[string]$ProjectName,

	# Workspace-relative destination folder requested by the user.
	[Parameter(Mandatory = $false)]
	[string]$FolderName,

	# Explicit VS Code workspace folder that owns the new project.
	[Parameter(Mandatory = $true)]
	[string]$FolderRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ==============================
# Workspace Root Validation
# ==============================
if (-not (Test-Path -LiteralPath $FolderRoot -PathType Container)) {
	throw "FolderRoot must be an existing VS Code workspace folder: $FolderRoot"
}

$FolderRoot = (Resolve-Path -LiteralPath $FolderRoot).Path

# ==============================
# Project Name Normalization
# ==============================
# Normalize project name into an identifier-safe token.
$projectNameWithoutSpaces = ($ProjectName -replace '\s+', '')
$normalizedProjectName = ($projectNameWithoutSpaces -replace '[^A-Za-z0-9_\-]', '')
if ([string]::IsNullOrWhiteSpace($normalizedProjectName)) {
	throw 'Normalized project name is empty.'
}

# ==============================
# Folder Path Validation
# ==============================
# Validate and normalize folder input as a workspace-relative path.
if ([string]::IsNullOrWhiteSpace($FolderName)) {
	$FolderName = $ProjectName
}

$folderNameInput = $FolderName.Trim()
$folderNameInput = $folderNameInput -replace '\\', '/'
if ([System.IO.Path]::IsPathRooted($folderNameInput)) {
	throw 'FolderName must be a workspace-relative folder path, not an absolute path.'
}

# Validate each path segment to prevent traversal and platform-invalid names.
$invalidFolderNameChars = [System.IO.Path]::GetInvalidFileNameChars()
$validatedFolderSegments = @()
foreach ($segment in ($folderNameInput -split '/')) {
	# Ignore empty segments so inputs like "a//b" normalize to "a/b".
	if ([string]::IsNullOrWhiteSpace($segment)) {
		continue
	}

	$trimmedSegment = $segment.Trim()
	if ($trimmedSegment -in @('.', '..')) {
		throw "Folder path segment '$segment' is not allowed."
	}

	# Validate against file-name character rules because each segment maps to a folder name.
	foreach ($invalidChar in $invalidFolderNameChars) {
		if ($trimmedSegment.Contains([string]$invalidChar)) {
			throw "Folder path segment '$segment' contains an invalid path character."
		}
	}

	$validatedFolderSegments += $trimmedSegment
}

if ($validatedFolderSegments.Count -eq 0) {
	throw 'Validated folder name is empty.'
}

$safeProjectName = $normalizedProjectName

# ==============================
# Destination Creation
# ==============================
# Create the destination folder only if it does not already exist.
$relativeFolderPath = ($validatedFolderSegments -join [System.IO.Path]::DirectorySeparatorChar)
$destinationFolder = [System.IO.Path]::GetFullPath((Join-Path -Path $FolderRoot -ChildPath $relativeFolderPath))
$folderRootPrefix = $FolderRoot.TrimEnd(
	[System.IO.Path]::DirectorySeparatorChar,
	[System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $destinationFolder.StartsWith($folderRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Destination folder must be inside the VS Code workspace folder: $FolderRoot"
}

if (Test-Path -LiteralPath $destinationFolder) {
	throw "Destination folder already exists: $destinationFolder"
}

New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null

# ==============================
# Output Contract
# ==============================
# Output contract consumed by later workflow steps.
[pscustomobject]@{
	SafeProjectName   = $safeProjectName
	DestinationFolder = (Resolve-Path -Path $destinationFolder).Path
}