---
name: arcgis-pro-sdk-project-creator
description: ArcGIS Pro SDK Project Creator. Use when you want to create a new ArcGIS Pro SDK project. Triggers "Make an addin", "Make a managed configuration", "Make a CoreHost", "Make a plugin datasource", "Create an ArcGIS Pro SDK addin project", "Create an ArcGIS Pro SDK managed configuration project", "Create an ArcGIS Pro SDK CoreHost project", "Create an ArcGIS Pro SDK plugin datasource project", "Create new ArcGIS Pro SDK project"
argument-hint: Provide project type and project name. A custom workspace-relative folder is optional.
license: Apache-2.0
metadata:
  author: Esri, Inc.
  version: "1.0.0"
---

<!-- Copyright 2026 Esri
 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
    https://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. -->

# ArcGIS Pro SDK Project Creator

## Purpose

Use this skill to create a new ArcGIS Pro SDK project. A project can only be one of the following: 
  * Add-in
  * Managed Configuration
  * CoreHost 
  * Plugin Datasource

# Workflow
1. Check for the VS Code extension language model tool and delegate project creation when available using `./references/06-vscode-extension-delegation.md`. Stop when delegated creation completes.
2. If delegation is unavailable, gather input requirements using `./references/00-required-inputs.md`.
3. Resolve the actual VS Code workspace folder from the editor context. Never infer it from the skill location, `$PSScriptRoot`, the process working directory, or the plugin installation directory. If no workspace folder is open, or a multi-root workspace does not identify which folder should own the project, stop and ask the user to choose a workspace folder.
4. Normalize the requested project type to the orchestrator value shown below, then run `./scripts/New-ArcGISProProject.ps1` once with the normalized project type, project name, and `-FolderRoot` set to the absolute path of the selected VS Code workspace folder. Pass `-FolderName` only when the user requested a custom workspace-relative folder.
5. Before reporting success, verify that `DestinationFolder` is inside the selected workspace folder. Use the returned object as the authoritative creation result. Report `Success`, `DestinationFolder`, `ProjectFile`, and `BuildSucceeded`; when unsuccessful, also report the populated diagnostic properties.

| Requested project type | Orchestrator `-ProjectType` value |
| --- | --- |
| Add-in | `Addin` |
| Managed Configuration or Configuration | `Configuration` |
| CoreHost | `CoreHost` |
| Plugin Datasource | `PluginDatasource` |

The run-once rule applies after project-type normalization. If PowerShell rejects the command during parameter binding, no orchestrator code or file creation has occurred; correct the argument and retry once. After the orchestrator begins executing, do not retry because partial files may exist.

The orchestrator owns ArcGIS Pro detection, folder creation, asset copying, substitution, reference verification, and building. It copies each project type's `Properties/launchSettings.json` into the generated project and resolves its template tokens during substitution. Do not invoke its stage scripts separately during the normal fallback workflow. The stage references remain available for maintaining or diagnosing an individual stage:

- `./references/01-ArcGISPro-detection.md`
- `./references/02-project-folder-creation.md`
- `./references/03-copy-asset-files.md`
- `./references/04-substitution-rules.md`
- `./references/05-verification.md`