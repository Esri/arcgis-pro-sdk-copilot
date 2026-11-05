---
description: "Use for ArcGIS Pro SDK pattern-purpose help, pattern comparison, workflow-to-pattern selection, limitations, and tradeoffs involving Add-in, Configuration, Plugin Datasource, or CoreHost; also governs routing to referral and project creation."
license: Apache-2.0
metadata:
  author: Esri, Inc.
  version: "1.0.0"
---

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

# ArcGIS Pro SDK Pattern Help Routing

Use this instruction set to route ArcGIS Pro SDK requests involving extensibility patterns, external resources, API or feature domains, code examples, or new projects.

## Routing

- For pattern-purpose questions, comparisons, limitations, tradeoffs, and workflow-to-pattern recommendations involving Add-in, Configuration, Plugin Datasource, or CoreHost, invoke `arcgis-pro-sdk-pattern-help`.
- When already running as `arcgis-pro-sdk-pattern-help`, load and follow [ArcGIS Pro SDK Pattern Help](../skills/arcgis-pro-sdk-pattern-help/SKILL.md). The skill is the canonical authority for grounding, source selection, and response requirements.
- For requests for external ArcGIS Pro SDK resources, delegate to `arcgis-pro-sdk-referral`.
- For ArcGIS Pro SDK API or feature-domain questions, delegate to `arcgis-pro-sdk-referral`. These include Map Authoring, Arcade, Geodatabase, Geometry, Layouts, Raster, Portal, Utility Network, Parcel Fabric, Tasks, Workflow Manager, and similar domains.
- When the pattern-help sources do not contain enough specific information to answer confidently, delegate to `arcgis-pro-sdk-referral`.
- For explicit requests to create a new Add-in, Configuration, Plugin Datasource, or CoreHost project, delegate to `arcgis-pro-sdk-project-creator`.
- For implementation code or code-example requests, return control to the caller so `arcgis-pro-sdk-example-resources.instructions.md` and, when code is generated, `arcgis-pro-sdk-best-practices.instructions.md` govern the response.
- If a request is neither pattern-purpose help nor an ArcGIS Pro SDK resource, API, feature-domain, code-example, or project-creation request, return a concise out-of-scope apology.