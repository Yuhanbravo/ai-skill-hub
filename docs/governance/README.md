# Governance Layer

This directory holds repository-governance documents that define or explain cross-repository rules, checks, and commit policy.

## Ownership

- Status: canonical home for repository-governance docs
- Owns: commit policy, adapter governance guidance, and future repository-level governance rules
- Does not own: active handoff/status artifacts, AI invocation rules, or human-layer repository overviews

## Contents

- `COMMIT_CONVENTION.md`: canonical commit-message convention for this repository
- `adapter_governance.md`: adapter drift-check scope, usage, and boundaries
- `stale_router_reconciliation_v1.md`: the only sanctioned maintainer reconciliation for the exact known pre-remediation machine router state (hash-verified, fail closed)
- `documentation_status_coordination.md`: minimum coordination note between `documentation-governance` and `update-project-status`
- `decisions/`: lightweight ADR / decision records for repository-level governance boundaries

## Quick Start

1. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\install_git_hooks.ps1` once in each new clone or worktree.
2. Write commit subjects according to [`COMMIT_CONVENTION.md`](COMMIT_CONVENTION.md).
3. Retry the commit after fixing any validation error reported by the `commit-msg` hook.

```text
clone / new worktree
  -> run tools/install_git_hooks.ps1 once
  -> write commit message
  -> commit-msg hook validates
  -> commit accepted or message corrected
```

The repository versions `.githooks/`; it does not version `.git/hooks/`.
