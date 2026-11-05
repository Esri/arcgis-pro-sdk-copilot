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
# ArcGIS Pro SDK Copilot Instructions (.NET)

These instructions apply to ArcGIS Pro SDK for .NET workspaces in this repository.
ArcGIS Pro SDK extends ArcGIS Pro, a .NET desktop GIS application.

## Routing Policy Related to ArcGIS Pro SDK .NET 
- For questions and guidance related to ArcGIS Pro SDK for .NET, always follow the routing policies outlined below.
- For pattern-purpose help, pattern comparisons, workflow-to-pattern selection, limitations, or tradeoffs, the parent/default agent must invoke `arcgis-pro-sdk-pattern-help`. The pattern-help agent loads `skills/arcgis-pro-sdk-pattern-help/SKILL.md` and follows `instructions/arcgis-pro-sdk-pattern-help.instructions.md`; do not self-route when already running as that agent.
- Questions and requests for code examples, route to `instructions/arcgis-pro-sdk-example-resources.instructions.md`
- When generating code for ArcGIS Pro SDK .NET implementations, route to `instructions/arcgis-pro-sdk-best-practices.instructions.md`
- For requests to add, create, or generate ArcGIS Pro SDK items in an existing Add-in or managed Configuration project (for example, "Add a button," "Add a menu," "Add a new map tool," or "Make me a new feature selection tool"), invoke `arcgis-pro-sdk-item-generator`. The skill uses its bundled `references/04-item-patterns.md`, applies `instructions/arcgis-pro-sdk-example-resources.instructions.md` for its mandatory confirmation gate and generated-example conformance, and applies `instructions/arcgis-pro-sdk-best-practices.instructions.md` when the item includes workflow behavior. Item templates cannot be added to CoreHost or Plugin Datasource projects.

<!-- add instructions for ArcGIS org copilot repo here.

     Instructions for Esri should go into copilot-instructions.esri_org.md.
    'ArcGIS' copilot-instructions.md is NOT published to Esri.
-->
