# Invocation Examples

### Input Example

```text
Use codex-project-workflow for this task.

task_description:
- Apply a small documentation update in a fictional repository.

authorized_paths:
- docs/example.md

constraints:
- Follow the project-local instructions and active task package.
- Do not modify files outside the authorized path.

expected_output:
- Compact Task Card and preflight result
- Bounded change with validation evidence
- Concise final report

context_files:
- AGENTS.md
- tasks/example_task_package.md
```
