<!--
Copyright 2026 Esri
 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
    https://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
```
license: Apache-2.0
metadata:
  author: Esri, Inc.
  version: "1.0.0"
```
# Verification

## Objective

Verify that the generated ArcGIS Pro SDK project is complete, placeholders are fully resolved, and the selected project type builds successfully.

## Operating Rules

- Use these values captured from previous steps:
	- `ProjectType`
	- `DestinationFolder`
	- `SafeProjectName`
	- `ProInstallDir`
	- `ArcGISProVersion`
- Run `./scripts/05-verify-project.ps1` with `ProjectType`, `DestinationFolder`, `SafeProjectName`, `ProInstallDir`, and substitution output `ScannedRoots`.
- Use the verifier output as the authoritative result for required files, unresolved tokens, ArcGIS references, and the Debug build.

## Project-Type File Checks

Required files by project type:

- `Addin`
	- `SafeProjectName.csproj`
	- `Config.daml`
	- `Module1.cs`
	- `Images\` and `DarkImages\`
	- `Properties\launchSettings.json`
- `Configuration`
	- `SafeProjectName.csproj`
	- `Config.daml`
    - `Module1.cs`
	- `ConfigurationManager1.cs`
	- `UI\`
	- `Images\` and `DarkImages\`
	- `Properties\launchSettings.json`
- `CoreHost`
	- `SafeProjectName.csproj`
	- `SafeProjectName.cs` (renamed from `ProCoreHost.cs`)
	- `Properties\launchSettings.json`
- `PluginDatasource`
	- `SafeProjectName.csproj`
	- `Config.xml`
	- `ProPluginCursorTemplate.cs`
	- `ProPluginDatasourceTemplate.cs`
	- `ProPluginTableTemplate.cs`
	- `Properties\launchSettings.json`

## Token and Reference Validation

- Verify no unresolved tokens remain:
	- Search pattern: `\{\{[^}]+\}\}`
	- Check all text files under `DestinationFolder`.
- Specifically verify these tokens are replaced where used:
	- `{{ProInstallDir}}`
	- `{{ProInstallDirJson}}`
	- `{{ArcGISProVersion}}`
	- `{{SafeProjectName}}`
	- `{{DamlInstallDir}}`
	- `{{Date}}`
	- `{{NewID}}`
	- `{{VersionMajorMinor}}`
- If any `{{ProInstallDirJson}}` tokens remain in `.vscode` files, flag as unresolved and fail verification.
- Parse `SafeProjectName.csproj` as XML.
- Resolve every `Reference/HintPath` and `Import/@Project` path.
- Confirm each resolved file exists and is under canonical `ProInstallDir`; do not assume every assembly is under `bin\Extensions`.

## Validation Command

Run from the workspace root unless stated otherwise.

```powershell
& ./scripts/05-verify-project.ps1 `
	-ProjectType $ProjectType `
	-DestinationFolder $DestinationFolder `
	-SafeProjectName $SafeProjectName `
	-ProInstallDir $ProInstallDir `
	-ScannedRoots $SubstitutionScannedRoots
```

## Coverage Checklist

- Destination folder exists and contains `SafeProjectName.csproj`.
- Required files for the selected `ProjectType` are present.
- No unresolved `{{...}}` tokens remain.
- No unresolved `{{ProInstallDirJson}}` tokens remain in `.vscode` files.
- ArcGIS reference `HintPath` values resolve from `ProInstallDir`.
- `dotnet build` completed successfully.

## Handoff

When verification is complete, report:

- `ProjectType`
- `DestinationFolder`
- `SafeProjectName`
- Overall `Success` and `BuildSucceeded`
- Any missing files
- Any remaining tokens (with file paths)
- Any missing references or references outside the ArcGIS Pro installation

If verification fails, stop and provide the minimum corrective action needed before retrying verification.
