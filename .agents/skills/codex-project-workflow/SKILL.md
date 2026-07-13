---
name: codex-project-workflow
description: "Adapter entry for bounded repository tasks that need a compact Task Card, explicit edit boundaries, repository preflight, risk-based sub-agent decisions, and a concise final report. Canonical source is in skills/codex-project-workflow."
metadata:
  triggers:
    - start a bounded Codex project task
    - prepare a task card and repository preflight
    - implement a repository change with explicit boundaries
    - review or close a Codex implementation round
    - prepare a compact ChatGPT handoff report
  side_effects:
    - read_only
    - write_files
  canonical_path: ../../../skills/codex-project-workflow
  adapter_type: thin-wrapper
---

# codex-project-workflow

- Canonical skill directory: `../../../skills/codex-project-workflow`
- Canonical skill definition: `../../../skills/codex-project-workflow/SKILL.md`
- Use this wrapper for discovery only. Read the canonical skill before execution.
