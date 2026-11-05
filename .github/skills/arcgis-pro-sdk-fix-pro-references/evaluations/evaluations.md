# ArcGIS Pro Reference Repair Evaluations

## Automated scenarios

Run from the repository root:

```powershell
& ./skills/arcgis-pro-sdk-fix-pro-references/tests/Test-ProReferenceScripts.ps1
```

The harness creates all inputs under a unique temporary directory and removes them after the run.

| Scenario | Representative input | Observable pass conditions |
|---|---|---|
| Repair, verify, and build an Add-in fixture | A nested, buildable `.csproj` with one stale ArcGIS `HintPath`, one non-ArcGIS reference, a stale Desktop targets import, one `Config.daml`, and stale profiles in workspace `.vscode/launch.json`, project `.vscode/launch.json`, and project-root `launch.json` | Repair and verification succeed; exactly five files change; all three launch profiles use the selected installation; each launch file has a distinct rollback copy; the ArcGIS path and target framework match; the non-ArcGIS reference remains; the repaired project builds successfully. |
| Repair and verify a Managed Configuration VB fixture | A `.vbproj` with `Config.xml` and `Properties/launchSettings.json` | Repair and verification succeed; exactly three files change; the non-ArcGIS launch profile remains unchanged. |
| Repair and verify a Plugin Datasource fixture | A `.csproj` with `Config.daml` and `Properties/launchSettings.json` | Repair and verification succeed; exactly three files change. |
| Repair, verify, and build a manifest-free CoreHost fixture | A buildable `.csproj` with an ArcGIS reference but no manifest, Desktop targets import, or ArcGIS Pro launch profile | Repair updates only the project and aligns its target framework; contract-based verification succeeds with no errors; the repaired project builds successfully. |
| Enforce verification project contracts | An ordinary .NET project, a Desktop project missing its manifest, and a CoreHost project with a stale HintPath | Each project fails with its specific actionable reason; `-ThrowOnFailure` preserves the missing-manifest reason. |
| Restore changes after malformed manifest XML | A repairable project beside malformed `Config.daml` | Repair fails; the project hash is unchanged after rollback; the error reports that modified files were restored. |
| Reject an incomplete installation candidate | A candidate containing `ArcGISPro.exe` but missing its runtime configuration and framework schema | Detection returns no installation and emits a warning. |
| Select ArcGIS projects from a mixed workspace | An ArcGIS project, an ordinary .NET project, an ArcGIS-looking generated project under `obj`, an ArcGIS project under `.github`, and a workspace root inside `.github` | Discovery returns only the top-level ArcGIS project, does not descend into `.github`, and rejects a root inside `.github`. |
| Block a failed project build | A malformed SDK project | The build script throws a blocking error with build diagnostics. |

## Execution record

On 2026-10-29, the harness was executed in PowerShell from the repository root.

The first run passed rollback and invalid-installation rejection but failed the Add-in scenario. It exposed a strict-mode defect where one manifest path became a scalar before the scripts read its `Count` property. The repair and verification scripts were changed to retain manifest paths as arrays.

The suite was expanded to cover the advertised project labels, both supported project extensions, both manifest names, both launch-file formats, and the build gate. The same command was then rerun with this result:

| Scenario | Result |
|---|:---:|
| Repair, verify, and build an Add-in fixture | PASS |
| Repair and verify a Managed Configuration VB fixture | PASS |
| Repair and verify a Plugin Datasource fixture | PASS |
| Repair, verify, and build a manifest-free CoreHost fixture | PASS |
| Enforce verification project contracts | PASS |
| Restore changes after malformed manifest XML | PASS |
| Reject an incomplete installation candidate | PASS |
| Select ArcGIS projects from a mixed workspace | PASS |
| Block a failed project build | PASS |

Exit status: `0`.

## Fresh-context discovery record

On 2026-10-29, two isolated, read-only VS Code subagent contexts evaluated skill selection without receiving prior conversation state:

| Invocation | Input | Observable pass conditions | Result |
|---|---|---|:---:|
| Explicit command-style invocation | `/arcgis-pro-sdk-fix-pro-references repair my ArcGIS Pro SDK project references` | Select this skill, identify `00-find-arcgis-pro-projects.ps1` as the first script, and reproduce the exact approval sentence. | PASS |
| Automatic discovery | A natural-language request describing a moved ArcGIS Pro installation and broken DLL HintPaths, Desktop targets import, and launch profile | Select this skill from metadata and identify project discovery plus explicit approval as the first controls. | PASS |

Both contexts selected `arcgis-pro-sdk-fix-pro-references`. The explicit context reproduced the required approval sentence exactly; the automatic-discovery context matched the request to the capability statement and selected the classifier first.

## Untested boundaries

- Copilot CLI slash invocation was not evaluated because the CLI is not installed. The explicit invocation above used a fresh VS Code subagent context.
- Cross-model and cross-runtime behavior has not been evaluated.