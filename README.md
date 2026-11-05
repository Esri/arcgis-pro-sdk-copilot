# ArcGIS Pro SDK Copilot Workspace

This repository provides GitHub Copilot customizations for developers building ArcGIS Pro SDK for .NET solutions. It combines repository instructions, specialized agents, reusable skills, project templates, scripts, and curated reference material so Copilot can give consistent pattern guidance, refer developers to authoritative SDK resources, and create supported project types.

The content is intended for third-party ArcGIS Pro SDK developers using GitHub Copilot Chat in Visual Studio Code. The guidance and reference material may also be useful with other AI development tools, but the customization files and automated workflows in this repository are designed and validated for GitHub Copilot and VS Code.

This content is provided **as-is** in the same manner as we provide code samples and code snippets. You may adopt the complete workspace or reuse selected instructions, skills, templates, and references in your own repositories.

For a detailed explanation of the customization architecture and its capabilities, see [ProConcepts Pro SDK AI Features for GitHub Copilot](https://github.com/Esri/arcgis-pro-sdk/wiki/ProConcepts-Pro-SDK-AI-features)

## Goals

- Help ArcGIS Pro SDK developers choose the correct extensibility pattern for a workflow.
- Keep pattern recommendations aligned with the capabilities and boundaries of ArcGIS Pro.
- Improve the quality of generated C#, WPF/XAML, DAML, and project configuration.
- Direct API, feature-domain, installation, migration, and other resource questions to authoritative ArcGIS Pro SDK documentation.
- Create repeatable Add-in, Managed Configuration, CoreHost, and Plugin Datasource projects from maintained assets and scripts.
- Repair ArcGIS Pro SDK references and related project paths after installation or version changes.
- Keep decision logic, referral mappings, implementation practices, and project-creation steps maintainable and independently reusable.

## Repository Structure

The tree below summarizes tracked repository content; local metadata and empty directories are omitted. Asset, reference, and script folders are collapsed unless expanded below.

```text
.
|-- .gitattributes
|-- .github/
|   |-- copilot-instructions.md
|   |-- plugin/
|   |   |-- marketplace.json
|   |   `-- plugin.json
|   |-- instructions/
|   |   |-- arcgis-pro-sdk-best-practices.instructions.md
|   |   |-- arcgis-pro-sdk-example-resources.instructions.md
|   |   `-- arcgis-pro-sdk-pattern-help.instructions.md
|   |-- agents/
|   |   |-- arcgis-pro-sdk-pattern-help.agent.md
|   |   |-- arcgis-pro-sdk-project-creator.agent.md
|   |   `-- arcgis-pro-sdk-referral.agent.md
|   `-- skills/
|       |-- arcgis-pro-sdk-fix-pro-references/
|       |   |-- references/
|       |   |-- scripts/
|       |   `-- SKILL.md
|       |-- arcgis-pro-sdk-item-generator/
|       |   |-- references/
|       |   |   |-- 00-target-and-required-inputs.md
|       |   |   |-- 01-item-plan-and-confirmation.md
|       |   |   |-- 02-generation-and-verification.md
|       |   |   |-- 03-vscode-extension-delegation.md
|       |   |   `-- 04-item-patterns.md
|       |   `-- SKILL.md
|       |-- arcgis-pro-sdk-pattern-help/
|       |   |-- references/
|       |   `-- SKILL.md
|       |-- arcgis-pro-sdk-project-creator/
|       |   |-- assets/
|       |   |   |-- addin/
|       |   |   |-- configuration/
|       |   |   |-- corehost/
|       |   |   `-- plugin-datasource/
|       |   |-- references/
|       |   |-- scripts/
|       |   `-- SKILL.md
|       `-- arcgis-pro-sdk-referral/
|           |-- references/
|           `-- SKILL.md
|-- .gitignore
|-- LICENSE.txt
`-- README.md
```

## What's New

Copilot AI repo for ArcGIS Pro 3.8.

## Installation

There are two ways to use this content:

1. **Copy the `.github` folder to your repository root.** If you already have a [copilot-instructions.md](.github/copilot-instructions.md) file, merge this repository's routing instructions into yours rather than replacing your existing instructions. Keep the folder structure intact so relative paths resolve correctly.
2. **Install the plugin.** The plugin provides agents, skills, and supporting resources without copying them into your repository. However, it does not add this repository's [Copilot instructions](.github/copilot-instructions.md) to your workspace. Copying the instructions file alone may not work as intended because its references to other resources assume the repository's folder structure. To include those workspace-level routing instructions, use Option 1.

See [Quick Start](#quick-start) for both options. The commands below apply to plugin installation.

This repository uses the native GitHub Copilot CLI plugin layout. The plugin
manifest is `.github/plugin/plugin.json`, and the marketplace catalog is
`.github/plugin/marketplace.json`. It does not use the Agent Plugins 1.0 schema.

For marketplace installation, register the ArcGIS marketplace once:

```bash
# Register the public ArcGIS marketplace
copilot plugin marketplace add Esri/arcgis-pro-sdk-copilot
```

List the registered marketplaces and browse the ArcGIS catalog:

```bash
copilot plugin marketplace list
copilot plugin marketplace browse arcgis
```

Install the plugin from the registered marketplace:

```bash
copilot plugin install arcgis-pro-sdk@arcgis
```

Confirm that the plugin is installed:

```bash
copilot plugin list
```

The plugin may be installed in the user profile and used from any VS Code
workspace. Its installation directory contains the reusable agents, skills,
scripts, and templates; it is not a project output directory. Project creation
uses the folder open in VS Code as the workspace root. If no folder is open, or
if a multi-root workspace does not make the target folder clear, Copilot must
ask for a workspace folder before creating files.

Uninstall the plugin:

```bash
copilot plugin uninstall arcgis-pro-sdk
```

Refresh the catalog after marketplace changes are published, then update the
installed plugin when a new version is available:

```bash
copilot plugin marketplace update arcgis
copilot plugin update arcgis-pro-sdk@arcgis
```

### Direct Repository Installation

Current Copilot CLI releases also support installing directly from this
repository:

```bash
copilot plugin install Esri/arcgis-pro-sdk-copilot
```

The marketplace workflow remains recommended for customers because it provides
a named catalog for discovery and versioned updates.

## Key Components

### Repository Routing

`.github/copilot-instructions.md` contains the minimum routing instructions needed to incorporate this repository's ArcGIS Pro SDK AI resources into a Copilot environment. It is not intended to replace an existing `copilot-instructions.md` file. If your repository already has Copilot instructions, copy the ArcGIS Pro SDK routing policy from this repository's file into your existing file and retain your other project-specific instructions.

The routing policy directs requests to the customization that owns the behavior:

- Pattern explanations, comparisons, workflow-to-pattern recommendations, and pattern limitations route to `arcgis-pro-sdk-pattern-help`.
- ArcGIS Pro SDK API, feature-domain, and external-resource questions route to `arcgis-pro-sdk-referral`.
- Requests for code examples use the example-resource instructions and generated implementation code also follows the managed C# best practices.
- Requests to add new framework items to an existing Add-in or Managed Configuration route to `arcgis-pro-sdk-item-generator`.
- Explicit requests for a new supported extensibility project route to `arcgis-pro-sdk-project-creator`.

### Instructions

`.github/instructions` contains the canonical behavioral guidance:

- `arcgis-pro-sdk-pattern-help.instructions.md` defines the four patterns, their boundaries, internal grounding sources, and delegation rules.
- `arcgis-pro-sdk-example-resources.instructions.md` governs generated or adapted C#, WPF/XAML, and DAML examples, including version checks and validation expectations.
- `arcgis-pro-sdk-best-practices.instructions.md` defines implementation practices for threading, `QueuedTask`, background work, async flows, UI updates, DAML, and related managed SDK code.

The item generator bundles `references/04-item-patterns.md`, which defines its supported item patterns, required DAML and code relationships, and creation-time validation rules for Add-in and Managed Configuration projects.

The example-resource workflow defaults to explanation-only for conceptual requests. It requires explicit confirmation before editing implementation files; new-project scaffolding uses the project-creator workflow instead.

### Agents

`.github/agents` provides context-isolated specialists:

- `arcgis-pro-sdk-pattern-help` explains patterns and recommends one for a concrete workflow using the internal decision material.
- `arcgis-pro-sdk-referral` returns authoritative ArcGIS Pro SDK resources selected by category and sub-category.
- `arcgis-pro-sdk-project-creator` delegates the deterministic project-creation skill.

Pattern selection uses the `arcgis-pro-sdk-pattern-help` agent for context isolation and its skill for canonical workflow and bundled reference material.

### Skills and Assets

`.github/skills` contains reusable, multi-step workflows:

- `arcgis-pro-sdk-fix-pro-references` repairs ArcGIS Pro SDK DLL `HintPath` values, Desktop targets imports, DAML or `Config.xml` schema paths, and ArcGIS Pro launch profiles in existing Add-in, Managed Configuration, CoreHost, and Plugin Datasource projects. It detects the installed ArcGIS Pro version, optionally aligns the target framework, requires confirmation before editing, creates rollback copies, and verifies the repaired project with a build.
- `arcgis-pro-sdk-pattern-help` grounds pattern explanations, comparisons, limitations, and workflow recommendations in its bundled pattern summary, decision guide, and detail references.
- `arcgis-pro-sdk-referral` applies canonical matching and scoring rules to select the most relevant documentation links.
- `arcgis-pro-sdk-item-generator` adds new framework items to existing Add-in and Managed Configuration projects. It delegates to the VS Code item-generation tool when available; otherwise it validates the target project, resolves the item pattern, presents the complete file-and-wiring plan for confirmation, generates the item, and verifies its DAML, code, resources, placement, and invocation path.
- `arcgis-pro-sdk-project-creator` creates Add-in, Managed Configuration, CoreHost, and Plugin Datasource projects. Its checked-in assets include project files, source files, DAML or configuration files where applicable, images, and VS Code build/debug configuration.

The project creator also includes references for input collection, installation detection, safe folder creation, asset copying, token substitution, output verification, and optional delegation to an installed VS Code project-creation tool.

### Skill References

The pattern-help and referral skills contain curated sources under their respective `references` directories:

- A summary of the supported patterns and their principal boundaries.
- A decision guide for workflow-to-pattern recommendations and comparisons.
- Detailed references for Add-ins, Configurations, CoreHost applications, and Plugin Datasources.
- Referral details used to organize authoritative external resources.

These documents ship with the plugin, support agent reasoning, and are not intended to be cited as public SDK documentation.

## Quick Start

### Prerequisites

- Windows with ArcGIS Pro installed for project creation and local builds.
- GitHub Copilot Chat in Visual Studio Code. This workspace supports VS Code 1.129 or later.
- C# language tooling and the .NET SDK required by the targeted ArcGIS Pro version.
- ArcGIS Pro SDK references and build configuration appropriate for that version.

Use the installed or explicitly requested ArcGIS Pro version to select APIs, SDK references, and the .NET target. Current repository guidance uses .NET 8 for ArcGIS Pro 3.3 through 3.6 and .NET 10 for ArcGIS Pro 3.7 and later unless version-specific documentation states otherwise. Do not assume examples written against the latest API are compatible with an older release.

CoreHost applications additionally require a compatible ArcGIS Pro installation and license at runtime.

### Option 1: Copy into Your Repository

Use this option to keep the instructions and supporting resources together in
your repository:

1. Clone or download this repository.
2. Copy the `.github` folder into the root of your target repository, preserving any existing files.
3. If you already have a [copilot-instructions.md](.github/copilot-instructions.md) file, merge this repository's ArcGIS Pro SDK routing instructions into yours and retain your project-specific instructions.
4. Preserve the relative paths between agents, instructions, skills, references, scripts, and assets.
5. Open the target repository folder in VS Code and use Copilot Chat.

### Option 2: Install the Plugin

Install the plugin once in your user profile to use it from any VS Code
workspace:

```bash
copilot plugin marketplace add Esri/arcgis-pro-sdk-copilot
copilot plugin install arcgis-pro-sdk@arcgis
```

Open the target folder in VS Code, then use Copilot Chat for pattern help,
referrals, examples, or project creation. Generated projects are created in the
active workspace, not in the plugin installation directory. See
[Installation](#installation) for private-repository access, direct repository
installation, updates, and uninstall commands.

**Workspace instructions caveat:** The plugin does not add
this repository's [Copilot instructions](.github/copilot-instructions.md) to your
workspace. Copying the instructions file alone may not work as intended because
its references to other resources assume the repository's folder structure.
To include those workspace-level routing instructions, use Option 1.

Useful GitHub Copilot documentation:

- https://docs.github.com/en/copilot
- https://docs.github.com/en/copilot/how-tos/configure-custom-instructions-in-your-ide/add-repository-instructions-in-your-ide
- https://docs.github.com/en/copilot/how-tos/chat-with-copilot/get-started-with-chat-in-your-ide
- https://docs.github.com/en/copilot/how-tos/chat-with-copilot/chat-in-ide

### Common Workflows

| Example request | Route | Expected outcome |
| --- | --- | --- |
| "What is an ArcGIS Pro Add-in, and when should I use one?" | Pattern help | Explains the Add-in's purpose, fit, limitations, and representative uses. |
| "Should this workflow use an Add-in or a Managed Configuration?" | Pattern help | Compares the relevant boundaries and recommends a pattern from the workflow requirements. |
| "I need a custom start page and role-based ArcGIS Pro UI." | Pattern help | Recommends a Managed Configuration and explains its startup and UI scope. |
| "I need to expose a proprietary read-only format as feature classes." | Pattern help | Recommends a Plugin Datasource and calls out its read-only and non-visual boundaries. |
| "I need a nightly standalone geodatabase processing application." | Pattern help | Recommends CoreHost when its geodatabase/geometry API scope and runtime requirements fit. |
| "Can CoreHost customize the ArcGIS Pro ribbon?" | Pattern help | Explains that CoreHost is standalone and does not customize the ArcGIS Pro UI. |
| "Where is the ArcGIS Pro Geometry API documentation?" | Referral | Selects the relevant API or feature-domain category and returns authoritative links. |
| "Find resources for SDK installation, migration, signing, or debugging." | Referral | Maps the topic to the corresponding documentation category and returns focused links. |
| "Show me a C# example for an ArcGIS Pro dockpane." | Example resources and best practices | Establishes the target Pro/SDK version, verifies the example against current practices, and provides code only when explicitly requested. |
| "Add a dockpane to my existing Add-in." | Item generator | Confirms the target is an Add-in or Managed Configuration, plans all files and DAML wiring, requests implementation confirmation, then generates and validates the item. |
| "Create a new ArcGIS Pro Add-in project named ParcelTools." | Project creator | Uses the VS Code creation tool when available; otherwise gathers inputs, detects Pro, scaffolds assets, substitutes values, verifies files, and builds. |
| "Create a Plugin Datasource project in src/DataAdapters." | Project creator | Validates the relative destination, creates the Plugin Datasource project, and checks its expected files and references. |
| "Fix the ArcGIS Pro references in my existing project." | Fix Pro references | Detects ArcGIS Pro, confirms the target and framework update, creates rollback copies, repairs supported paths, and builds the project. |
| "Repair all ArcGIS Pro SDK project paths after moving ArcGIS Pro." | Fix Pro references | Processes the workspace projects after confirmation and reports changed files, backups, framework results, and build status. |

### Project Creation Workflow

The project creator supports exactly four project types: Add-in, Managed Configuration, CoreHost, and Plugin Datasource.

1. Resolve the target from the active VS Code workspace. Never use the plugin installation directory, skill path, or process working directory as the workspace root.
2. If the workspace has multiple roots and the target is ambiguous, ask the user to select one. Stop if no workspace folder is open.
3. Use the installed VS Code ArcGIS Pro project-creation tool when it is available, then stop after successful delegation.
4. Otherwise gather the project type, project name, and optional workspace-relative destination folder.
5. Detect the ArcGIS Pro installation and version from supported Windows registry locations.
6. Validate that the destination is inside the selected workspace, normalize a safe project name, apply the appropriate pattern suffix, and create a unique project folder.
7. Copy the selected pattern's checked-in assets and merge its `.vscode` files into the workspace configuration.
8. Replace project, identifier, version, and ArcGIS Pro installation placeholders in the copied files.
9. Check for unresolved tokens, missing pattern-specific files, incomplete VS Code substitutions, and invalid ArcGIS assembly `HintPath` values.
10. Build the generated project with `dotnet build` and report the result.

Project creation stops and reports actionable diagnostics when ArcGIS Pro cannot be detected, a destination is unsafe or already exists, required assets are missing, substitutions remain unresolved, or the generated project fails validation or build.

### Item Generation Workflow

The item generator adds new framework items only to existing Add-in and Managed Configuration projects. CoreHost and Plugin Datasource projects do not support these item templates.

1. Use the installed VS Code ArcGIS Pro item-generation tool when it is available, then stop after successful delegation.
2. Otherwise inspect the target project, `Config.daml`, module, namespace, ArcGIS Pro version, and nearby conventions.
3. Resolve the canonical item type, including ambiguous edit, sketch, and construction-tool requests.
4. Identify every required file, declaration, placement, category registration, companion control, and invocation path.
5. Present the complete plan and obtain explicit confirmation before editing implementation files.
6. Generate the minimum complete item pattern while preserving the existing Add-in or Configuration scaffold.
7. Validate DAML structure and references, code and XAML relationships, resources, visibility, invocation, and the target project build.

### Reference Repair Workflow

The reference-repair skill supports existing Add-in, Managed Configuration, CoreHost, and Plugin Datasource projects.

1. Find the workspace `.csproj` and `.vbproj` files, excluding generated output and asset folders.
2. Detect and validate the installed ArcGIS Pro location and version.
3. Plan target-framework alignment unless the user explicitly declines it, and verify that a compatible .NET SDK is installed.
4. Present the project path, ArcGIS Pro installation, and framework choice for explicit confirmation before changing files.
5. Create rollback copies and repair supported assembly paths, Desktop targets imports, schema paths, and launch profiles.
6. Restore modified files automatically if the repair script fails.
7. Verify the repaired paths and build the project, then report changed files, backup location, framework result, and build status.

## Troubleshooting

### ArcGIS Pro Detection Fails

- Confirm ArcGIS Pro is installed on Windows.
- Check ArcGIS Pro entries in the expected HKLM and HKCU uninstall registry locations.
- Verify the detected entry has valid `InstallLocation` and `DisplayVersion` values.
- Confirm the detected installation contains the expected `bin` folder.

### Project Folder Creation Fails

- Open the intended project folder as a VS Code workspace before requesting project creation.
- In a multi-root workspace, identify which workspace folder should contain the project.
- Use a workspace-relative folder; absolute paths and parent traversal are rejected.
- Choose a destination that does not already exist.
- Check that the project name can be normalized into a valid folder and identifier.

### Generated Project Fails Verification or Build

- Search generated text files for unresolved `{{...}}` placeholders.
- Confirm all required files for the selected pattern were copied.
- Verify substitutions were applied to project files and `.vscode` configuration.
- Check ArcGIS assembly `HintPath` values against the detected ArcGIS Pro installation.
- Confirm the compatible .NET SDK and C# tooling are installed.
- For CoreHost, confirm the ArcGIS Pro runtime and license requirements are satisfied.

### ArcGIS Pro Reference Repair Fails

- Review the reported blocking error for missing manifests, ambiguous DLL matches, malformed XML or JSONC, multi-target frameworks, or a missing compatible .NET SDK.
- Confirm the selected ArcGIS Pro installation contains the required assemblies and Desktop targets.
- Use the reported rollback directory if files need to be restored manually; rollback copies are never deleted automatically.
- Resolve unrelated build errors before rerunning the repair workflow.

### Guidance or Routing Appears Inconsistent

- Check `.github/copilot-instructions.md` for the current repository-level routes.
- Confirm the relevant agent description still matches its owning instruction or skill.
- Keep skill references, routing instructions, and agent contracts synchronized when behavior changes.
- Route API and feature-domain questions to referral rather than treating them as pattern-selection requests.

## Issues
Find a bug or want to request a new feature? Please let us know by emailing us at arcgisprosdk@esri.com.

## License

Copyright 2026 Esri

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

A copy of the license is available in the repository's [LICENSE.txt](LICENSE.txt) file.
