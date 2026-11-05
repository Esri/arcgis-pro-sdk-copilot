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
# Substitution Rules

## Objective

Apply substitution tokens in the destination project and copied workspace `.vscode` files by running the substitution script.

## Operating Rules
- Use these input values from earlier workflow steps:
     - `DestinationFolder`
     - `ProInstallDir`
     - `ArcGISProVersion`
     - `SafeProjectName`
     - `WorkspaceRoot`
- Run `./scripts/04-apply-substitution-rules.ps1` with:
     - `-DestinationFolder` set to `DestinationFolder`
     - `-WorkspaceRoot` set to `WorkspaceRoot`
     - `-ProInstallDir` set to `ProInstallDir`
     - `-ArcGISProVersion` set to `ArcGISProVersion`
     - `-SafeProjectName` set to `SafeProjectName`
     - `-ProjectType` set to `ProjectType`

## Coverage Checklist
- Script executed with `DestinationFolder`, `WorkspaceRoot`, `ProInstallDir`, `ArcGISProVersion`, and `SafeProjectName`.
- Substitution tokens replaced for:
     - `ProInstallDir`
     - `ProInstallDirJson`
     - `ArcGISProVersion`
     - `SafeProjectName`
     - `WorkspaceRelativeProjectPath`
     - `DamlInstallDir`
     - `Date`
     - `NewID`
     - `VersionMajorMinor`
- Workspace `.vscode\tasks.json` and `.vscode\launch.json` files included in substitution coverage when copied by the asset step.
- The copied `Properties\launchSettings.json` file is included in project substitution; resolve `{{SafeProjectName}}` and `{{ProInstallDirJson}}` where present.
- Script output reviewed for:
     - `FilesScanned`
     - `FilesUpdated`
     - `ScannedRoots`
     - `ReplacementsByToken`
     - `UnresolvedTokens` (failure when populated)
     - `RequiredTokensMissing` (failure when populated)
     - `UnusedAvailableTokens` (informational only)

## Handoff
When substitution is complete, report `DestinationFolder`, `ScannedRoots`, `FilesScanned`, `FilesUpdated`, `ReplacementsByToken`, and any `UnresolvedTokens` or `RequiredTokensMissing`. Do not report `UnusedAvailableTokens` as a failure.