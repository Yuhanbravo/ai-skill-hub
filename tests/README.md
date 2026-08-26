# tests

Repository-level test area for `ai-skill-hub`.

## Quick start

常用本地验证入口：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks smoke
```

## Focused checks

- Router / pipeline smoke:
  - `python tests/test_skill_router.py`
- AI-level canonical Skill resolution（agent-neutral locator、Codex / Claude / generic Agent Skills 薄 adapter、configure 全目标 preflight、空需求 fail-closed、consumer-routing doctor、已知 stale router 形态的 sanctioned reconciliation 与 near-miss fail-closed）:
  - `python tests/test_ai_skill_hub_resolver.py`
- Adapter consistency smoke (`consumer` + `hub` contract):
  - `python tests/test_adapter_consistency_smoke.py`
- Skill structure baseline:
  - `python tests/test_skill_structure.py`
- Project runtime pack initializer（需 `pwsh` + `git`，fixtures 全部在 OS temp 内）:
  - `python -m pytest tests/test_init_project_runtime_pack.py -q -p no:cacheprovider`

## Notes

- 这些测试主要保护 skill routing、adapter contract 和 canonical skill metadata 基线。
- 若需要更完整检查，优先使用 `tools/run_local_checks.ps1 -Checks all`。
