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
# Project Folder Creation

## Objective
Create the destination project folder by running the folder creation script with interview inputs.

## Operating Rules

- Use the project name and type from the interview process. Use a custom folder name when supplied; otherwise default it to the project name.
- Use the absolute workspace folder path obtained from VS Code editor context. Do not infer it from the skill or plugin installation path.
- Folder names may include relative path components (for example: `my_addins/my_edit_addin`).
- Preserve path separators in the requested folder name and create the corresponding folder hierarchy under workspace root.
- Run `./scripts/02-create-safe-project-name-folder.ps1` with:
	- `-ProjectType` set to the requested project type.
	- `-ProjectName` set to the requested project name.
	- `-FolderName` set only when a custom folder was requested.
	- `-FolderRoot` set to the absolute path of the selected VS Code workspace folder.
- Read the script output object and store:
	- `SafeProjectName` from `output.SafeProjectName`.
	- `DestinationFolder` from `output.DestinationFolder`.
- Use `DestinationFolder` as the destination for all later project file copy steps.
- Treat any destination outside `FolderRoot` as an error and do not create files.
- If a .code.workspace file exists, update it with the new project folder.


## Coverage Checklist
- Script executed with project type and project name, plus an optional custom folder name.
- `SafeProjectName` captured from script output.
- `DestinationFolder` captured from script output.
- Destination project folder created at `DestinationFolder`.
- `DestinationFolder` verified to be inside the selected workspace folder.
- Any parent folders implied by folder-name path components created under workspace root.
- Outside-workspace destinations rejected before file creation.
- .code.workspace updated when present.

## Handoff
When folder creation is complete, report `SafeProjectName` and `DestinationFolder`. If the folder could not be created, explain why and provide the next recommended step.

