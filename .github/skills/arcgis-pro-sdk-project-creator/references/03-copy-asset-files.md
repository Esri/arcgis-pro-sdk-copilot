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
# Copy asset files

## Objective

Copy project asset files by running the template-copy script with interview-derived inputs.

## Operating Rules
- Use `ProjectType` from the interview process.
- Use `SafeProjectName` from the output of `./scripts/02-create-safe-project-name-folder.ps1`.
- Use `DestinationFolder` from the output of `./scripts/02-create-safe-project-name-folder.ps1`.
- Use `WorkspaceRoot` from the selected VS Code workspace folder.
- Run `./scripts/03-copy-asset-files.ps1` with:
	- `-ProjectType` set to `ProjectType`.
	- `-SafeProjectName` set to `SafeProjectName`.
	- `-DestinationFolder` set to `DestinationFolder`.
	- `-WorkspaceRoot` set to `WorkspaceRoot`.
- Merge template `.vscode` settings into the workspace files:
	- Preserve existing top-level properties and array entries.
	- Append tasks by unique `label` and launch configurations by unique `name`.
	- Do not duplicate entries when project creation is retried for the same `SafeProjectName`.
	- Stop without modifying an existing destination file when it is not valid JSON or its target property is not an array.
- Use the script output object for downstream values:
	- `SafeProjectName` from `output.SafeProjectName`
	- `DestinationFolder` from `output.DestinationFolder`
	- `SourceFolder` from `output.SourceFolder`

## Coverage Checklist
- Script executed with `ProjectType`, `SafeProjectName`, `DestinationFolder`, and `WorkspaceRoot`.
- Source asset folder resolved from `ProjectType`.
- `SafeProjectName`, `DestinationFolder`, and `SourceFolder` captured from script output.
- Required files for the selected project type copied to the destination folder.
- The asset folder's `Properties` directory, including `launchSettings.json` when present, copied to the destination folder.
- `.vscode` tasks and launch configurations appended to the workspace root without replacing existing entries.

## Handoff
When file copy is complete, report `ProjectType`, `SourceFolder`, `DestinationFolder`, and `SafeProjectName`, then proceed to the next workflow step.
