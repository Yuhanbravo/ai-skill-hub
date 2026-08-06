# Project Runtime Pack MVP V1 Design Contract

- Work item: `ASH-PROJECT-RUNTIME-PACK-MVP-V1`
- Contract status: `FROZEN_FOR_ROUND_2_IMPLEMENTATION`
- Frozen on: `2026-08-05`
- Target repository: `D:\dev\ai-skill-hub`
- Implementation authorized by this document: `NO`

## 1. Executive Decision

Project Runtime Pack MVP V1 采用“Git submodule 固定 canonical hub commit + 项目侧薄入口 + 两个原生 router Skill + 审计 manifest”的结构。

产品承诺冻结为：

```text
SUPPORTED=
所有 canonical Skill 均能被 AI 经由项目入口定位、选择和读取

NOT_GUARANTEED=
所有 canonical Skill 均显示为每个 AI 工具的原生 Skill 或 slash command
```

默认接入模式是 `Submodule`。`ExternalPath` 仅作为显式、本机型 opt-in；不存在自动 fallback。运行时版本权威是 superproject 的 submodule gitlink，Skill 正文权威是被固定 hub checkout 下的 `skills/`，`.ai/runtime-pack.json` 是生成、路由定位和审计记录，不是版本或 Skill 正文 SSOT。

本轮只冻结设计与 Round 2 实现契约，不实现 initializer，不修改工具、canonical Skill、adapter、status 或 handoff，也不执行远端操作。

## 2. Scope / Non-Scope

### 2.1 Scope

- 冻结 D-01 至 D-09。
- 冻结目标文件、CLI、schema、managed block、router、事务、回滚、幂等、DryRun 和错误 taxonomy。
- 为 Round 2 提供无需重新做架构选择的实现输入。
- 记录当前四类工具的入口兼容证据和仍需实际 E2E 的边界。

### 2.2 Non-Scope

- 不实现 `tools/init_project_runtime_pack.ps1`。
- 不升级现有 runtime pack。
- 不实现跨平台支持。
- 不复制或镜像全量 Skill。
- 不修改用户级 Skill、全局 AI 配置或凭证配置。
- 不创建 symlink、junction 或其他 reparse point。
- 不实现 `-Force`、交互式 merge、通用模板引擎、插件系统或 package manager。
- 不自动 push、PR、merge、tag 或 commit。
- 不把本设计写成已完成 rollout、distribution 或 adoption 的事实。

## 3. Repository Facts

### 3.1 Git baseline

| Fact | Observed value |
| --- | --- |
| Branch | `main` |
| HEAD | `df7dba4391d73b3349cc24de96e16fa990325678` |
| Expected HEAD | `df7dba4391d73b3349cc24de96e16fa990325678` |
| Local `origin/main` | `df7dba4391d73b3349cc24de96e16fa990325678` |
| Ahead / behind | `+0 / -0` |
| Working tree before docs | clean |
| Staging before docs | clean |
| Active Git operation | none |
| Origin URL | `gitea-nas:yuhanbravo/ai-skill-hub.git` |
| Git version observed | `2.55.0.windows.3` |
| PowerShell version observed | `7.6.4` |

未执行 `fetch`；`origin/main` 指本地已有 remote-tracking ref。当前 HEAD 与用户给出的预期值完全一致，因此无需后继关系例外判断。

### 3.2 Governance and current-state facts

- `AGENTS.md` 要求先读 `skills/workflow-bootstrap/SKILL.md` 和 `skills/chatgpt-handoff-pilot/SKILL.md`；已完成。
- `skills/` 是唯一 canonical Skill source of truth。
- `docs/HANDOFF.md` 与 `docs/status/skill-hub-status.md` 是 mutable current-state SSOT pair。
- 两份 current-state 文档仍在正文中记录较早的 observed `origin/main` `3919677`；Git 当前事实为本节所列 `df7dba...`。该滞后不改变 runtime-pack 设计基础，也不授权本轮刷新 status/handoff。
- 当前系统阶段仍为 `Phase 3 - Controlled System`。
- ADR-0001 要求既有 AI 文件增量接入、禁止复制 canonical 正文，并要求新 runtime surface 通过独立 task package 与 review；本设计及配套 Round 2 task package满足该进入方式，但尚未构成实施。

### 3.3 Existing runtime-pack guidance

现有 `workflow-bootstrap` 资产已经冻结以下基础：

- 项目侧入口必须 thin、reference-first、anti-second-rulebook。
- `AGENTS.md` 是共享主入口；`.github/copilot-instructions.md` 是 Copilot 薄适配入口。
- canonical path 必须是具体文件路径；不得凭空发明 project-local canonical payload。
- Phase 3A/3D 资产是未来项目侧 sketch/calibration，不是 initializer 实现。

本 MVP 在独立设计与任务包下新增 `CLAUDE.md`、两个 router Skill、submodule 和 manifest 契约；不回写或改变上述 canonical Skill 正文。

### 3.4 Existing tools and overlap result

| Existing asset | Actual boundary | Overlap decision |
| --- | --- | --- |
| `tools/sync_skills_to_nongit_project.ps1` | 用 `robocopy /MIR` 把 canonical Skill 复制到项目 `.codex/skills`，并生成 `.agents/.github` adapter；支持非 Git/文件级同步 | 不复用；它违反本 MVP 的“不镜像完整 Skill”产品边界，职责不同 |
| `tools/manage_codex_user_skills.ps1` | 管理 `$CODEX_HOME/skills` 中冻结的用户级 Bundle V1；带 ownership manifest、fingerprint、lock、staging 和 rollback | 只借鉴 fail-closed/transaction 设计；目标与权限边界不同，不调用、不修改 |
| `tools/codex_user_skills_manifest.json` | 冻结两个用户级 primary skills 与 `_protocol` dependency | 不作为项目 runtime-pack schema |

仓库中不存在 `init_project_runtime_pack`、`ai-skill-hub-router`、`.ai/runtime-pack.json` 或同名 schema。不存在职责重叠 initializer。

### 3.5 Naming, tests, hooks and docs conventions

- 设计文档位于 `docs/design/`，实现任务包位于 `docs/task_packages/`。
- 仓库级测试位于 `tests/test_<capability>.py`。
- 默认本地入口为 `tools/run_local_checks.ps1`；支持 `smoke` 与 `all` 分组。
- versioned commit hook 位于 `.githooks/commit-msg`，调用 `skills/skill-governance/scripts/commit_convention_check.py`。
- commit subject 使用 `<type>(<scope>): <action>`；本轮建议 `docs(adapter): freeze project runtime pack MVP contract`。

### 3.6 Current compatibility evidence

以下资料用于冻结“原生入口”与“文档路由”的边界，检索日期为 `2026-08-05`：

- Codex：[`AGENTS.md` guide](https://developers.openai.com/codex/guides/agents-md)；当前 Codex workspace 也已实际从本仓库 `.agents/skills/<name>/SKILL.md` 暴露项目 Skill。
- GitHub Copilot：官方文档列出 `.github/copilot-instructions.md`、`AGENTS.md` 以及 `.agents/skills/<name>/SKILL.md` 等项目级 Skill 位置：[custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions)、[agent skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)。
- Kimi Code：官方 Agent Skills 文档列出项目级 `.agents/skills/` 并说明根据 `description` 自动选择：[Kimi Code Agent Skills](https://moonshotai.github.io/kimi-code/en/customization/skills)。
- Claude Code：官方文档列出项目级 `.claude/skills/<name>/SKILL.md` 和 `CLAUDE.md`：[Claude Code Skills](https://code.claude.com/docs/en/slash-commands)、[extensions overview](https://code.claude.com/docs/en/features-overview)。

这些资料支持目标目录选择，但不替代 Round 2 的真实 host E2E。

## 4. Target Architecture

```text
new-project/
├─ .ai/
│  ├─ ai-skill-hub/                         # default: Git submodule checkout
│  └─ runtime-pack.json                     # locator + generation/audit record
├─ AGENTS.md                                # shared managed block
├─ CLAUDE.md                                # Claude managed block
├─ .agents/
│  └─ skills/
│     └─ ai-skill-hub-router/
│        └─ SKILL.md                        # Codex/Kimi/Copilot router
├─ .claude/
│  └─ skills/
│     └─ ai-skill-hub-router/
│        └─ SKILL.md                        # Claude router
└─ .github/
   └─ copilot-instructions.md               # Copilot managed block
```

路由链固定为：

```text
native project entry
  -> ai-skill-hub-router
  -> .ai/runtime-pack.json
  -> <resolved hub>/SKILLS_INDEX.md
  -> <resolved hub>/skills/<selected-skill>/SKILL.md
  -> required supporting resources
```

所有项目侧入口只允许 `discover -> route -> reference -> load`。router 本身只读；它不能借路由动作修改项目。加载后的 canonical Skill 是否可执行写操作，仍由用户请求、项目规则与该 Skill 的授权共同决定。

## 5. Authority Model

权威顺序冻结如下：

1. Superproject submodule gitlink：`Submodule` 模式实际 hub commit 权威。
2. 被固定 checkout 下的 `skills/`：Skill 正文权威。
3. `.gitmodules`：submodule path、name、URL 注册权威；不提供版本权威。
4. `.ai/runtime-pack.json`：路由 locator、生成记录与审计输入；不覆盖 gitlink。
5. 项目 adapters：发现和路由入口；不拥有 canonical 内容。
6. Submodule working directory HEAD：gitlink 的物化状态；必须等于 gitlink，但自身不是 superproject 版本权威。

任何层级不一致均 fail closed，不自动“修正”为另一个层级。

## 6. Hub Mode Contract — D-01

### 6.1 Frozen decision

```text
Default=Submodule
ExternalPath=Explicit_Opt_In_Only
Automatic_Fallback=NO
```

### 6.2 Submodule

- `HubPath` 必须是相对 project root 的规范化 POSIX 路径；默认 `.ai/ai-skill-hub`。
- 新 submodule name 固定为 `ai-skill-hub`。
- `.gitmodules` 的 path 和 URL 必须与计划完全一致。
- gitlink 必须存在于目标 commit/index，并固定 `resolved_commit`。
- working directory 可未初始化；initializer 可执行显式 materialization，但不得改变 gitlink 版本。
- 已有相同 path、相同规范化 URL、相同 gitlink commit 的合法 submodule 可以复用。
- 同 path 不同 URL、不同 gitlink、重复 path、重复 submodule section 或普通目录占位均阻塞。

### 6.3 ExternalPath

- 只能显式传 `-HubMode ExternalPath`。
- `-HubPath` 必须是已存在、位于 target project 之外的绝对普通目录，且是独立 Git worktree root。
- 禁止 symlink、junction、reparse point 或 target project 内的 nested Git repository。
- `-HubUrl` 在此模式下禁止传入；URL 从 external checkout 的 `origin` 读取并审计。
- external checkout HEAD 必须等于解析出的 `resolved_commit`，且 canonical index 必须存在；initializer 不 checkout、不 fetch、不修改 external repo。
- 该模式是本机/受控 CI opt-in，不具备 clone 后自动可用性；不得作为 Submodule 失败后的 fallback。
- manifest 会记录绝对、slash-normalized path，因此包含 ExternalPath 的 runtime pack 不可声称跨机器可移植。

### 6.4 `.gitmodules`, gitlink, worktree relationship

- `.gitmodules` 说明“从哪里、挂载到哪里”。
- gitlink 说明“固定哪个 commit”。
- working directory 说明“该 commit 是否已经 materialize”。
- 三者必须一致；JSON 不得替代其中任何一项。

## 7. Version Pinning Contract — D-02

### 7.1 Accepted `HubRef`

允许：

- short branch/tag name，例如 `main` 或 `v1.2.0`；
- fully qualified `refs/heads/<name>`；
- fully qualified `refs/tags/<name>`；
- 完整 40 位 hexadecimal commit ID。

禁止：abbreviated SHA、`HEAD`、remote-tracking expression、reflog expression、`~`/`^` revision expression 和空值。

默认 `HubRef=main`。

### 7.2 Deterministic resolution

首次初始化或收编一个没有 manifest 的既有 submodule 时：

1. fully qualified branch/tag 只查询对应 ref。
2. short name 同时查询 `refs/heads/<name>` 与 `refs/tags/<name>`；两者同时存在则 `BLOCKED_REF_AMBIGUOUS`。
3. annotated tag 使用 peeled `^{}` commit；lightweight tag 使用直接 commit。
4. 40 位 commit 通过隔离的临时 Git repo执行 fetch/cat-file 验证；不要求该 commit 是 ref tip。
5. 最终值必须是 lower-case 40 位 commit ID。

首次解析允许只读网络访问。`file://` URL 仅允许 local smoke/test profile，并必须输出 non-portable warning；不得作为跨机器生产配置。

### 7.3 Runtime and rerun behavior

- `requested_ref` 原样审计，`resolved_commit` 是确定版本。
- 成功生成 manifest 后，重复运行读取并使用已记录的 `resolved_commit`；即使 branch/tag 远端已前移，也不重新跟随。
- 运行时不自动 fetch 或 follow branch。
- initializer MVP 不承担升级；CLI 请求、现有 gitlink、manifest 或 external HEAD 指向不同 commit 时返回 `BLOCKED_UPGRADE_REQUIRED`。
- 未来升级必须由独立、显式 upgrade work item/tool 完成。

## 8. Adapter and Router Contract — D-03

### 8.1 Required artifacts

以下六项全部是 MVP 必选产物：

1. `AGENTS.md`
2. `CLAUDE.md`
3. `.github/copilot-instructions.md`
4. `.agents/skills/ai-skill-hub-router/SKILL.md`
5. `.claude/skills/ai-skill-hub-router/SKILL.md`
6. `.ai/runtime-pack.json`

### 8.2 Responsibilities

| Artifact | Responsibility |
| --- | --- |
| `AGENTS.md` | 跨工具共享入口；要求读取 runtime manifest 和 shared router |
| `CLAUDE.md` | Claude persistent entry；回指共享规则与 Claude router |
| Copilot instructions | Copilot 高频薄入口；回指 `AGENTS.md` 和 shared router |
| `.agents` router | Codex/Kimi/Copilot 的项目级原生 Skill 路由 |
| `.claude` router | Claude 的项目级原生 Skill 路由 |
| runtime manifest | 定位 hub/index、记录 commit、记录 generated ownership hashes |

### 8.3 Minimal router frontmatter

两个 router 使用相同的最小、跨工具交集 frontmatter；不加入 tool-specific keys：

```yaml
---
name: ai-skill-hub-router
description: "Locate and load the appropriate canonical ai-skill-hub Skill for this project. Use when a task may benefit from reusable hub guidance or explicitly names a hub Skill."
---
```

### 8.4 Selection algorithm

router 必须按以下顺序执行：

1. 从 project root 读取 `.ai/runtime-pack.json`；schema/字段/ownership 不合法即停止。
2. 解析 hub path；Submodule 模式验证 committed gitlink、manifest commit 和 materialized HEAD 一致；ExternalPath 模式验证 external HEAD。
3. 读取 manifest 指定的 canonical index；MVP 固定为 hub root 的 `SKILLS_INDEX.md`。
4. 用户明确命名 Skill 时，只接受 index 中 exact name。
5. 未明确命名时，使用 index 的 category、use scenario、name 和 per-skill overview 选择恰好一个清晰匹配项。
6. 无匹配返回 `ROUTER_NO_MATCH`；多个同等匹配返回 `ROUTER_AMBIGUOUS_MATCH`。不得猜测、拼接或创建路径。
7. 从 index 的 `Canonical path` 解析目标；路径必须规范化后位于 `<hub>/skills/<skill>/SKILL.md`，不得包含 escape。
8. 完整读取选中 `SKILL.md`，再按其中 routing instructions 读取必要 supporting resources。
9. 按用户授权、项目规则和 canonical Skill 执行；router 自身不产生项目 mutation。

### 8.5 Failure behavior

以下任一情况均停止路由并报告明确 code 和缺失路径：manifest 缺失/不兼容、submodule 未初始化、gitlink mismatch、index 缺失、Skill 不在 index、canonical path escape、`SKILL.md` 缺失、required supporting resource 缺失。

不得 fallback 到模型记忆、相似本地文件、hub adapter 或互联网副本。

## 9. Managed Block Contract — D-04

### 9.1 Markers

三个目标文件都是 Markdown，使用同一组 HTML comment marker：

```text
<!-- ai-skill-hub:runtime-pack:start schema=v1 -->
...
<!-- ai-skill-hub:runtime-pack:end -->
```

HTML comments 对 `AGENTS.md`、`CLAUDE.md` 和 `.github/copilot-instructions.md` 都是合法 Markdown；marker 本身只作为 ownership delimiter，不承载指令。无需替代 marker。

### 9.2 Create/adopt/refresh policy

```text
Default_Policy=ManagedBlock
Human_Content_Outside_Block=PRESERVE_BYTE_FOR_BYTE
Modified_Managed_Block=FAIL_CLOSED
Force_Overwrite=NO
Interactive_Merge=NO
```

- 文件不存在：创建仅含该 managed block 的文件。
- 文件存在且无 marker：
  - `ManagedBlock`：在 EOF 后追加一个 managed block；原 bytes 全部保留。
  - `Fail`：返回 `BLOCKED_EXISTING_FILE`。
- 文件存在且恰好一个结构合法 block：只有 manifest 记录的 SHA-256 与当前 block bytes 相同才视为 generator-owned；然后可按同一 generator/schema 刷新。
- block 存在但 manifest 缺失：`BLOCKED_UNKNOWN_MANAGED_BLOCK_PROVENANCE`。
- block hash 与 manifest 不同：`BLOCKED_MANAGED_CONTENT_MODIFIED`。
- start/end 重复、嵌套、孤立、逆序或 start schema 非 `v1`：`BLOCKED_MANAGED_BLOCK_INVALID`。
- block 外内容永不被 normalizer、trim 或换行转换触碰。
- 已存在合法、同版本 runtime pack 的 rerun 不受 `ExistingFilePolicy=Fail` 阻塞；该参数只控制首次 adoption。

### 9.3 Encoding/newline preservation

- 新文件与生成内容：UTF-8 without BOM、LF、末尾一个 LF。
- 既有入口文件只接受有效 UTF-8（with/without BOM）；BOM 状态保留。
- 既有文件若只有 CRLF，则插入 block 使用 CRLF；若只有 LF，则使用 LF；mixed newline 返回 `BLOCKED_TEXT_FORMAT_UNSUPPORTED`。
- block hash 针对 marker 在内、以 canonical LF 表示的逻辑 block计算，避免宿主 newline 差异改变 ownership；实际写入时再转换为宿主 newline。

### 9.4 Full-generated files

两个 router `SKILL.md` 是 full-generated files，不允许在文件内混入人工内容。若目标已存在：

- manifest 缺失：target conflict；
- manifest hash 不匹配：local modification；
- manifest hash匹配且 generator/schema 相同：可验证或幂等刷新。

## 10. `runtime-pack.json` Schema — D-05

### 10.1 Complete V1 shape

```json
{
  "schema_version": 1,
  "generator": {
    "id": "ai-skill-hub.project-runtime-pack",
    "version": 1
  },
  "hub": {
    "mode": "submodule",
    "path": ".ai/ai-skill-hub",
    "url": "gitea-nas:yuhanbravo/ai-skill-hub.git",
    "requested_ref": "main",
    "resolved_commit": "0123456789abcdef0123456789abcdef01234567"
  },
  "routing": {
    "strategy": "thin-router",
    "canonical_index": ".ai/ai-skill-hub/SKILLS_INDEX.md"
  },
  "adapters": [
    {
      "id": "agents-entry",
      "path": "AGENTS.md",
      "management": "managed-block",
      "content_sha256": "<64-lower-hex>"
    },
    {
      "id": "claude-entry",
      "path": "CLAUDE.md",
      "management": "managed-block",
      "content_sha256": "<64-lower-hex>"
    },
    {
      "id": "claude-router",
      "path": ".claude/skills/ai-skill-hub-router/SKILL.md",
      "management": "generated-file",
      "content_sha256": "<64-lower-hex>"
    },
    {
      "id": "copilot-entry",
      "path": ".github/copilot-instructions.md",
      "management": "managed-block",
      "content_sha256": "<64-lower-hex>"
    },
    {
      "id": "shared-router",
      "path": ".agents/skills/ai-skill-hub-router/SKILL.md",
      "management": "generated-file",
      "content_sha256": "<64-lower-hex>"
    }
  ]
}
```

### 10.2 Required fields and validation

- 上例所有字段均 required。
- 所有 object 均 `additionalProperties=false`；unknown fields 返回 `BLOCKED_MANIFEST_UNKNOWN_FIELD`。
- `schema_version` 与 generator version 只接受 integer `1`；其他值返回 incompatible schema/generator，不尝试迁移。
- `hub.mode` 只接受 lower-case `submodule|external-path`。
- `hub.resolved_commit` 是 40 位 lower-case hex。
- adapter ids 唯一，五项集合必须精确相等，并按 `id` ordinal ascending 排序。
- adapter path 必须使用 `/`、相对 project root、不得以 `/` 开头、不得含 `.`/`..` segment。
- `content_sha256` 是 managed block 的 canonical logical bytes 或 generated file full bytes 的 SHA-256 lower hex。

### 10.3 Paths

- Submodule：`hub.path` 和 `routing.canonical_index` 均为 project-relative POSIX path；index 必须等于 `<hub.path>/SKILLS_INDEX.md`。
- ExternalPath：`hub.path` 和 `canonical_index` 均为 absolute slash-normalized Windows path，例如 `D:/shared/ai-skill-hub`；index 必须等于 `<hub.path>/SKILLS_INDEX.md`。
- JSON 不使用反斜杠保存路径。

### 10.4 URL normalization

- trim leading/trailing whitespace；拒绝 control characters。
- 接受 `https://`、`ssh://`、`git://`、`file://` 和 SCP-like `[user@]host:path`。
- 去掉 URL 末尾多余 `/`，但不增删 `.git`、不改写 protocol、不解析 SSH host alias。
- URL 比较使用规范化后的 ordinal string equality；不把不同写法猜作相同 remote。
- 相对 submodule URL 在 MVP 禁止。
- 当前 hub 默认 URL 从 initializer 所在 hub repository 的 `origin` 读取；本基线解析为 `gitea-nas:yuhanbravo/ai-skill-hub.git`。SSH alias/credential 可用性属于调用环境责任。

### 10.5 Encoding and authority

- UTF-8 without BOM，两个空格缩进，LF，末尾一个 LF。
- key 顺序固定为示例顺序；adapter array 固定按 id 排序。
- JSON 是首次生成输出、rerun ownership/validation 输入和 router locator。
- JSON 不是 hub commit 或 Skill content SSOT。
- JSON 与 gitlink、`.gitmodules`、external HEAD 或实际 file hash 不一致时 fail closed；不得自动以 JSON 覆盖实际状态。

## 11. Initializer CLI Contract — D-06

目标脚本：`tools/init_project_runtime_pack.ps1`

```powershell
tools/init_project_runtime_pack.ps1 `
  -ProjectPath <path> `
  [-HubMode Submodule|ExternalPath] `
  [-HubUrl <url>] `
  [-HubRef <branch|tag|40-char-commit>] `
  [-HubPath <path>] `
  [-ExistingFilePolicy ManagedBlock|Fail] `
  [-DryRun]
```

| Parameter | Required/default | Contract |
| --- | --- | --- |
| `ProjectPath` | required | 相对值基于 caller current directory；规范化后必须等于 `git rev-parse --show-toplevel` |
| `HubMode` | default `Submodule` | 无自动 fallback |
| `HubUrl` | Submodule optional | 默认从 source hub `origin` 读取；ExternalPath 禁止 |
| `HubRef` | default `main` | 语法与解析按第 7 节 |
| `HubPath` | Submodule default `.ai/ai-skill-hub` | Submodule 时 project-relative；ExternalPath 时 required absolute existing path |
| `ExistingFilePolicy` | default `ManagedBlock` | 仅控制首次 adoption |
| `DryRun` | switch | 零 repository worktree/index/admin mutation |

明确不支持：`-Force`、全局配置修改、用户级 Skill 修改、symlink/junction、Skill 镜像、非 Git project、自动 upgrade、自动 commit/push/PR。

## 12. Git and Working Tree Preconditions

### 12.1 Repository root and operations

- target 必须是 Git working tree 的 top-level；bare repo、子目录、worktree 外路径和非 Git目录阻塞。
- merge、rebase、cherry-pick、revert、bisect、sequencer 或现有 index lock 任一存在即阻塞。
- Git safe.directory 报错直接返回 `BLOCKED_GIT_SAFE_DIRECTORY`；脚本不修改 local/global/system Git config。

### 12.2 Dirty/staged policy

首次初始化要求 tracked、untracked、staged 全部为空。

成功初始化后未 commit 的立即 rerun 是唯一例外：仅当所有变化都精确属于同一 valid manifest 的完整、已 staged initializer change set，且无 unstaged/额外文件时，允许返回 no-change。任何额外 dirty/staged/untracked 项均阻塞。

这同时冻结：

- dirty working tree 默认不允许；
- staged changes 默认不允许；
- initializer 不吸收、不重排用户现有 staging。

### 12.3 Existing paths

- 合法、clean、同 URL/commit 的 committed submodule 可以复用。
- 未初始化但合法的同 commit submodule可以 materialize。
- 不同 URL/commit submodule阻塞。
- HubPath 被普通 file、普通 directory、unregistered nested repo 或 reparse point 占用时阻塞。
- 除已注册目标 submodule 外，不允许把 nested Git repo 当成 Submodule 模式输入。

## 13. Transaction and Rollback Contract — D-07

### 13.1 Phases

```text
Preflight
Plan
SubmoduleMutationOrExternalValidation
AdapterGeneration
ManifestGeneration
Validation
CommitReady
FinalVerification
```

### 13.2 Mutation map

| Phase | Worktree/admin mutation | Index mutation |
| --- | --- | --- |
| Preflight | none | none |
| Plan | none；允许 OS temp 和只读 network | none |
| SubmoduleMutation | `.gitmodules`、submodule worktree、specific `.git/config` section、specific `.git/modules/...` | 只写 alternate transaction index |
| AdapterGeneration | 原子替换/创建入口与 router | none |
| ManifestGeneration | manifest 最后生成到 worktree | none |
| Validation | none | none |
| CommitReady | none | `git add` 只写 alternate index；随后原子提交 real index |
| FinalVerification | none | none |

### 13.3 Alternate-index protocol

1. Preflight 记录 real index bytes/hash 和所有目标 path 的 stage entries。
2. 复制 real index到 transaction temp；所有 mutating Git commands 设置 `GIT_INDEX_FILE` 指向该 alternate index。
3. `.gitmodules`、gitlink、五个 adapter 与 manifest全部加入 alternate index。
4. Validation 检查 alternate staged diff 的 path set 精确等于计划，不含其他项。
5. CommitReady 前重新确认 real index hash 未变化。
6. 使用 Git index lock protocol 把 alternate index bytes flush 到 `.git/index.lock`，关闭后原子 rename 为 real `.git/index`。
7. 不使用 `git reset --hard`、`git checkout --` 或 broad clean。

### 13.4 File atomicity and backup

- transaction journal 位于 target git dir 下的唯一 scoped 目录；记录 pre-state、created paths、submodule name 和 hashes。
- 每个会改动的既有人工文件先做 byte-for-byte backup。
- 新内容先写同 volume temp file，flush，验证 hash，再 `File.Replace`（既有）或 atomic move（新建）。
- manifest 在其他 adapter 都已写入并验证后才写。
- 成功后才删除 backups/journal。

### 13.5 Rollback order

失败后必须按确定顺序：

1. 停止后续 phase并保留 original error。
2. 若 real index 已 swap，使用预先保存 bytes和 index lock protocol原子恢复，并验证 hash；若未 swap，只删除 alternate index。
3. 按 journal byte-for-byte 恢复既有入口文件；删除仅由本事务创建的 adapters/manifest。
4. 恢复 `.gitmodules` 原 bytes或缺失状态。
5. 只在 journal 证明目标在事务前不存在时，清理本事务创建的 HubPath、对应 `.git/modules/<name>` 和 `.git/config` submodule section；每个绝对路径必须再次验证位于预期 project/git-dir scope。
6. 验证 worktree status、index hash、人工文件 hash和 pre-state 完全相同。
7. rollback 成功：删除 journal，返回 exit `3` 和 `FAILED_APPLY_ROLLED_BACK`。
8. rollback 任一步无法验证：停止清理、保留 scoped evidence，返回 exit `4` 和 `BLOCKED_ROLLBACK_FAILURE`，同时输出 journal 的绝对路径。

“尽量回滚”不是合格实现；所有 failure-injection tests 必须证明上述 post-state。

### 13.6 DryRun

`DryRun` 可解析 remote ref并使用 OS temp，但不得：

- 创建/修改 target worktree 文件；
- 创建/修改 target git-dir transaction、module、config 或 lock；
- 修改 index；
- 执行 `git submodule add/update`；
- 写入 manifest 或 adapter。

测试必须比较执行前后 worktree snapshot、real index bytes/hash、`.git/config`、`.git/modules` 和 `git status --porcelain=v2` 完全相同。

## 14. Idempotency Contract

幂等定义：同一 target、同一 valid manifest、同一 stored resolved commit、同一 generator/schema、同一 adapters 和实际 authority 状态下再次运行：

- `Decision=NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT`；
- exit code `0`；
- 不访问远端解析已固定 branch/tag；
- worktree、index、`.git/config`、`.git/modules` 和 file mtimes 均不变；
- 不重写 JSON、managed block 或 router；
- 不产生临时 transaction artifact。

branch/tag 远端前移不改变幂等结果；升级必须另行执行。

## 15. DryRun Contract

`DryRun` stdout 固定输出以下 key（顺序固定），diagnostics 写 stderr：

```text
Decision=PASS_PROJECT_RUNTIME_PACK_DRY_RUN
Project_Root=<absolute-path>
Hub_Mode=<Submodule|ExternalPath>
Hub_Path=<normalized-path>
Hub_Url=<normalized-url>
Requested_Ref=<ref>
Resolved_Commit=<40-hex>
Planned_Actions=<semicolon-separated ordered actions>
Changed_Count=<integer>
Index_Change=NO
Working_Tree_Change=NO
Rollback_Status=NOT_REQUIRED
Manifest_Status=<ABSENT|VALID>
Message=DryRun completed with zero repository mutation.
```

DryRun 遇到 preflight conflict 仍返回对应 blocking decision和 exit `2`，不得用计划输出掩盖冲突。

## 16. Error and Result Taxonomy

### 16.1 Exit codes

| Exit | Meaning |
| --- | --- |
| `0` | initialized, no-change, or valid DryRun |
| `2` | fail-closed preflight/validation/config conflict；无 mutation或无需 rollback |
| `3` | apply failed；rollback 已完整验证 |
| `4` | rollback 无法完整验证；evidence retained |

### 16.2 Success decisions

- `PASS_PROJECT_RUNTIME_PACK_INITIALIZED`
- `NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT`
- `PASS_PROJECT_RUNTIME_PACK_DRY_RUN`

### 16.3 Blocking families

- Git：`BLOCKED_NOT_GIT_REPOSITORY`、`BLOCKED_PROJECT_NOT_ROOT`、`BLOCKED_GIT_OPERATION_ACTIVE`、`BLOCKED_DIRTY_WORKTREE`、`BLOCKED_STAGED_CHANGES`、`BLOCKED_GIT_SAFE_DIRECTORY`。
- Path/submodule：`BLOCKED_PATH_SAFETY_VIOLATION`、`BLOCKED_HUB_PATH_CONFLICT`、`BLOCKED_SUBMODULE_CONFLICT`、`BLOCKED_EXTERNAL_PATH_INVALID`。
- Ref/network：`BLOCKED_REF_INVALID`、`BLOCKED_REF_NOT_FOUND`、`BLOCKED_REF_AMBIGUOUS`、`BLOCKED_CREDENTIAL_OR_TRANSPORT`。
- Managed files：`BLOCKED_EXISTING_FILE`、`BLOCKED_MANAGED_BLOCK_INVALID`、`BLOCKED_UNKNOWN_MANAGED_BLOCK_PROVENANCE`、`BLOCKED_MANAGED_CONTENT_MODIFIED`、`BLOCKED_TEXT_FORMAT_UNSUPPORTED`。
- Manifest/runtime：`BLOCKED_MANIFEST_INVALID`、`BLOCKED_MANIFEST_UNKNOWN_FIELD`、`BLOCKED_SCHEMA_INCOMPATIBLE`、`BLOCKED_RUNTIME_PACK_MISMATCH`、`BLOCKED_UPGRADE_REQUIRED`、`BLOCKED_CANONICAL_INDEX_MISSING`。
- Transaction：`FAILED_APPLY_ROLLED_BACK`、`BLOCKED_ROLLBACK_FAILURE`、`BLOCKED_CONCURRENT_STATE_CHANGE`、`BLOCKED_UNEXPECTED_ERROR`。

非零结果仍必须输出与 DryRun 相同的 common fields，并用 `Message` 给出不含凭证/secret 的最短解释。

## 17. Security and Path Boundaries

- 只调用通过 `Get-Command git.exe` 解析的 Git；参数以 array传递，不拼 shell command string。
- 所有 destructive cleanup 只针对 journal 中“事务前不存在、由本事务创建”的已重新解析绝对路径。
- project root、drive root、git dir root、用户 home 和任意未验证 ancestor 不得作为 recursive delete target。
- 拒绝 wildcard、NUL/control、`.`/`..` segment、alternate data stream 和 Windows reserved device names。
- Submodule HubPath 不得等于 project root、`.git` 或位于 git dir 内。
- Existing path ancestors 必须不是 reparse point。
- router 对 index path和 Skill path做 containment validation，防止 canonical index 注入 path escape。
- initializer 不读取、打印或保存 credential；Git credential helper、SSH agent、host key和 private-submodule token由调用环境负责。
- `safe.directory` 不在脚本职责内；只报告修复责任，不自动运行 `git config`。

## 18. Validation Matrix — D-09

`Blocking` 表示 Round 2 实现验收或 MVP release gate 是否必须通过。

| # | Scenario | Type | Blocking | Expected result |
| ---: | --- | --- | --- | --- |
| 1 | 空白 clean Git repo 首次初始化 | Automated integration | Yes | 全部产物和 staged set精确，gitlink固定 |
| 2 | 重复执行 | Automated integration | Yes | no-change，零 bytes/mtime/index变化 |
| 3 | DryRun | Automated integration | Yes | 完整计划，repo/admin/index零变化 |
| 4 | 已有人工入口文件 | Automated integration | Yes | block 外 bytes保留，block追加 |
| 5 | managed block 人工修改 | Automated integration | Yes | `BLOCKED_MANAGED_CONTENT_MODIFIED` |
| 6 | marker 重复/缺失/逆序/嵌套 | Automated parameterized | Yes | `BLOCKED_MANAGED_BLOCK_INVALID` |
| 7 | 非 Git目录 | Automated | Yes | `BLOCKED_NOT_GIT_REPOSITORY` |
| 8 | repo 子目录作为 ProjectPath | Automated | Yes | `BLOCKED_PROJECT_NOT_ROOT` |
| 9 | dirty working tree | Automated | Yes | `BLOCKED_DIRTY_WORKTREE` |
| 10 | staged changes | Automated | Yes | `BLOCKED_STAGED_CHANGES` |
| 11 | HubPath 被普通 file/dir 占用 | Automated parameterized | Yes | `BLOCKED_HUB_PATH_CONFLICT` |
| 12 | 已有合法相同 submodule | Automated integration | Yes | 复用，不改 gitlink |
| 13 | 已有不同 URL submodule | Automated integration | Yes | `BLOCKED_SUBMODULE_CONFLICT` |
| 14 | HubRef 无法解析/歧义 | Automated with local remote | Yes | ref-specific blocking decision |
| 15 | submodule 后 adapter 生成失败 | Automated failure injection | Yes | rollback恢复 exact pre-state |
| 16 | clone 后 submodule 未初始化 | Automated integration + Local smoke | Yes | initializer可materialize；router在此前 fail closed |
| 17 | JSON 与 gitlink 不一致 | Automated | Yes | `BLOCKED_RUNTIME_PACK_MISMATCH` |
| 18 | 路径包含空格和中文 | Automated integration | Yes | 成功且路径/JSON正确 |
| 19 | canonical index 缺失 | Automated | Yes | `BLOCKED_CANONICAL_INDEX_MISSING`，零残留 |
| 20 | router 指向不存在 Skill | Automated router fixture | Yes | `ROUTER_SKILL_NOT_FOUND` |
| 21 | Codex 原生发现 `.agents` router 并路由一个 Skill | External Tool E2E | Yes | router可见、选择、读取 canonical Skill |
| 22 | Kimi 原生发现 `.agents` router 并路由一个 Skill | External Tool E2E | Yes | router可见、选择、读取 canonical Skill |
| 23 | GitHub Copilot instructions + `.agents` router | External Tool E2E | No | 记录版本/host/入口证据；不可用时保留官方文档证据 |
| 24 | Claude Code `CLAUDE.md` + `.claude` router | External Tool E2E | No | 记录版本/host/入口证据；不可用时保留官方文档证据 |

补充 blocking automated cases：unknown JSON field、schema mismatch、ExternalPath outside/inside boundary、reparse point、safe.directory error classification、concurrent index change、rollback failure evidence retention、existing valid staged complete pack rerun。

## 19. Known Limitations

- 仅 Windows + PowerShell。
- ExternalPath 不可移植。
- SCP-like origin 依赖调用机 SSH host alias；initializer 不改写它。
- 不保证每个 canonical Skill 都作为每个工具的原生命令显示。
- 语义选择仍由模型基于 index 完成；ambiguous 时 fail closed，不提供 deterministic classifier。
- GitHub Copilot/Claude external E2E 非 Round 2 blocking，但必须在更广 release claim 前补齐。
- Windows long-path 能力取决于 OS、Git 和 filesystem配置；MVP 只保证常规路径与包含空格/中文的路径。

## 20. Support Environment — D-08 and Upgrade Path

### 20.1 Supported environment

```text
Operating_System=Windows 10/11
PowerShell_Minimum=7.4.0
Git_Minimum=2.40.0
Target=non-bare Git working tree root
Cross_Platform=NOT_IN_MVP
```

- 直接调用 `git.exe`。
- generated text/JSON 使用 UTF-8 no BOM + LF；existing human text按第 9 节保留。
- 路径处理使用 .NET path API；Git/PowerShell参数逐项传递，必须支持空格和中文。
- CI credential、private submodule authorization、SSH host key、proxy 和 `safe.directory` 均由运行环境负责。

### 20.2 Upgrade path

未来升级必须是独立 contract/work item，至少负责：显式新 ref解析、gitlink更新、manifest resolved commit更新、可能的 template/schema migration、完整 rollback 和新的 E2E。MVP initializer 对任何版本变化只报告 `BLOCKED_UPGRADE_REQUIRED`。

## 21. Frozen Decisions

- D-01：默认 Submodule；ExternalPath仅显式本机 opt-in；无自动 fallback。
- D-02：branch/tag/40-char commit解析为 exact commit；gitlink是运行时版本权威；不自动 follow，不在 initializer升级。
- D-03：六项产物全部 required；两个 router 使用最小 `name+description` frontmatter；router只读并 fail closed。
- D-04：ManagedBlock默认；外部人工内容 byte-preserved；hash识别 managed modification；无 Force/interactive merge。
- D-05：schema v1 exact-field、exact-order、UTF-8 no BOM/LF；JSON是 locator/audit record，不覆盖 gitlink/skills。Adapter `content_sha256` 使用 SHA-256；新 manifest 必须声明 `hash_algorithm: sha256` 与 `hash_normalization: utf8-lf-v1`，即 UTF-8 文本的 CRLF/CR 规范化为 LF 后计算。旧 manifest 缺少这两个字段时按历史 raw-hash 契约读取；仅当冻结的 LF 逻辑内容仍完全匹配时，initializer 才能生成可审计的新 manifest，字符内容差异仍 fail closed。
- D-06：七个参数及默认值冻结；仅 Git root；首次 clean；只允许完整 managed staged rerun例外。
- D-07：alternate index + byte backups + atomic file operations + exact rollback verification；DryRun零 repo mutation。
- D-08：Windows 10/11、PowerShell 7.4+、Git 2.40+；safe.directory/credentials由环境负责。
- D-09：20项 automated/local blocking场景；Codex/Kimi external E2E blocking；Copilot/Claude external E2E non-blocking但需要后续证据。

## 22. Open Issues

无实现阻塞型 open issue。

非阻塞 follow-up：

1. 维护者可在未来决定是否提供不依赖 `gitea-nas` SSH alias 的公开/企业 canonical URL；MVP 已冻结默认从 source `origin`读取且允许显式 `-HubUrl`。
2. GitHub Copilot 与 Claude Code 的真实 authenticated host E2E 可在 Round 3 补齐。
3. Cross-platform、upgrade tool、relative submodule URL 和更强 deterministic routing属于未来独立 work item。

## Appendix A. Managed Block Payload Requirements

三个 block 的正文必须短、只做定位，不复制本设计或 canonical Skill正文。

### A.1 `AGENTS.md`

```md
<!-- ai-skill-hub:runtime-pack:start schema=v1 -->
## AI Skill Hub Runtime Pack

- Runtime manifest: `.ai/runtime-pack.json`
- Shared router: `.agents/skills/ai-skill-hub-router/SKILL.md`
- Read the router before selecting hub guidance; the router locates canonical Skills through the manifest and canonical index.
- Keep this entry thin. Do not copy canonical Skill bodies into this project.
- If the manifest, hub commit, index, router, or selected Skill is missing or inconsistent, stop and report the mismatch.
<!-- ai-skill-hub:runtime-pack:end -->
```

### A.2 `CLAUDE.md`

```md
<!-- ai-skill-hub:runtime-pack:start schema=v1 -->
## AI Skill Hub Runtime Pack

- Follow `AGENTS.md` for shared project entry guidance.
- Runtime manifest: `.ai/runtime-pack.json`
- Claude router: `.claude/skills/ai-skill-hub-router/SKILL.md`
- Read the router before selecting hub guidance. Do not copy canonical Skill bodies into this file.
- If the manifest, hub commit, index, router, or selected Skill is missing or inconsistent, stop and report the mismatch.
<!-- ai-skill-hub:runtime-pack:end -->
```

### A.3 `.github/copilot-instructions.md`

```md
<!-- ai-skill-hub:runtime-pack:start schema=v1 -->
## AI Skill Hub Runtime Pack

- Follow `AGENTS.md` first for shared project guidance.
- Runtime manifest: `.ai/runtime-pack.json`
- Shared router: `.agents/skills/ai-skill-hub-router/SKILL.md`
- Use the router to locate canonical Skills; do not duplicate their bodies in Copilot instructions.
- If the manifest, hub commit, index, router, or selected Skill is missing or inconsistent, stop and report the mismatch.
<!-- ai-skill-hub:runtime-pack:end -->
```

## Appendix B. Exact Router `SKILL.md` Template

两个 router 文件必须使用以下完整内容；除 newline serialization 外不得改写。`../../../.ai/runtime-pack.json` 从两个 router 目录都解析到 project root。

```md
---
name: ai-skill-hub-router
description: "Locate and load the appropriate canonical ai-skill-hub Skill for this project. Use when a task may benefit from reusable hub guidance or explicitly names a hub Skill."
---

# AI Skill Hub Router

This router is read-only. It may discover, route, reference, and load guidance, but it must not modify the project, initialize a submodule, fetch, or update the hub.

## Route

1. Locate the Git project root and read `../../../.ai/runtime-pack.json` relative to this Skill directory.
2. Require schema version `1`, generator `ai-skill-hub.project-runtime-pack` version `1`, the exact five adapter records, and this router's matching generated-file hash. On failure, stop with `ROUTER_MANIFEST_INVALID`.
3. Resolve `hub.path` and `routing.canonical_index` exactly as recorded. Reject path escape, unknown mode, or an index outside the resolved hub.
4. For `submodule`, require the committed superproject gitlink to equal `hub.resolved_commit`, and require the materialized hub HEAD to equal that same commit. If the checkout is absent, stop with `ROUTER_HUB_NOT_MATERIALIZED`; if versions differ, stop with `ROUTER_HUB_VERSION_MISMATCH`.
5. For `external-path`, require the external Git worktree HEAD to equal `hub.resolved_commit`; otherwise stop with `ROUTER_HUB_VERSION_MISMATCH`.
6. Read the canonical `SKILLS_INDEX.md`. If it is missing, stop with `ROUTER_INDEX_MISSING`.
7. If the user explicitly names a Skill, require an exact indexed name. Otherwise use the index category, use scenario, name, and per-Skill overview, and select only when exactly one Skill is a clear match. Use `ROUTER_NO_MATCH` for none and `ROUTER_AMBIGUOUS_MATCH` for a tie.
8. Resolve the indexed canonical path and require it to stay under `<hub>/skills/<skill-name>/SKILL.md`. On path escape or malformed index data, stop with `ROUTER_CANONICAL_PATH_INVALID`.
9. Read the selected `SKILL.md` completely. If it is absent, stop with `ROUTER_SKILL_NOT_FOUND`. Read every supporting resource that the selected Skill requires; if one is absent, stop with `ROUTER_SUPPORTING_RESOURCE_MISSING`.
10. Follow the selected canonical Skill together with the user's authorization and project rules. The router itself grants no write or external-operation authority.

Do not fall back to model memory, copied Skill text, a hub adapter, or an internet copy when any validation fails.
```

## Appendix C. Initializer Result Fields

所有结果按以下固定顺序输出：

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
