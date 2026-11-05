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
# VS Code Extension Language Model Tool Delegation

## Objective

Prefer the ArcGIS Pro SDK for .NET VS Code extension's language model tool. Use the bundled asset-copy workflow only when the tool is unavailable.

## Language Model Tool Contract

- Create-project tool reference: `#tool:createArcGISProProject`

Use VS Code's `#tool:<toolReferenceName>` syntax when referring to a language model tool in these instructions. The tool reference name is `createArcGISProProject`.

The tool owns project type, project name, VS Code workspace folder, and destination folder collection and validation. Invoke it without arguments. Do not gather the fallback workflow inputs before delegation. The tool must obtain workspace identity from VS Code editor context; it must not use the skill path, extension installation path, or process working directory as the workspace.

VS Code makes contributed language model tools available when their extension is installed and enabled. Do not explicitly activate the extension, inspect installed extensions, or probe unrelated capabilities.

## Availability Check

Perform this check before the fallback interview:

1. Check whether the language model tool #tool:createArcGISProProject is available in the current tool set.
2. If the tool is unavailable, continue with the fallback workflow.
3. If the tool is available, proceed directly to delegated creation.

Do not ask the user to install the extension during this workflow. The local bundled process remains authoritative fallback behavior.

## Delegated Creation

1. Invoke #tool:createArcGISProProject without arguments.
2. Let the tool collect and validate its inputs and create the project.
3. If the tool returns a destination, verify that it is inside the workspace folder selected by the tool. Treat an outside-workspace destination as a failed result.
4. Stop the skill workflow after the tool completes successfully.

## Fallback Rules

Use the bundled skill workflow when:

- The language model tool #tool:createArcGISProProject is not available in the current tool set.
- VS Code reports that the tool is unavailable before execution begins.

Once tool execution begins, do not run the fallback workflow. If the user cancels, the tool fails, or partial files may exist, stop and report the outcome instead of risking duplicate or overlaid project files.

## Handoff

Report whether project creation was delegated or the bundled fallback workflow was selected. The delegated tool owns its creation result; `./references/05-verification.md` applies to projects created by the bundled workflow.