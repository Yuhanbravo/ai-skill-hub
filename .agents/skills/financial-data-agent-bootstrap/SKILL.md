---
name: financial-data-agent-bootstrap
description: "Adapter entry for bootstrapping agent rules, contracts, validation, task packages, reports, and handoff boundaries for financial data engineering or operations projects. Canonical source is in skills/financial-data-agent-bootstrap."
metadata:
  triggers:
    - bootstrap a financial data agent project
    - create financial data project AGENTS template
    - define data contract and source contract
    - prepare financial data task package
    - enforce read-only and production-write boundaries
  side_effects:
    - read_only
    - write_files
  canonical_path: ../../../skills/financial-data-agent-bootstrap
  adapter_type: thin-wrapper
---

# financial-data-agent-bootstrap

- Canonical skill directory: `../../../skills/financial-data-agent-bootstrap`
- Canonical skill definition: `../../../skills/financial-data-agent-bootstrap/SKILL.md`
- Use this wrapper for discovery only. Read the canonical skill before execution.
