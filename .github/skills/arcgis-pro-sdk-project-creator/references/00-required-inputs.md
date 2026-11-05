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
# Required inputs

## Objective

Conduct a short, depth-first interview to collect the information needed to create an ArcGIS Pro C# project. Required inputs are project type, project name, and the actual VS Code workspace folder from editor context. A custom folder name is optional.
For a single-folder workspace, use that folder without asking a separate location question. For a multi-root workspace, ask which workspace folder should own the project unless the request already identifies it.

## Operating Rules
- Start from the user's initial request.
- Ask one question at a time.
- Ask follow-up questions when details are missing or ambiguous.
- Do not execute anything during the interview.
- Never derive the workspace folder from the skill file path, plugin installation path, `$PSScriptRoot`, or process working directory.
- If no workspace folder is open, stop and ask the user to open or select one; do not create a project relative to the installed skill.
- Project name is mandatory and must be explicit. A clear initial request such as "create a Configuration called WebMapGallery" satisfies this requirement; do not ask the user to confirm it again.
- When the user does not request a custom folder, use the project name as the workspace-relative folder without asking a separate folder question.
- Ask for a folder name only when the user requests a different location but does not provide it clearly.
- Folder name may include relative path components (for example: `my_addins/my_edit_addin`).
- Preserve path separators in folder names.
- When folder name includes path separators, treat it as a workspace-root-relative hierarchy and create missing parent folders as needed.
- Validate each folder path segment as a folder name instead of collapsing the whole path into a single normalized name.
- The final resolved destination folder must be unique in the workspace; if it already exists, ask the user for a different folder name.

## Coverage Checklist
Capture:
- Project type
- Project name (required)
- Workspace folder (required; obtained from editor context or selected by the user)
- Folder name (optional; defaults to project name)

## Handoff
When the interview is complete, store the project type, project name, and absolute path of the selected VS Code workspace folder. Store a workspace-root-relative folder name only when the user supplied a custom value; otherwise let the orchestrator default it to the project name.