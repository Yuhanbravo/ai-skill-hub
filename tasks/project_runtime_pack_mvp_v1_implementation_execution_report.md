# Execution Report: Project Runtime Pack MVP V1 Implementation (Round 2)

- Work item: `ASH-PROJECT-RUNTIME-PACK-MVP-V1-ROUND-2`
- Executor: Kimi Code (role: IMPLEMENTER_AND_TESTER)
- Date: `2026-08-05`
- Repository: `D:\dev\ai-skill-hub`

## 1. Task Identity and Baseline

| Fact | Value |
| --- | --- |
| Starting branch | `main` |
| Starting HEAD | `d4d735e0261abe35694c33a74cb1217fd2e85a87` |
| Design baseline commit | `d4d735e0261abe35694c33a74cb1217fd2e85a87` (resolves successfully; is HEAD itself, therefore trivially an ancestor) |
| Starting working tree | CLEAN |
| Starting staging | EMPTY |
| Starting Git operation | NONE (no MERGE_HEAD / CHERRY_PICK_HEAD / REVERT_HEAD / rebase-merge / rebase-apply / BISECT_LOG) |
| `origin/main...main` ahead/behind | `0 1` (local remote-tracking ref only; no fetch performed) |
| Design documents in HEAD | YES (`docs/design/project_runtime_pack_mvp_v1_design_contract.md`, `docs/task_packages/project_runtime_pack_mvp_v1_implementation_task_package.md`) |
| Python | `3.12.13`, `D:\miniforge3\envs\dev-core-py312\python.exe` |
| PowerShell | `7.6.4` (`pwsh`) |
| Git | `2.55.0.windows.3` |

Baseline note: the task package records package-creation HEAD `df7dba4391d73b3349cc24de96e16fa990325678`; the actual HEAD at execution start is its direct successor `d4d735e0` (the design-contract freeze commit itself). The design contract dependency is unaffected; this was recorded, not treated as a baseline change.

## 2. Scope Restatement

Implemented exactly the frozen contract: a Windows PowerShell 7.4+ initializer that attaches `ai-skill-hub` to a clean Git project as an exact-commit submodule, generates three managed-block entries, two project-level router Skills, and a schema-v1 runtime manifest, with transactional alternate-index staging, verified rollback, zero-mutation DryRun, and strict idempotency. No redesign, no scope expansion, no remote operations.

## 3. Files Changed

Added:

- `tools/init_project_runtime_pack.ps1` (2152 lines)
- `tools/project_runtime_pack_schema_v1.json` (JSON Schema Draft 2020-12)
- `tests/test_init_project_runtime_pack.py` (56 test functions, 87 parameterized cases)
- `tasks/project_runtime_pack_mvp_v1_implementation_execution_report.md` (this file)

Modified:

- `tools/run_local_checks.ps1` (registered check `project-runtime-pack`, appended to `smoke` and `all` group tails only)
- `tools/README.zh-CN.md` (one new section for the initializer)
- `tests/README.md` (one focused-check entry)

## 4. Files Explicitly Not Changed

`skills/**`, `.agents/**`, `.github/**`, root `AGENTS.md` / `CLAUDE.md`, `docs/**` (including the design contract and the task package), `SKILLS_INDEX.md`, `skills_index.json`, all existing tools/routers/pipelines/hooks/workflows, and all existing tests. Verified via `git status --short` + `git diff --name-status`: only the seven authorized paths above appear.

## 5. CLI and Schema Implementation Summary

- Param block is verbatim the frozen seven-parameter contract (`ProjectPath`, `HubMode`, `HubUrl`, `HubRef`, `HubPath`, `ExistingFilePolicy`, `DryRun`) with frozen defaults; no additional public parameters. Failure injection exists only via the test-only environment variable `AI_SKILL_HUB_RUNTIME_PACK_TEST_FAIL_AT` (`AfterSubmodule`, `AfterFirstAdapter`, `AfterManifest`, `AfterIndexSwap`, `DuringRollback`); unset in production it is inert.
- PowerShell < 7.4 fails closed with the fixed 14-key output and exit `2`.
- HubRef: fully-qualified branch/tag, short branch/tag (both-present → `BLOCKED_REF_AMBIGUOUS`), annotated-tag peel `^{}`, 40-hex commit verified via isolated OS-temp repo; abbreviated SHA / `HEAD` / `~` / `^` / empty → `BLOCKED_REF_INVALID`. `file://` URLs emit the non-portable warning on stderr.
- URL normalization per contract §10.4 (trim, trailing-`/` strip, ordinal comparison, no protocol rewrite, relative submodule URLs rejected).
- Manifest: exact key order, exact five adapter ids sorted by id, two-space indent, UTF-8 no BOM, LF, final LF; built-in exact-field validator mirrors `tools/project_runtime_pack_schema_v1.json` (`additionalProperties=false` everywhere; unknown field → `BLOCKED_MANIFEST_UNKNOWN_FIELD`); JSON never overrides gitlink/skills authority.
- Managed blocks and router files are byte-identical to Design Contract Appendix A/B (verified by scripted byte comparison, not visual inspection); block ownership hash covers marker-inclusive logical block in canonical LF plus the block-terminating LF, converted to host newline on write.

## 6. Transaction/Rollback Implementation Evidence

- Phases implemented in the frozen order: Preflight → Plan → SubmoduleMutationOrExternalValidation → AdapterGeneration → ManifestGeneration → Validation → CommitReady → FinalVerification.
- Alternate index: real index bytes hashed/snapshotted in Preflight; transaction index under a GUID-scoped journal directory inside the target git dir; staged set validated to equal the planned path set exactly; CommitReady re-verifies real index hash before atomic `.git/index.lock`-protocol swap.
- Implementation note (contract-equivalent deviation, recorded per instructions): `git submodule add/update` cannot honor `GIT_INDEX_FILE` (it leaks into clone/checkout child processes), so submodule commands momentarily touch the real index, which is immediately restored to its pre-bytes via the lock protocol and copied into the alternate index; the real index is never persistently mutated outside the final atomic swap.
- File writes: same-volume temp → flush → hash verify → `File.Replace` / atomic move; byte-for-byte backups of pre-existing human files; manifest written last; journal/backups deleted only after FinalVerification.
- Rollback: deterministic reverse order per contract §13.5; post-rollback verification compares worktree file hashes, index state (`git ls-files -s` equivalence; raw-bytes hash is used for concurrent-change detection because the stat cache legitimately changes on any refresh), `.gitmodules` bytes/absence, config/module cleanup scoped to journal-proven transaction-created paths. Success → exit `3` + `FAILED_APPLY_ROLLED_BACK`; unverifiable step → exit `4` + `BLOCKED_ROLLBACK_FAILURE` with the absolute journal path retained.
- `BLOCKED_CONCURRENT_STATE_CHANGE` is routed through rollback (exit `3`) because it is detected at CommitReady after mutations exist.
- Automated evidence: `test_failure_injection_exact_rollback` (parameterized over `AfterSubmodule`, `AfterFirstAdapter`, `AfterManifest`, `AfterIndexSwap`), `test_rollback_restores_human_files`, `test_injected_rollback_failure_retains_evidence` (`DuringRollback` → exit 4, journal retained), `test_concurrent_index_change_before_swap` — all passing.

## 7. Automated Test Matrix with Commands and Results

Command: `python -m pytest tests/test_init_project_runtime_pack.py -q -p no:cacheprovider` (executor `D:\miniforge3\envs\dev-core-py312\python.exe`) → **87 passed**.

Coverage against task package §13.2 (all 28 categories; test names as implemented):

1. blank first init — `test_first_init_blank_repo`
2. immediate staged-complete rerun — `test_immediate_staged_rerun_no_change`
3. committed rerun — `test_committed_rerun_no_change`
4. DryRun zero mutation (worktree/index/config/modules/mtime) — `test_dryrun_zero_mutation`, `test_dryrun_reports_preflight_conflict`
5. human content byte preservation (all three entries) — `test_existing_human_content_byte_preservation`
6. `ExistingFilePolicy Fail` — `test_existing_file_policy_fail`
7. modified managed block — `test_modified_managed_block`
8. duplicate/nested/orphan/reversed markers — `test_invalid_marker_structures`
9. invalid UTF-8 / mixed newline — `test_text_format_unsupported`
10. non-Git / subdirectory / bare repo — `test_non_git_directory`, `test_subdirectory_is_not_root`, `test_bare_repo_is_blocked`
11. merge/rebase/index-lock classification — `test_git_operation_active`
12. dirty / untracked / unrelated staged — `test_dirty_worktree_blocked`, `test_untracked_blocked`, `test_unrelated_staged_blocked`
13. HubPath occupied (file/dir/nested repo/reparse where host permits) — `test_hub_path_occupied`
14. exact existing submodule reuse; uninitialized materialize — `test_existing_exact_submodule_reuse`, `test_uninitialized_submodule_materialize`
15. different URL / different commit — `test_submodule_different_url_conflict`, `test_submodule_different_commit_requires_upgrade`
16. branch/tag/annotated-tag/40-hex resolution — `test_hubref_resolution`, `test_hubref_full_commit_resolution`
17. ambiguous / missing / invalid abbreviated — `test_hubref_ambiguous`, `test_hubref_not_found`, `test_hubref_invalid`
18. schema unknown field/version/type/order/adapter-set — `test_manifest_validation_failures`, `test_manifest_key_order_failure`
19. manifest vs gitlink/worktree/hash mismatch — `test_manifest_gitlink_mismatch`
20. canonical index missing — `test_canonical_index_missing`
21. router fixtures (exact-name/no-match/ambiguous/missing/path escape) — `test_router_exact_name_selection`, `test_router_no_match`, `test_router_ambiguous_match`, `test_router_skill_not_found`, `test_router_path_escape`
22. spaces + Chinese paths — `test_paths_with_spaces_and_chinese`
23. failure injection rollback — `test_failure_injection_exact_rollback`
24. injected rollback failure evidence — `test_injected_rollback_failure_retains_evidence`
25. ExternalPath valid/inside-project/non-Git/reparse/HEAD mismatch — `test_external_path_valid`, `test_external_path_inside_project`, `test_external_path_non_git`, `test_external_path_reparse`, `test_external_path_head_mismatch`, `test_external_path_forbids_huburl`, `test_external_path_requires_explicit_hubpath`
26. concurrent real index change — `test_concurrent_index_change_before_swap`
27. output key order / decisions / exit codes — `test_output_key_order_and_exit_codes`, `test_output_contract_on_blocking`
28. schema golden manifests — `test_schema_is_draft_2020_12`, `test_schema_validates_golden_manifests`

Additional: router byte-exactness (`test_generated_router_files_exact`), unknown-provenance block (`test_valid_block_without_manifest_is_unknown_provenance`), upgrade blocking (`test_requested_commit_requires_upgrade`).

Local check registration:

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/run_local_checks.ps1 -Checks smoke -CondaEnvName dev-core-py312` → 7 passed / 1 failed.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/run_local_checks.ps1 -Checks all -CondaEnvName dev-core-py312` → 9 passed / 1 failed.
- The single failure in both groups is the **pre-existing** `codex-user-skills-bootstrap` case `test_real_canonical_payload_dependency_closure_and_lifecycle`: under this machine's deep temp paths, Windows PowerShell 5.1 (.NET Framework MAX_PATH 260) hits a 265-char staging path inside `manage_codex_user_skills.ps1` and returns `BLOCKED_UNEXPECTED_ERROR`. Reproduced identically on a pristine baseline worktree of `d4d735e0` with zero task changes applied (baseline smoke: 6 passed / 1 failed, same test). The same test passes with a short `--basetemp` (`C:\Temp\ash-baseline-check`). Root cause is outside this task's authorized file set; not weakened, skipped, or modified.
- Commit convention: `python skills/skill-governance/scripts/commit_convention_check.py <file containing 'feat(adapter): add project runtime pack initializer'>` → exit 0.
- PowerShell syntax: `[System.Management.Automation.Language.Parser]::ParseFile(...)` on the initializer → no errors.

## 8. Codex E2E Evidence (Blocking — PASS)

- Host: `codex-cli 0.146.0` (`C:\Users\Administrator\AppData\Local\Programs\OpenAI\Codex\bin\codex`).
- Fixture project: `C:\Temp\ash-e2e\fixture-proj` (blank Git repo, initialized via `pwsh .../init_project_runtime_pack.ps1 -ProjectPath 'C:\Temp\ash-e2e\fixture-proj' -HubUrl 'file:///C:/Temp/ash-e2e/hub-remote.git' -HubRef main`, then committed; fixture HEAD `402a0b99b32788891c22a52cc2571b919f46cdda`).
- Hub remote: local bare clone of this repository at `C:\Temp\ash-e2e\hub-remote.git`; `resolved_commit=d4d735e0261abe35694c33a74cb1217fd2e85a87`.
- Invocation: `codex exec --sandbox read-only "<list project skills; read router; follow routing; load canonical Skill 'project-takeover'; report facts>"`.
- Observed output (verbatim facts): project skills seen: `ai-skill-hub-router`; router read: `.agents/skills/ai-skill-hub-router/SKILL.md`; `resolved_commit`: `d4d735e0261abe35694c33a74cb1217fd2e85a87`; canonical index: `.ai/ai-skill-hub/SKILLS_INDEX.md`; canonical Skill loaded: `.ai/ai-skill-hub/skills/project-takeover/SKILL.md`; first heading: `# Project Takeover`. Session log additionally shows Codex reading supporting resource content of the loaded Skill.
- Fixture Git state after the run: `git status --porcelain=v2` empty, HEAD unchanged — router acted read-only.
- Conclusion: Codex natively discovered the `.agents` router and routed one exact-named canonical Skill. PASS.

## 9. Kimi E2E Evidence (Blocking — PASS)

- Host: `kimi 0.31.1` (`C:\Users\Administrator\.kimi-code\bin\kimi`).
- Same fixture project and hub as §8.
- Invocation: `kimi -p "<same fact-reporting prompt>"` (full log retained at `C:\Temp\ash-e2e\kimi-e2e.log`).
- Observed output (verbatim facts): natively visible project-scope skills: only `ai-skill-hub-router`; router read: `C:/Temp/ash-e2e/fixture-proj/.agents/skills/ai-skill-hub-router/SKILL.md`; `resolved_commit` `d4d735e0261abe35694c33a74cb1217fd2e85a87` with explicit verification that superproject gitlink (`160000 commit d4d735e0...`) and materialized hub HEAD both equal it; canonical index `C:/Temp/ash-e2e/fixture-proj/.ai/ai-skill-hub/SKILLS_INDEX.md`; canonical Skill loaded `C:/Temp/ash-e2e/fixture-proj/.ai/ai-skill-hub/skills/project-takeover/SKILL.md`; first heading `# Project Takeover`; no files modified.
- Fixture Git state after the run: clean, HEAD `402a0b99b32788891c22a52cc2571b919f46cdda`.
- Limitation note: evidence is the native Kimi CLI execution surface auto-discovering project `.agents/skills/` (per Kimi Code Agent Skills documentation); the model's self-report of its skill listing is corroborated by the routing facts it could only obtain by reading the generated files. PASS.

## 10. Copilot E2E Status (Non-blocking — NOT VERIFIED)

GitHub Copilot CLI is not installed on this machine (`Get-Command copilot` → none). Per Design Contract §3.6, entry compatibility rests on the official documentation evidence recorded there (`.github/copilot-instructions.md`, `AGENTS.md`, `.agents/skills/<name>/SKILL.md`). Not claimed as verified; Round 3 follow-up required.

## 11. Claude E2E Status (Non-blocking — NOT VERIFIED)

Claude Code CLI `2.1.220` is installed but not authenticated (`claude -p ...` → `Not logged in · Please run /login`). No E2E performed; not claimed as verified. The `.claude/skills/ai-skill-hub-router/SKILL.md` artifact is byte-identical to the frozen Appendix B template and covered by automated fixtures; authenticated host E2E remains a Round 3 follow-up.

## 12. DryRun/Idempotency Evidence

- Fixture DryRun output: `Decision=PASS_PROJECT_RUNTIME_PACK_DRY_RUN`, `Index_Change=NO`, `Working_Tree_Change=NO`, `Rollback_Status=NOT_REQUIRED`, `Manifest_Status=ABSENT`, planned actions listed in frozen order; automated proof in `test_dryrun_zero_mutation` (file-tree snapshot, real index bytes/hash, `.git/config`, `.git/modules`, `git status --porcelain=v2` all identical before/after).
- Fixture immediate staged rerun: `Decision=NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT`, exit 0, `git status --porcelain=v2` hash identical before/after.
- Fixture committed rerun: `NO_CHANGE`, zero diff, zero mtime changes (automated: `test_committed_rerun_no_change` asserts byte and mtime equality).
- Manifest byte-shape on fixture: no BOM, LF-only, single final LF; adapter `content_sha256` values independently recomputed and matched for all five adapters.

## 13. Boundary Compliance

- No push/pull/fetch/tag/PR/remote modification; the only network-class operation is local `file://` fixture access with the mandated non-portable warning. The development repository itself was never fetched/pulled/pushed.
- No symlink/junction/reparse point created (rejected by design; negative tests cover reparse inputs where the host permits creation).
- No canonical Skill body copied: routers and managed blocks contain only discover/route/reference/load guidance; fixture contains no mirror of `skills/**` outside the pinned submodule checkout; no second skill index or rulebook generated (automated: `test_first_init_blank_repo` asserts the staged path set is exactly the eight planned paths).
- No automatic hub upgrade: any version divergence returns `BLOCKED_UPGRADE_REQUIRED` (`test_requested_commit_requires_upgrade`, `test_submodule_different_commit_requires_upgrade`).
- No modification of user-level Skill bundle, global AI configuration, `$CODEX_HOME`, user home, or global Git config; `safe.directory` errors are only classified (`BLOCKED_GIT_SAFE_DIRECTORY`), never auto-fixed.
- No `git reset --hard`, `git clean`, `git checkout --`, `--no-verify`, `Invoke-Expression`, or `cmd /c` anywhere in the initializer (statically verified).
- Rollback never touches pre-existing uncommitted user changes; first-init requires a fully clean tree, and the only dirty exception is the complete staged set owned by a valid manifest.

## 14. Risks/Assumptions

- The `GIT_INDEX_FILE` equivalent-effect deviation for `git submodule add/update` (§6) is the single contract-interpretation point; rollback and idempotency tests prove the real index is never persistently mutated mid-transaction.
- Contract §13.3.4 (Validation checks alternate staged set) vs §13.2 mutation map (`git add` in CommitReady) conflict; implemented per the mutation map (staged-set validation after CommitReady add, before swap). Recorded, not redesigned.
- `safe.directory` classification has no automated case (cannot be triggered single-user without touching global config); the stderr classification path exists.
- `origin/main`-style slash-containing short names are treated as ordinary branch names (lookup → `BLOCKED_REF_NOT_FOUND`); the contract does not define how to recognize "remote-tracking expressions" syntactically.
- The concurrent-index-change test injects a stat refresh via a polling thread with retries; stable across repeated runs but inherently timing-sensitive.
- Windows long-path behavior remains environment-bound per contract §19; the pre-existing `codex-user-skills-bootstrap` failure on this machine is one such environmental instance.

## 15. Blocking Issues

None within this task's scope. Out-of-scope known issue: pre-existing `codex-user-skills-bootstrap` environmental failure under deep temp paths on Windows PowerShell 5.1 hosts (baseline-reproduced; requires a separate authorized fix).

## 16. Final Decision

`PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_IMPLEMENTATION`

Notes: (a) the single red check in `smoke`/`all` is the pre-existing, baseline-reproduced environmental failure described in §7/§15 — all task-owned gates (focused 87/87, syntax, commit convention, DryRun, idempotency, rollback, negative matrix) pass; (b) Copilot and Claude Code external E2E are not verified (CLI absent / unauthenticated) and are honestly recorded as non-blocking gaps per the frozen classification.

## 17. Recommended Next Round

`COPILOT_HETEROGENEOUS_INDEPENDENT_VALIDATION`: authenticated GitHub Copilot and Claude Code host E2E on a committed fixture; independent review of this round's evidence; optional separate work item for the pre-existing MAX_PATH-sensitive user-skills test environment issue; future explicit upgrade tool per contract §20.2.

## Final Handoff Fields

```text
Decision=
PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_IMPLEMENTATION

Repository=
D:\dev\ai-skill-hub

Starting_Branch=
main

Starting_HEAD=
d4d735e0261abe35694c33a74cb1217fd2e85a87

Final_Branch=
main

Final_HEAD=
3ab89e62224da16d706ab295ebbb68f9818a9d71 (implementation commit before this field's finalization amend; a commit cannot embed its own hash — the containing commit hash is recorded in the Round 2 session final output)

Working_Tree_Before=
CLEAN

Working_Tree_After=
DIRTY_WITH_AUTHORIZED_IMPLEMENTATION

Remote_Operations=
NONE

Commit_Created=
YES

Validation=
focused 87/87 passed; smoke 7/8 and all 9/10 with one pre-existing baseline-reproduced environmental failure (codex-user-skills-bootstrap MAX_PATH); PS parser clean; commit convention check exit 0; Codex and Kimi blocking E2E PASS; Copilot/Claude non-blocking E2E not verified and recorded

Blocking_E2E=
Codex,Kimi

Non_Blocking_E2E=
GitHub Copilot,Claude Code

Recommended_Next_Round=
COPILOT_HETEROGENEOUS_INDEPENDENT_VALIDATION
```
