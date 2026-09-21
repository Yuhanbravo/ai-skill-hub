# CLAUDE.md

@AGENTS.md

## Claude Code Notes

- Treat `AGENTS.md` as the shared repository entrypoint and keep this file Claude-specific and thin.
- For repository-local discovery, use `SKILLS_INDEX.md`, `.agents/skills/<skill-id>/SKILL.md`, or the flat `.agents/skills/<skill-id>.md` summary; both adapter shapes exist and route back to `skills/<skill-id>/SKILL.md`.
- Read the canonical `SKILL.md` and required supporting resources before execution. Adapter summaries are discovery surfaces only.
- Do not copy shared repository rules, mutable status, canonical skill bodies, or provider-specific manuals into this file.
- Follow the `repo-python` runtime and validation commands in `AGENTS.md`; do not select or repair a Python environment from Claude Code.
- If a task changes only documentation, preserve source, tests, adapters, protocols, and tooling unless its allowlist explicitly includes them.
