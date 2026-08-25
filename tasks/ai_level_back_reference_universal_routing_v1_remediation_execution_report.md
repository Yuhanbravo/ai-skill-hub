# AI_LEVEL_BACK_REFERENCE_UNIVERSAL_ROUTING_V1 — Remediation Execution Report

- Date: 2026-08-25
- Branch: `codex/ai-level-universal-routing-v1`
- Remediated from: `9231e5fb511d50069f93247720444cce8a13cb1f`
- Previous review decision: `BLOCKED_BY_ARCHITECTURE_CONTRACT`
- Scope discipline: no new standalone feature work item, no IDF entry, no merge, no remote write.

## 1. What changed

### Architecture contract freeze

`AI_LEVEL_CONFIG_BACK_REFERENCE_V1` is frozen in `docs/status/skill-hub-status.md` and
`docs/HANDOFF.md` (section-aware merge; the historical `AI_LEVEL_CONFIG_BACK_REFERENCE`
freeze and all pilot evidence are preserved, not rewritten). The frozen contract:

1. Canonical Skill resolution core is agent-agnostic.
2. After full Project Runtime Pack retirement, every currently supported local-development
   AI consumer retains a verified canonical Hub discovery path.
3. Agent discovery adapters may use each agent's native user-level Skill directory;
   physical paths are not required to be uniform.
4. Consumer Projects do not store canonical Skill payload.
5. Consumer Projects do not store machine-specific Hub absolute paths.
6. The User Bundle is not expanded into a full canonical Skill mirror.

Frozen V1 supported consumers: `CODEX`, `CLAUDE_CODE`, `GITHUB_COPILOT`, `KIMI_CODE`.

### Hub locator neutralization

- Before: `$CODEX_HOME/ai-skill-hub/locator.json` (Codex-bound).
- After: `~/.ai-skill-hub/locator.json` (agent-neutral; current user's home).
- Explicit config-home override for tests / isolated environments:
  `--config-home` or `AI_SKILL_HUB_CONFIG_HOME`.
- The locator remains the only component allowed to store the machine-local Hub checkout
  path; schema v1 + kind `ai-skill-hub.canonical-hub-locator` validation is unchanged and
  fail closed; no canonical Skill copy is created.
- No backward compatibility is carried for the old `$CODEX_HOME` locator: the candidate
  was never merged and no repo-tracked external dependency exists. One inert leftover
  instance of the old locator was observed on this machine (see Section 5).

### Thin adapter coverage

`configure` now manages one neutral locator plus three byte-identical thin router
adapters (all sharing the same locator, none containing canonical payload or Hub
absolute paths):

| Target id | Destination | Serves |
| --- | --- | --- |
| `codex_adapter` | `$CODEX_HOME/skills/ai-skill-hub-router/SKILL.md` | Codex |
| `claude_adapter` | `~/.claude/skills/ai-skill-hub-router/SKILL.md` | Claude Code |
| `agents_adapter` | `~/.agents/skills/ai-skill-hub-router/SKILL.md` | GitHub Copilot, Kimi Code (generic Agent Skills entry) |

No per-agent variants were needed: all three hosts consume the same `SKILL.md`
frontmatter + body contract, so one text serves all three; only the discovery root
differs. The adapter route text was hardened during runtime smoke to (a) resolve `~`
to the current user's home explicitly and (b) honor `AI_SKILL_HUB_CONFIG_HOME` when set.

Adapter roots resolve as: CLI flag → native env (`CODEX_HOME`, `CLAUDE_CONFIG_DIR`,
`AI_SKILL_HUB_AGENTS_HOME`) → default under the user home. All fail closed on relative
values.

### Configure safety

`configure` now runs in two phases:

1. Read-only preflight of the Hub (must be a valid non-bare Git checkout root), the
   locator destination (fixed default path for the effective config home), and **all**
   adapter destinations (unknown/conflicting content, non-file objects, reparse points
   at the destination or any existing ancestor).
2. Only after every target passes preflight, writes begin; each file write remains
   temp-file + atomic replace.

Any known conflict → decision `BLOCKED_LOCATOR_CONFLICT` / `BLOCKED_ROUTER_CONFLICT`
with `Mutation=NONE` and exit code 2 (previously a blocked configure could still exit
0; that is fixed). Reports now carry `mutation` (`NONE`/`PERFORMED`) and per-target
`managed_targets` actions. A crash-safe multi-file transaction journal is **not**
implemented; it is recorded as a non-blocking finding below.

### Empty requirement safety

`smoke` / `doctor` with zero declared required skills now fail closed with
`INSUFFICIENT_REQUIREMENTS` (exit 2, `overall=BLOCKED`, `routing_gap=YES`,
`requirements_declared=NO`). `--allow-empty-requirements` is the explicit opt-in for
"zero skills is intentional"; outputs then carry `zero_requirements_intentional=YES`
so automation can distinguish it from "no required skills discovered". Empty
requirements are never treated as migration-safe evidence.

### Tests

`tests/test_ai_skill_hub_resolver.py` now covers: neutral locator default + env/CLI
override + `CODEX_HOME` independence; Codex / Claude / generic Agent Skills thin
adapters; configure all-target preflight conflict with no new managed state (adapter
conflict and locator conflict); non-default configure locator rejection; zero required
skills fail-closed plus explicit intentional-zero; reparse-point rejection (symlinked
locator, junction Hub root, junction Skill directory, junction adapter ancestor);
malformed locator JSON; relative Hub root (configure argument and locator payload);
frontmatter identity mismatch; and the pre-existing bundled/unbundled resolution,
doctor `ADOPT_AS_IS`, invalid/missing/unavailable fail-closed states, unsupported
locator schema, and competing-identity ambiguity cases.

## 2. What was explicitly not changed

- Runtime Pack pinning semantics, manifest schema, initializer
  (`tools/init_project_runtime_pack.ps1`), project-local router behavior, and the
  supported pinned/portable modes — untouched; its pytest suite passes unchanged.
- No IDF modification, no Runtime Pack retirement, no User Bundle expansion, no
  canonical Skill duplication, no rollout, no retirement apply tool, no remote write,
  no unrelated refactor.
- Repo adapter surfaces (`.agents/skills/`, `.github/skills/`) untouched; the user-level
  adapters are generated machine state, not repo content.

## 3. Verification evidence

Environment note: this machine has no system Python on PATH; the existing
`D:\dev\Investment_Data_Flow\.venv` (Python 3.12.13, pytest 9.1.1) was used read-only
as the interpreter. Earlier sandboxed runs required a mkdir-mode shim; the final
evidence below was produced after the session file policy moved to
`danger-full-access`, without the shim.

- Focused tests: `python tests/test_ai_skill_hub_resolver.py` → 18/18 PASS.
- Controlled routing smoke (isolated temp homes, real Hub checkout
  `D:\dev\ai-skill-hub`): for each adapter surface (Codex, Claude, generic Agent
  Skills) the chain adapter file → neutral locator → resolver → canonical
  `skills/project-takeover/SKILL.md` was executed end to end; adapters contain no Hub
  absolute path; only `ai-skill-hub-router` exists under each adapter `skills` root;
  doctor on unbundled `documentation-governance` → `ADOPT_AS_IS`; empty requirements →
  `INSUFFICIENT_REQUIREMENTS`. Result: `CONTROLLED_ROUTING_SMOKE=PASS`.
- Real host runtime smoke, Kimi Code 0.38.0 (authenticated, `kimi -p`,
  `--skills-dir <isolated>` so only the isolated adapter is loaded,
  `AI_SKILL_HUB_CONFIG_HOME` pointing at the isolated config home): Kimi loaded
  `ai-skill-hub-router`, read the neutral locator, ran the resolver
  (`Skill_Result=project-takeover|RESOLVED|CANONICAL_ENTRY_RESOLVED|skills/project-takeover/SKILL.md`),
  read the canonical `SKILL.md` completely, and reported first heading
  `# Project Takeover`; no files modified; real user profile untouched
  (`~/.ai-skill-hub`, `~/.agents`, `~/.claude` remain absent).
- Full local regression `tools/run_local_checks.ps1 -Checks all`: 10/11 checks PASS.
  `project-runtime-pack` 124 passed (identical to pre-change baseline).
  `codex-user-skills-bootstrap` 70 passed / 1 failed
  (`test_real_canonical_payload_dependency_closure_and_lifecycle`) — this is the
  pre-existing MAX_PATH baseline failure already recorded in
  `docs/status/skill-hub-status.md`; it is identical before and after this round and is
  unrelated to the changed files.
- Git diff check: only the 7 files listed in Section 6 changed; no Runtime Pack,
  `skills/`, `.agents/`, `.github/`, or IDF files touched; no machine-specific absolute
  path added to any tracked file.

## 4. Runtime smoke evidence level per consumer

| Consumer | Adapter artifact + full routing chain | Real host discovery | Evidence level |
| --- | --- | --- | --- |
| CODEX | PASS (controlled) | NOT_RUNTIME_VERIFIED — no Codex CLI on this machine; Codex App cannot be driven headlessly here | Controlled smoke + tests |
| CLAUDE_CODE | PASS (controlled) | NOT_RUNTIME_VERIFIED — Claude Code not installed; historical user-level discovery version differences remain untestable locally | Controlled smoke + tests |
| GITHUB_COPILOT | PASS (controlled, generic adapter) | NOT_RUNTIME_VERIFIED — no Copilot CLI / headless VS Code driving available | Controlled smoke + tests |
| KIMI_CODE | PASS (controlled) | PASS via real `kimi --skills-dir` run (explicit-dir load); native auto-discovery of `~/.agents/skills` not probed because that would require writing to the real user profile | Real runtime smoke (explicit skills dir) |

Whether the three `NOT_RUNTIME_VERIFIED` host discoveries are sufficient for gate
purposes is deferred to the next Independent Review.

## 5. Observations on this machine (not acted upon)

- An inert leftover of the unmerged candidate exists at
  `C:\Users\Yuhan\.codex\ai-skill-hub\locator.json` plus
  `C:\Users\Yuhan\.codex\skills\ai-skill-hub-router\SKILL.md` (from earlier local
  experimentation with the candidate). The remediated design does not read these paths;
  they were left untouched. A maintainer may delete them manually after independent
  review.
- Stale ACL-restricted pytest temp directories under `.tmp\` predate this round and
  remain undeletable at the current privilege level; they are gitignored and do not
  affect test outcomes.

## 6. Files changed

- `tools/ai_skill_hub_resolver.py` — agent-neutral locator, three-adapter configure with
  all-target preflight, empty-requirement fail-closed, extended report fields.
- `tests/test_ai_skill_hub_resolver.py` — 18 focused tests (Section 1, Tests).
- `docs/status/skill-hub-status.md` — `AI_LEVEL_CONFIG_BACK_REFERENCE_V1` freeze record.
- `docs/HANDOFF.md` — contract freeze, hard boundaries, update log.
- `docs/human/CODEX_USER_SKILLS_BOOTSTRAP_WINDOWS.md` — routing section updated to the
  neutral locator and three thin adapters.
- `tools/README.zh-CN.md` — resolver tool documentation updated.
- `tests/README.md` — focused-test description updated.

## 7. Current blockers

None blocking. Independent review is the next gate.

## 8. Non-blocking findings

- Multi-file `configure` writes are individually atomic (temp + replace) but not
  journaled as one crash-safe transaction; a crash mid-write can leave a partially
  updated target set, which the next `configure` run heals idempotently. A full
  transaction journal is deferred as non-blocking scope.
- Claude Code user-level Skill discovery has historical version differences; file-level
  generation is verified, host discovery is not runtime-verified locally.
- Kimi native auto-discovery of `~/.agents/skills` was not probed under the
  no-real-profile-write constraint; the `--skills-dir` host-consumption path is verified.

## 9. Recommended next step

`INDEPENDENT_REVIEW` of this remediation commit.
