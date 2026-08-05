# Task Package: Project Runtime Pack MVP V1 Implementation

## 1. Task Identity

- Project: `ai-skill-hub`
- Project code: `ASH`
- Work item: `ASH-PROJECT-RUNTIME-PACK-MVP-V1-ROUND-2`
- Recommended executor: `Kimi`
- Role: `IMPLEMENTER_AND_TESTER`
- Target repository: `D:\dev\ai-skill-hub`
- Authoritative branch at package creation: `main`
- Package baseline HEAD: `df7dba4391d73b3349cc24de96e16fa990325678`
- Date: `2026-08-05`
- Local commit authorized after all blocking acceptance gates pass: `YES`
- Remote operations authorized: `NO`
- Expected commit subject: `feat(adapter): add project runtime pack initializer`

## 2. Required Reading and Authority

在改动前完整读取：

1. `AGENTS.md`
2. `skills/workflow-bootstrap/SKILL.md`
3. `skills/chatgpt-handoff-pilot/SKILL.md`
4. `docs/design/project_runtime_pack_mvp_v1_design_contract.md`
5. `docs/governance/decisions/ADR-0001-project-side-runtime-surface-and-linkage-boundary.md`
6. `docs/governance/COMMIT_CONVENTION.md`
7. `tools/run_local_checks.ps1`
8. `tools/manage_codex_user_skills.ps1`，仅用于参考 fail-closed transaction pattern，不得调用或修改

权威顺序：本 task package服从 Design Contract；若实现细节与 Design Contract 冲突，停止并报告，不得重新设计。

## 3. Scope Restatement

实现一个 Windows PowerShell 7.4+ initializer，使 clean Git repository 能以 exact-commit Git submodule接入 `ai-skill-hub`，并安全生成：

- 三个 managed-block入口；
- 两个项目级 router Skill；
- 一个 schema-v1 runtime manifest；
- 完整、可验证、fail-closed 的 transaction / rollback / DryRun / idempotency行为。

本轮只实现已冻结 contract。不得讨论或更换 submodule-first architecture、authority model、marker、schema、参数、默认值、transaction strategy、E2E blocking分类。

## 4. Precisely Authorized Files

### 4.1 Add

- `tools/init_project_runtime_pack.ps1`
- `tools/project_runtime_pack_schema_v1.json`
- `tests/test_init_project_runtime_pack.py`
- `tasks/project_runtime_pack_mvp_v1_implementation_execution_report.md`

### 4.2 Modify

- `tools/run_local_checks.ps1`
- `tools/README.zh-CN.md`
- `tests/README.md`

### 4.3 No other paths

任何其他文件均未授权。尤其不得修改：

- `skills/**`
- `.agents/**`
- `.github/skills/**`
- root `AGENTS.md`
- root `CLAUDE.md`
- root `.github/copilot-instructions.md`
- `docs/HANDOFF.md`
- `docs/status/**`
- `docs/design/project_runtime_pack_mvp_v1_design_contract.md`
- 本 task package
- 现有 sync/user-skill manager、router、pipeline、metadata、bundle、hook 或 workflow
- `SKILLS_INDEX.md`、`skills_index.json`

如果实现确实需要第 4.1/4.2 节之外的 production file，停止并回报 `SCOPE_EXPANSION_REQUIRED`。

## 5. Explicit Non-Goals

- 不实现 upgrade。
- 不支持非 Git project。
- 不支持 cross-platform。
- 不实现 `-Force` 或 interactive merge。
- 不复制完整 canonical Skill。
- 不写 `$CODEX_HOME`、用户 home 或全局 AI 配置。
- 不创建 symlink/junction/reparse point。
- 不在验证通过前 commit；不执行 push、PR、merge、tag。
- 不改变用户已有 staging；除 initializer 自己的 exact planned set外不 stage任何内容。
- 不新增 project template family、plugin、package manager 或 generic merge engine。

## 6. CLI Contract

脚本必须声明：

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [ValidateSet('Submodule', 'ExternalPath')]
    [string]$HubMode = 'Submodule',

    [string]$HubUrl,

    [string]$HubRef = 'main',

    [string]$HubPath = '.ai/ai-skill-hub',

    [ValidateSet('ManagedBlock', 'Fail')]
    [string]$ExistingFilePolicy = 'ManagedBlock',

    [switch]$DryRun
)
```

ExternalPath 组合约束：

- caller 必须显式传 `-HubMode ExternalPath`；
- 必须显式传 absolute `-HubPath`；如果值仍是默认值则阻塞；
- 禁止传 `-HubUrl`；
- 不修改 external repository。

相对 `ProjectPath` 基于 caller current directory。Submodule `HubPath` 基于 resolved project root。全部参数规则、URL规范化、HubRef解析和结果字段必须逐字遵守 Design Contract第 6、7、10、11、15、16 节。

## 7. Frozen Generated Artifacts

### 7.1 Managed markers

精确 marker：

```text
<!-- ai-skill-hub:runtime-pack:start schema=v1 -->
<!-- ai-skill-hub:runtime-pack:end -->
```

三个 managed block正文必须与 Design Contract Appendix A 完全一致；不得润色、扩写或加入实现说明。

### 7.2 Router frontmatter

两个 router 的 frontmatter 必须完全相同：

```yaml
---
name: ai-skill-hub-router
description: "Locate and load the appropriate canonical ai-skill-hub Skill for this project. Use when a task may benefit from reusable hub guidance or explicitly names a hub Skill."
---
```

### 7.3 Router body requirements

两个 router 的 body 可以共用同一生成函数和同一文本，因为从两个 `.../skills/ai-skill-hub-router/` 目录到 project root 都是 `../../..`。

两个 router 的完整文件内容必须与 Design Contract Appendix B 完全一致；不得自行改写措辞。以下列表用于实现/测试时核对该 exact template 的语义：

body 必须精确表达以下 algorithm，不加入 canonical Skill 正文：

1. router is read-only；它只 discover/route/reference/load。
2. project manifest 固定为 `../../../.ai/runtime-pack.json`。
3. 校验 schema/generator、hub mode/path、resolved commit和 adapter ownership。
4. Submodule 校验 committed gitlink、manifest commit和 materialized HEAD；ExternalPath校验 external HEAD。
5. 读取 manifest `routing.canonical_index`。
6. exact explicit name 优先；否则只在恰好一个清晰 semantic match 时选择。
7. no match/ambiguous/missing/mismatch 时返回 Design Contract定义的 router error 并停止。
8. index 的 canonical path 必须 containment-check 到 `<hub>/skills/<name>/SKILL.md`。
9. 完整读取 selected `SKILL.md`及其明确要求的 supporting resources。
10. 后续 mutation只可来自用户请求 + project rules + selected canonical Skill；router 不授予 mutation权限。

router不得：自动运行 initializer、自动 `git submodule update`、自动 fetch、自动修改 target、fallback到模型记忆或互联网副本。

### 7.4 `runtime-pack.json`

必须严格生成 Design Contract第 10.1 节的 shape：

- required top-level keys：`schema_version`, `generator`, `hub`, `routing`, `adapters`；
- exact `generator.id=ai-skill-hub.project-runtime-pack`；
- integer schema/generator version `1`；
- exact five adapter ids；
- adapter按 id ordinal ascending；
- `additionalProperties=false`；
- UTF-8 no BOM、two-space JSON、LF、final LF；
- SHA-256 lower hex；
- Submodule path相对 project root且用 `/`；ExternalPath绝对且 slash-normalized。

`tools/project_runtime_pack_schema_v1.json` 必须是 JSON Schema Draft 2020-12 文件，并表达相同 required/enum/pattern/additionalProperties约束。PowerShell 实现不得依赖外部 JSON Schema package；必须有同等严格的内建 validation。

## 8. Existing File Protection

实现 Design Contract第 9 节的全部规则：

- new file：只写 block；
- existing/no marker + ManagedBlock：EOF append，外部 bytes完全保留；
- existing/no marker + Fail：阻塞；
- exactly one valid block + valid manifest hash：允许验证/同版本 refresh；
- manifest missing、modified block、duplicate/nested/orphan/reversed marker：分别 fail closed；
- existing router 是 full-generated ownership，禁止人工 mixed content；
- UTF-8 with/without BOM支持；mixed newline阻塞；existing BOM/newline保持；
- 无 Force、无 interactive path。

测试必须证明 block 外 prefix/suffix bytes与执行前相同，不可只做文本等价比较。

## 9. Git and Ref Implementation Rules

### 9.1 Git invocation

- `Get-Command git.exe`；所有 args使用 array，不通过 `Invoke-Expression`、`cmd /c` 或拼接 shell string。
- capture stdout/stderr/exit code；禁止把 credential或完整敏感环境输出到 report。
- `safe.directory` error只分类，不执行 `git config`。

### 9.2 HubRef

按 Design Contract第 7 节实现：fully qualified branch/tag、short branch/tag、40-char commit；拒绝 abbreviated SHA和revision expressions；short branch/tag collision阻塞；annotated tag peel；commit在isolated OS temp repo验证。

已有 valid manifest rerun不得重新解析 remote branch/tag。

### 9.3 Submodule

- 新 submodule section name固定 `ai-skill-hub`。
- gitlink必须 checkout/stage到 resolved commit，不记录 branch-follow配置。
- exact same existing committed submodule可以复用。
- uninitialized exact submodule可以 materialize。
- mismatch只返回 conflict/upgrade decision，不自动修复。

### 9.4 Dirty/staged

- 首次执行必须完全 clean，包括 untracked。
- 唯一例外是上一轮成功 initializer留下的 complete valid staged set；必须用 manifest/hash/path set证明完整 ownership后返回 no-change。
- 不允许把用户 staged changes混入 alternate index或最终 index。

## 10. Transaction Implementation Sequence

必须按以下顺序实现，不得把 manifest提前写成“成功标记”：

1. `Preflight`
   - validate runtime versions、paths、Git root/operations/status、existing files/submodule/manifest。
   - snapshot target files、`.gitmodules`、real index hash/bytes、specific git config/module state。
2. `Plan`
   - resolve first-install ref；build exact path/action set；DryRun到此后输出并退出。
3. `SubmoduleMutationOrExternalValidation`
   - 创建 alternate index；所有 mutating Git command设置 `GIT_INDEX_FILE`。
   - Submodule add/materialize/checkout exact commit；ExternalPath只读验证。
4. `AdapterGeneration`
   - build all contents in memory；write scoped same-volume temp；verify hashes；atomic replace/move。
5. `ManifestGeneration`
   - 在其他 artifacts写完后生成并原子写 manifest。
6. `Validation`
   - schema、hash、marker、router、index、gitlink/worktree、canonical index、exact planned path set。
7. `CommitReady`
   - `git add`到 alternate index；再次确认 real index unchanged；通过 `.git/index.lock` protocol原子提交 alternate index。
8. `FinalVerification`
   - 校验 real staged set、worktree、manifest、gitlink；输出 success；删除 journal/backups。

## 11. Rollback Requirements

必须完整实现 Design Contract第 13.5 节。最低不可协商要求：

- 不使用 `git reset --hard`、`git checkout --`、`git clean` 或 broad recursive cleanup。
- index swap前后都可恢复 exact original index bytes/hash。
- existing human entry files byte-for-byte恢复。
- `.gitmodules` byte-for-byte恢复或恢复为 absent。
- 只删除 journal证明由本事务新建的 HubPath、specific module gitdir和specific config section。
- rollback后比较 `git status --porcelain=v2`、index hash、file hashes和pre-state。
- rollback成功返回 exit `3`；rollback无法验证返回 exit `4`，保留 scoped evidence并输出绝对 journal path。

在测试可控环境内提供 failure injection。建议使用仅在 test process设置的环境变量 `AI_SKILL_HUB_RUNTIME_PACK_TEST_FAIL_AT`，接受固定 values如 `AfterSubmodule`, `AfterFirstAdapter`, `AfterManifest`, `AfterIndexSwap`, `DuringRollback`。生产未设置时无行为；不得把 injection作为公开 CLI参数。

## 12. Result Contract

stdout key顺序固定：

```text
Decision
Project_Root
Hub_Mode
Hub_Path
Hub_Url
Requested_Ref
Resolved_Commit
Planned_Actions
Changed_Count
Index_Change
Working_Tree_Change
Rollback_Status
Manifest_Status
Message
```

success/blocking decision和 exit code必须使用 Design Contract第 16 节。人类 diagnostics写 stderr；stdout始终可由 line-based parser读取。

不要新增 `OutputFormat`、silent mode或隐式 prompts。

## 13. Test Requirements

### 13.1 Test harness

- 使用 Python stdlib + `pytest`（仓库现有模式）；不得引入新 dependency。
- test fixtures在 OS temp中创建 isolated superproject 和 bare/local hub remote。
- local remote可用 `file://`，并验证 non-portable warning；测试不得访问真实 network或真实 origin。
- test不得修改 source repository worktree、real user `$CODEX_HOME`、global Git config或credential store。
- 每个 test设置 isolated HOME/Git config环境，处理 Windows路径空格/中文。

### 13.2 Required automated cases

`tests/test_init_project_runtime_pack.py` 至少覆盖：

1. blank Git repo first init；
2. immediate staged-complete rerun no-change；
3. committed rerun no-change；
4. DryRun exact zero mutation，包括 index/config/modules/mtime；
5. existing human content byte preservation for all three entries；
6. `ExistingFilePolicy Fail`；
7. modified managed block；
8. duplicate/nested/orphan/reversed markers；
9. invalid UTF-8/mixed newline；
10. non-Git、subdirectory、bare repo；
11. merge/rebase/index-lock operation classification；
12. dirty、untracked、unrelated staged；
13. HubPath occupied by file/directory/nested repo/reparse point where host permits；
14. exact existing submodule and uninitialized clone；
15. different URL/different commit；
16. branch/tag/annotated-tag/40-char commit resolution；
17. ambiguous branch+tag、missing ref、invalid abbreviated SHA；
18. schema unknown field/version/type/order/adapter-set failures；
19. manifest vs gitlink/worktree/hash mismatch；
20. canonical index missing；
21. router exact-name selection、no-match、ambiguous、missing Skill、path escape fixtures；
22. paths with spaces and Chinese characters；
23. failure after submodule/adapter/manifest/index swap with exact rollback；
24. injected rollback failure retains evidence；
25. ExternalPath valid、inside-project、non-Git、reparse、HEAD mismatch；
26. concurrent real index change before swap；
27. output key order、decision、exit codes；
28. generated schema validates golden Submodule and ExternalPath manifests。

### 13.3 Local check registration

- 新 test以 `project-runtime-pack` 名称加入 `tools/run_local_checks.ps1`。
- 必须进入 `smoke` 和 `all`；不要改变现有组内其他 test顺序/语义。
- 更新两个 README 的最短调用和职责边界。

### 13.4 External E2E

实现者必须执行并阻塞：

- Codex：在 committed fixture project确认 `.agents` router可见，能从 exact user-named Skill读取 canonical `SKILL.md`。
- Kimi：同一 committed fixture确认 `.agents` router可见，能 `/skill:ai-skill-hub-router` 或自动选择并读取 canonical `SKILL.md`。

如果相应 host/CLI未安装或无法认证，Round 2 结论必须是 `BLOCKED_IMPLEMENTATION_ACCEPTANCE`，不能把 automated fixture冒充 external E2E。

非阻塞但需尝试/记录：GitHub Copilot、Claude Code。不可用时记录版本/缺口和 Design Contract中的官方文档证据，不阻塞 implementation commit。

## 14. Validation Commands

至少执行：

```powershell
python -m pytest tests/test_init_project_runtime_pack.py -q -p no:cacheprovider
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/run_local_checks.ps1 -Checks smoke
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/run_local_checks.ps1 -Checks all
python skills/skill-governance/scripts/commit_convention_check.py <message-file-containing-expected-subject>
```

如果仓库默认 Python需要显式 executor，沿用 `run_local_checks.ps1` 现有选择机制，不改其无关逻辑。

## 15. Acceptance Criteria

只有以下全部满足才可 PASS：

1. Authorized files范围准确，无其他 diff。
2. 参数、默认值、结果字段和 exit codes完全匹配冻结契约。
3. Submodule first init固定 exact gitlink，不记录 branch-follow行为。
4. ExternalPath无 fallback、无 mutation、明确不可移植。
5. 三个 existing human files按 bytes保护；modified managed content fail closed。
6. 两个 router保持 thin/read-only且能通过 manifest/index加载任一 canonical Skill。
7. JSON schema和内建 validator一致，unknown fields fail。
8. immediate rerun和committed rerun均零 diff/mtime/index变化。
9. DryRun零 worktree/index/git-admin变化。
10. 每个 failure-injection rollback恢复 exact pre-state；rollback failure保留 evidence。
11. focused、smoke、all checks通过。
12. Codex/Kimi external E2E通过。
13. Copilot/Claude E2E状态被诚实记录。
14. 全部 blocking gate 通过后创建一个本地 commit，且只使用预期 subject；不 push、不创建 PR。
15. execution report完整且不声称 rollout/distribution已完成。

## 16. Stop Conditions

立即停止并报告，不做替代设计：

- baseline已变化且影响 Design Contract依赖；
- working tree/staging存在与本任务冲突的未提交内容；
- 出现同类 initializer重叠实现；
- 无法在 authorized files内完成；
- 无法做到 exact index/worktree rollback；
- PowerShell/Git最小环境不满足且不能在本轮验证；
- canonical source origin/HubRef无法在 local test fixture与真实默认路径上确定；
- Codex或Kimi blocking E2E不可执行/失败；
- 任一 rollback failure不是按 contract保留 evidence和exit `4`；
- 需要修改 canonical Skill正文、user-level Skill、global config或credential。

发生 stop condition 时不得创建 commit。

非关键可读性偏好不得触发 redesign；按 frozen contract实现。

## 17. Forbidden Redesign Decisions

不得改变：

- Submodule默认 / ExternalPath explicit-only / no fallback；
- gitlink版本权威；
- 六项 required output；
- `.agents` 与 `.claude` router split；
- HTML marker；
- hash-based ownership；
- exact schema v1 fields；
- alternate-index transaction；
- clean-first policy和complete-staged-rerun exception；
- no-upgrade；
- Windows/PowerShell/Git floor；
- Codex/Kimi blocking与Copilot/Claude non-blocking E2E分类。

若发现设计缺陷，停止并提交 evidence；不要边实现边改 contract。

## 18. Execution Report Format

写入 `tasks/project_runtime_pack_mvp_v1_implementation_execution_report.md`，至少包含：

1. Task identity and baseline
2. Scope restatement
3. Files changed
4. Files explicitly not changed
5. CLI and schema implementation summary
6. Transaction/rollback implementation evidence
7. Automated test matrix with commands and results
8. Codex E2E evidence
9. Kimi E2E evidence
10. Copilot E2E status
11. Claude E2E status
12. DryRun/idempotency evidence
13. Boundary compliance
14. Risks/assumptions
15. Blocking issues
16. Final decision
17. Recommended next round

Final decision只能是：

```text
PASS_PROJECT_RUNTIME_PACK_MVP_V1_IMPLEMENTATION
PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_IMPLEMENTATION
BLOCKED_PROJECT_RUNTIME_PACK_MVP_V1_IMPLEMENTATION
```

## 19. Final Handoff Fields

execution report末尾追加：

```text
Decision=
<decision>

Repository=
D:\dev\ai-skill-hub

Starting_Branch=
<branch>

Starting_HEAD=
<commit>

Final_Branch=
<branch>

Final_HEAD=
<commit>

Working_Tree_Before=
<CLEAN|DIRTY>

Working_Tree_After=
<CLEAN|DIRTY_WITH_AUTHORIZED_IMPLEMENTATION>

Remote_Operations=
NONE

Commit_Created=
<YES；BLOCKED 时为 NO>

Validation=
<summary>

Blocking_E2E=
Codex,Kimi

Non_Blocking_E2E=
GitHub Copilot,Claude Code

Recommended_Next_Round=
COPILOT_HETEROGENEOUS_INDEPENDENT_VALIDATION
```
