# Codex 用户级 Skills Bootstrap V1（Windows）

本文说明如何在 Windows 上检查、规划和受控管理 Codex 用户级 V1 skill bundle。工具只使用本地 `ai-skill-hub` Git checkout，离线可运行；它不是插件安装器、网络安装器或项目迁移工具。

## 四个 control plane

必须区分以下四层，不能互相替代：

| 层 | 典型路径 | 职责 |
| --- | --- | --- |
| Hub canonical source | `<ai-skill-hub>\skills\<skill>` | 唯一 canonical skill 内容 |
| Project runtime copy | `<consumer-project>\.codex\skills\<skill>` | 业务项目自己的运行时副本 |
| Codex user installation | `$CODEX_HOME\skills\<skill>` | 当前用户可发现的受控复制候选 |
| Codex system skills | `$CODEX_HOME\skills\.system\**` | Codex 系统管理区域，工具永久排除 |

用户级安装不会自动满足项目 `AGENTS.md` 或其他规则中写死的相对路径，例如 `<consumer-project>\.codex\skills\...`。这类项目引用仍需独立评估，不能因为用户目录已有副本就宣称项目已迁移。

## V1 管理范围

V1 是冻结 bundle，只整体安装或整体卸载：

- `workflow-bootstrap`：复制完整 canonical 目录树；
- `chatgpt-handoff-pilot`：复制完整 canonical 目录树；
- `_protocol/skill_assessment_output.md`：只复制 descriptor 明确声明的共享依赖文件。

静态 source descriptor 是：

```text
tools\codex_user_skills_manifest.json
```

它声明允许管理的 source/target、对象角色和 dependency relationship，不记录机器路径或实际安装状态，也不是新的 canonical source。

## 前提

- Windows PowerShell 5.1 或 PowerShell 7.x；
- 本地、完整、干净的 `ai-skill-hub` Git checkout；
- descriptor 与所有 managed source 文件已被当前 `HEAD` 跟踪且相对该提交无修改、无未跟踪 payload；
- 真实写入前已获得独立授权。

工具不需要网络、Gitea、GitHub、插件或业务仓库。

## CODEX_HOME 解析

解析顺序：

1. 进程环境中存在非空 `CODEX_HOME` 时使用它；
2. 否则使用当前用户 profile 下的 `.codex`；
3. 在其后追加 `skills` 得到 target root。

V1 会拒绝：

- 空白、相对、UNC、drive root 或包含 wildcard 的 `CODEX_HOME`；
- 文件、symlink、junction、reparse-point root；
- 与 repository 或 canonical `skills` 重叠的路径；
- 逃逸 target root 或进入 `.system` 的 managed path。

尾部分隔符会被规范化。所有 Windows 路径比较使用 absolute、normalized、case-insensitive 和 LiteralPath 语义。

## 新机器初始化

先取得一个本地 checkout，并确认 Git 状态：

```powershell
Set-Location 'D:\dev\ai-skill-hub'
git rev-parse --show-toplevel
git rev-parse HEAD
git status --short
```

然后只读检查：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File tools\manage_codex_user_skills.ps1 `
  -Action Check
```

无参数调用与 `-Action Check` 等价，不能创建 `CODEX_HOME`、`skills`、lock、manifest、临时文件或日志。

## Check 与 Plan

`Check` 检查 source commit、descriptor、dependency closure、target path、ownership、fingerprints、冲突、`.system` 保护和当前状态：

```powershell
.\tools\manage_codex_user_skills.ps1 -Action Check
```

`Plan` 运行同等完整的只读 preflight，并列出 Apply 的有序动作：

```powershell
.\tools\manage_codex_user_skills.ps1 -Action Plan
```

需要机器可读输出时：

```powershell
.\tools\manage_codex_user_skills.ps1 -Action Plan -OutputFormat Json
```

JSON stdout 是单一文档，数组保持数组，`Decision` 与 text mode 使用相同拼写。输出会以 `$CODEX_HOME` 表示用户 target，避免在普通控制台输出中扩散用户 profile 路径。

## Apply

`Apply` 是显式写操作：

```powershell
.\tools\manage_codex_user_skills.ps1 -Action Apply
```

事务顺序包括：

```text
read-only preflight
→ 创建事务所需且原本缺失的普通目录
→ 获取 exclusive manager lock
→ post-lock 重验 manifest、对象类型与 fingerprints
→ 在 target root 同卷 staging
→ 校验 staged fingerprints
→ 在 target root 同卷 backup 与 transaction journal
→ 只替换需要变化的 owned entries
→ 重算 installed fingerprints
→ 最后原子写入 ownership manifest
→ final verification
→ 清理 transaction artifacts 并释放 lock
```

完全相同的第二次 Apply 返回 no-change，且不获取 lock、不做 writability probe、不创建 transaction artifact。升级只替换 source fingerprint 已变化、且 target 仍等于原 installed fingerprint 的 owned entry。

## ownership manifest

动态 ownership manifest 位于：

```text
$CODEX_HOME\skills\.ai-skill-hub-user-skills.json
```

它记录 manager、source commit、target root、时间戳、完整 V1 managed-entry coverage、source fingerprint 与 installed fingerprint。它是本机 ownership metadata，不是 canonical source，也不会被递归当作 skill payload fingerprint。

以下情况会阻断，不会自动修复、adopt 或覆盖：

- manifest 缺失但 managed name 已存在；
- JSON 损坏、schema/manager/target 不匹配；
- required entry 缺失、出现额外或重复 entry；
- descriptor dependency closure 不完整；
- locally modified owned copy；
- unknown file/directory、junction、symlink、broken link 或 reparse point；
- concurrent lock 或 stale transaction artifact；
- post-lock state change。

## 冲突与本地修改

工具没有 `-Force` 或 `-Adopt`。如果目标内容来源未知，先人工确认 provenance；如果 owned copy 被本地修改，先把需要保留的内容回收到 canonical hub 或另行备份，再恢复到可验证状态。不要手工裁剪 manifest 来做部分卸载。

`_protocol` 是一个整体 owned 的 filtered directory。多出任何未声明文件都会改变 fingerprint 并阻断更新或卸载，工具不会删除该未知文件。

## Uninstall

整体卸载：

```powershell
.\tools\manage_codex_user_skills.ps1 -Action Uninstall
```

Uninstall 必须先验证完整 manifest coverage、target root 和每个 installed fingerprint；获取 lock 后再次验证。它只把 manifest 管理且未修改的三个 entry 移入同卷 backup，再最后移除 manifest。成功验证 `.system` 与 unrelated top-level entries 未改变后才删除 backup。重复 Uninstall 返回 not-installed no-change。

V1 不支持单技能卸载，也不从 matching content 推断 ownership。

## 回滚与恢复证据

Apply/Uninstall 在 mutation 开始后失败时，会停止前进，只按当前 transaction journal 删除新对象或恢复 backup，并验证恢复后的 fingerprints 与 manifest bytes。

- 回滚成功：返回非零 Decision，并报告 `Rollback_Status=RESTORED`；
- 回滚无法验证：返回 `BLOCKED_ROLLBACK_FAILURE`、exit `3`，保留位于 `$CODEX_HOME\skills` 下的 manager-prefixed backup/transaction evidence，供人工恢复；
- lock 会在 `finally` 中释放；
- 不会写入“成功”的半安装 manifest。

不要自行清理 recovery evidence，除非完成独立人工检查。

## `.system` 保护

`.system` 永远不属于 descriptor、manifest、staging、backup、替换、卸载或 stale cleanup。工具不会把 `.system` 当作冲突，也不会进入它做 ownership 或清理。本仓库隔离测试会在成功和失败路径前后独立 fingerprint `.system` sentinel，证明其未改变。

## 临时隔离验证

本轮实现和本地测试不得写真实用户目录。手工验证示例：

```powershell
$testRoot = Join-Path $env:TEMP ('codex-user-skills-test-' + [guid]::NewGuid().ToString('N'))
$testCodexHome = Join-Path $testRoot 'codex home'
$previousCodexHome = $env:CODEX_HOME

try {
    $env:CODEX_HOME = $testCodexHome
    .\tools\manage_codex_user_skills.ps1 -Action Check
    .\tools\manage_codex_user_skills.ps1 -Action Plan
    .\tools\manage_codex_user_skills.ps1 -Action Apply
    .\tools\manage_codex_user_skills.ps1 -Action Apply
    .\tools\manage_codex_user_skills.ps1 -Action Uninstall
}
finally {
    $env:CODEX_HOME = $previousCodexHome
}
```

自动化 suite 会为每个场景建立 temporary repository fixture、temporary HOME 和 temporary `CODEX_HOME`，并对子进程显式注入环境。测试不会调用 `sync_skills_to_nongit_project.ps1`，不会依赖真实用户目录内容，也不会修改任何业务仓库。

## 旧项目同步工具的边界

禁止将以下路径传给 `tools\sync_skills_to_nongit_project.ps1`：

```text
$HOME
$CODEX_HOME
$CODEX_HOME\skills
```

该旧工具面向 consumer project 的 `.codex\skills`，包含镜像和 stale-cleanup 语义；用户级安装必须使用本页的 ownership-aware manager。

## 重启与外部 E2E

changed Apply 或 changed Uninstall 会输出 `Restart_Required=YES`。这表示可能需要重启 Codex App 或开启新 session，具体行为必须在真实安装获得独立授权后验证。

仓库测试和文件复制不能证明：

- Codex App 已发现两个用户级 skills；
- Codex CLI 已发现两个用户级 skills；
- 新 session 已读取安装；
- App 是否必须重启；
- 两个 skills 在真实 host 中能读取 shared `_protocol`；
- 项目相对 `.codex\skills` 引用已迁移。

这些都是 merge、release/availability decision 与单独真实用户安装授权之后的 host-level external E2E，不属于本轮实施结论。
