# Compact Final Report Template

Use this structure for a ChatGPT handoff or project-specific final answer. Omit empty detail, but retain explicit non-implementation and validation status.

```markdown
## Final Report

- Branch / context: <branch or non-git context>
- Baseline: <commit, tag, or stated starting point>
- Task type: <classification>
- Changed files: <paths or `None`>
- Summary: <what the authorized work accomplished>
- Validation: <command — result; include not-run reason if applicable>
- Workflow adoption: <Task Card used; boundary template applied; preflight completed; local state sources read; sub-agents used or not used>
- Explicitly not implemented: <forbidden work, deferred phases, or no-change confirmation>
- Risks / assumptions: <active items or `None`>
- Recommended next action: <one concrete action>
```

Keep the report factual and compact. The main agent must review the final scope and evidence even when readonly sub-agents contributed findings.
