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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$registryPaths = @(
	'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ArcGISPro'
	'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ArcGISPro'
)

foreach ($registryPath in $registryPaths) {
	if (-not (Test-Path -Path $registryPath)) {
		continue
	}

	$item = Get-ItemProperty -Path $registryPath
	$installLocation = ([string]$item.InstallLocation).TrimEnd(
		[System.IO.Path]::DirectorySeparatorChar,
		[System.IO.Path]::AltDirectorySeparatorChar
	)
	$displayVersion = [string]$item.DisplayVersion

	if ([string]::IsNullOrWhiteSpace($installLocation) -or -not (Test-Path -LiteralPath $installLocation -PathType Container)) {
		continue
	}

	[pscustomobject]@{
		RegistryPath      = $registryPath
		ProInstallDir     = $installLocation
		ArcGISProVersion  = $displayVersion
		InstallLocation   = $installLocation
		DisplayVersion    = $displayVersion
	}
	return
}

Write-Warning 'ArcGIS Pro was not detected in HKLM or HKCU uninstall registry keys.'