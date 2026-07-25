# Task Package: Codex User Skills Bootstrap V1

## 1. Task Identity and Frozen Decision

| Field | Value |
| --- | --- |
| Task_ID | `CODEX_USER_SKILLS_BOOTSTRAP_V1` |
| Repository | `ai-skill-hub` |
| Package_Type | `IMPLEMENTATION_TASK_PACKAGE` |
| Risk_Level | `FILESYSTEM_WRITE_WITH_FAIL_CLOSED_OWNERSHIP` |
| Implementation_Type | `ADD_NEW_INSTALL_TOOL` |
| Package_Date | `2026-07-25` |
| Canonical_Source | `<repository-root>\skills` |
| Target_Root | `$CODEX_HOME\skills` |
| Default_CODEX_HOME | `$HOME\.codex` |
| Installation_Mode | `CONTROLLED_COPY` |
| Default_Mode | `CHECK_OR_PLAN_ONLY` |
| Write_Mode | `EXPLICIT_APPLY_ONLY` |
| External_Verification_Required | `YES` |
| Manifest_Is_Not_Canonical_Source | `YES` |

```text
Package_Decision=
READY_FOR_INDEPENDENT_REVIEW

Implementation_Authority=
ONLY_WHEN_THIS_PACKAGE_IS_EXPLICITLY_ACTIVATED_AFTER_REVIEW
```

This package freezes one bounded V1 implementation: install the two named canonical
skills and their resolved shared dependency from a local `ai-skill-hub` checkout
into the Codex user skill root. The implementation must be safe by default,
offline-capable, manifest-owned, idempotent, and reversible.

This package does not implement the tool. It is the complete implementation input
for a later Implementer.

## 2. Evidence Baseline

### 2.1 Confirmed canonical inputs

The following repository files are the required canonical inputs for implementation:

- `skills/workflow-bootstrap/SKILL.md`
- `skills/chatgpt-handoff-pilot/SKILL.md`
- `skills/_protocol/skill_assessment_output.md`

The V1 source inspection confirmed:

- `workflow-bootstrap` and `chatgpt-handoff-pilot` are canonical skill directories;
- both `SKILL.md` files reference
  `../_protocol/skill_assessment_output.md`;
- supporting files referenced from within each skill are contained inside that
  skill's own directory;
- the only confirmed cross-directory payload file required by both skills is
  `skills/_protocol/skill_assessment_output.md`;
- textual references to other repository roles or skills are coordination
  guidance, not additional V1 installation payloads.

The prior read-only audit observed both user-level skills as missing. That is
historical input only. Every later run must inspect the then-current target and
must not assume that it remains absent.

### 2.2 Distinct control planes

The implementation and its documentation must preserve these distinct control
planes:

| Control plane | Contract |
| --- | --- |
| Hub canonical source | `<repository-root>\skills\<skill>` |
| Project runtime copy | `<consumer-project>\.codex\skills\<skill>` |
| Codex user installation | `$CODEX_HOME\skills\<skill>` |
| Codex system skills | `$CODEX_HOME\skills\.system\**` |

The user installation is not a replacement for project-relative runtime copies.
It does not automatically satisfy an `AGENTS.md` or other project rule that names
`<consumer-project>\.codex\skills\...`.

### 2.3 Existing tool prohibition

```text
tools/sync_skills_to_nongit_project.ps1

MUST_NOT_BE_USED_AGAINST=
$HOME
$CODEX_HOME
$CODEX_HOME\skills
```

That tool has project-copy mirroring and stale-cleanup semantics. It must not be
reused, wrapped, or called for this V1 user installation.

## 3. Goal, Scope, and Non-goals

### 3.1 Primary goal

```text
Primary_Goal=
From ai-skill-hub canonical skills,
install the frozen V1 skill set and its dependency closure
into $CODEX_HOME\skills through an explicit controlled-copy action.
```

### 3.2 Frozen V1 installation set

```text
Primary_Skills=
workflow-bootstrap
chatgpt-handoff-pilot

Shared_Dependency=
_protocol

Required_Dependency_File=
skills/_protocol/skill_assessment_output.md
```

V1 manages this exact bundle. It does not expose an arbitrary skill-selection
surface. Adding more skills, supporting partial bundles, or changing dependency
semantics requires a later reviewed package and a source descriptor schema change.

### 3.3 Explicit non-goals

V1 must not implement or claim:

- junction installation;
- symlink installation;
- plugin installation;
- network installation;
- GitHub installation;
- direct Gitea installation;
- `$HOME\.agents\skills` as the default or secondary installation root;
- automatic migration of consumer repositories;
- removal of project runtime copies;
- modification of Codex configuration;
- modification of canonical skill content;
- modification of Codex system-managed `.system`;
- automatic adoption of an existing target;
- whole-target mirroring or stale cleanup;
- Codex App or CLI discovery verification from unit tests.

```text
JUNCTION=
DEFERRED_V2_CANDIDATE

$HOME\.agents\skills=
DEFERRED_EXTERNAL_VERIFICATION
```

## 4. Frozen User-facing Tool Contract

### 4.1 Single tool

```text
Tool=
tools/manage_codex_user_skills.ps1
```

The tool must use one action parameter:

```powershell
-Action Check
-Action Plan
-Action Apply
-Action Uninstall
```

Frozen parameter contract:

| Parameter | Required | Default | Contract |
| --- | --- | --- | --- |
| `-Action` | no | `Check` | `Check`, `Plan`, `Apply`, or `Uninstall` only |
| `-RepositoryRoot` | no | parent of the script's `tools` directory | Explicit alternate local hub checkout or temporary test fixture |
| `-OutputFormat` | no | `Text` | `Text` or `Json` |

No positional target path is allowed. V1 does not accept `-Skill`, `-TargetRoot`,
`-Force`, `-Adopt`, `-Mirror`, or an equivalent scope-widening parameter.

### 4.2 Action semantics

| Action | Writes allowed | Required behavior |
| --- | --- | --- |
| `Check` | none | Inspect source, resolved target, manifest, ownership, conflicts, and current state |
| `Plan` | none | Perform full preflight and report the exact ordered actions that `Apply` would take |
| `Apply` | controlled writes | Install or update only the frozen managed bundle after complete preflight |
| `Uninstall` | controlled writes/deletes | Remove only verified managed entries after complete ownership validation |

```text
Default_Action=
Check

Apply_Requires_Explicit_Flag=
YES: -Action Apply

Uninstall_Requires_Explicit_Flag=
YES: -Action Uninstall
```

No-argument invocation is always equivalent to `-Action Check` and must not create
a directory, lock, temporary file, manifest, backup, or log.

### 4.3 Source root

`-RepositoryRoot` must resolve to a local `ai-skill-hub` checkout containing:

- `skills/workflow-bootstrap/SKILL.md`;
- `skills/chatgpt-handoff-pilot/SKILL.md`;
- `skills/_protocol/skill_assessment_output.md`;
- `tools/codex_user_skills_manifest.json`.

The default is derived from the script location, not the current working directory.
An explicit alternate root exists for a moved checkout and isolated tests; it does
not authorize a network source or a different repository layout.

The source repository must resolve `HEAD` to a full commit ID. Every managed source
path must be tracked and clean relative to that commit, including the absence of
untracked payload files. Otherwise `source_commit` would not describe the bytes
being installed, so the action must return
`BLOCKED_CANONICAL_SOURCE_INVALID`.

## 5. Source Bundle Descriptor

The repository-side file:

```text
tools/codex_user_skills_manifest.json
```

is a versioned source bundle descriptor. It is not the target ownership manifest
and is not a canonical source for skill content.

It must freeze:

```text
schema_version
manager
bundle_version
primary_skills
managed_entries
relative_source_path
relative_target_path
object_role
skill_name
dependency_of
included_files
```

The V1 descriptor must resolve exactly these payload entries:

| Relative source | Relative target under `$CODEX_HOME\skills` | Object role | Included files | Dependency of |
| --- | --- | --- | --- | --- |
| `skills/workflow-bootstrap/` | `workflow-bootstrap/` | `skill` | entire regular-file tree | none |
| `skills/chatgpt-handoff-pilot/` | `chatgpt-handoff-pilot/` | `skill` | entire regular-file tree | none |
| `skills/_protocol/` | `_protocol/` | `dependency_container` | `skill_assessment_output.md` only | both primary skills |

The target `_protocol` directory is a dependency container, not an invocable skill.
The descriptor must not give it a `SKILL.md` or advertise it as a primary skill.
The dependency container is owned as one filtered directory tree so a clean
Uninstall can remove the manager-created directory, while any unexpected target
file changes its installed tree fingerprint and blocks deletion.

The implementation must validate the descriptor rather than embedding an
independent path list in multiple code locations. The script, tests, and docs may
describe the same contract, but only the descriptor drives payload resolution.

## 6. Dependency Closure Contract

Before every action, the resolver must:

1. load and schema-check the source bundle descriptor;
2. confirm both primary skill directories exist;
3. confirm each primary skill contains `SKILL.md`;
4. parse each `SKILL.md` frontmatter and confirm `name` exactly equals its
   directory name;
5. resolve all relative Markdown file links in the two selected skill trees;
6. confirm links internal to a skill remain inside that skill directory and exist;
7. confirm every link that escapes a primary skill directory resolves to an
   explicitly declared managed dependency;
8. reject path traversal, absolute payload paths, links that leave the repository,
   missing files, and undeclared cross-directory payloads;
9. reject source symlinks, junctions, reparse points, and broken links in the
   resolved payload;
10. build a deterministic list of regular files for staging and fingerprinting.

If later source evolution adds another required cross-directory file, the resolver
must not silently omit it. The action must stop with:

```text
Decision=
BLOCKED_DEPENDENCY_CLOSURE_INVALID
```

until the descriptor, tests, and package-authorized implementation are updated
together.

## 7. CODEX_HOME and Target Resolution

Resolution order is frozen:

1. use the non-empty process environment variable `CODEX_HOME`;
2. otherwise resolve the current user's profile directory and append `.codex`;
3. append `skills` to form `Target_Root`.

The implementation may describe step 2 as `$HOME\.codex`, but it must not assign
to or repurpose the PowerShell automatic `$HOME` variable.

The resolver must:

- reject an empty or whitespace-only explicit `CODEX_HOME`;
- normalize to an absolute path without wildcard expansion;
- preserve paths containing spaces;
- reject `.` and `..` escape after normalization;
- compare paths with Windows-appropriate case-insensitive semantics;
- reject overlap in either direction between repository root and target root;
- reject a target root equal to the canonical `skills` source;
- reject a target root whose existing path is a file;
- reject an existing target root that is a symlink, junction, reparse point, or
  broken link;
- reject any managed target resolving outside the normalized target root;
- reject any managed path whose first segment is `.system`.

`Check` and `Plan` must not create a missing `CODEX_HOME` or target root.
`Apply` may create missing normal directories only after every non-write preflight
check has passed.

## 8. Target Ownership Manifest

### 8.1 Location and identity

```text
Ownership_Manifest=
$CODEX_HOME\skills\.ai-skill-hub-user-skills.json

Manager=
ai-skill-hub.codex-user-skills/v1
```

The file:

- is manager metadata, not a skill;
- must not be placed inside `.system`;
- must not contain `SKILL.md`;
- must not overwrite a Codex-native file;
- must be written only after installed payload verification succeeds;
- must never be treated as canonical skill content.

### 8.2 Required fields

The ownership manifest must contain:

```text
schema_version
manager
source_repository
source_commit
installed_at
updated_at
target_root
managed_entries
relative_source_path
relative_target_path
object_role
skill_name
dependency_of
included_files
source_fingerprint
installed_fingerprint
```

Field rules:

- `schema_version` is an integer with explicit supported-version validation;
- `manager` must equal the frozen manager identifier exactly;
- `source_repository` is the logical identifier `ai-skill-hub`, not a credentialed
  remote URL;
- `source_commit` is the full 40-character commit ID observed from the source
  repository at successful Apply time;
- `installed_at` is UTC ISO 8601 and is preserved across upgrades;
- `updated_at` is UTC ISO 8601 and changes only after a successful mutation;
- `target_root` is the normalized resolved target root used for ownership checks;
- paths inside `managed_entries` use forward slashes and are relative only;
- `dependency_of` is an array and contains both primary skill names for the shared
  protocol payload;
- `included_files` is empty for full skill trees and contains only
  `skill_assessment_output.md` for the dependency container;
- `skill_name` contains the directory name for a skill entry and is `null` for the
  dependency container;
- fingerprints are lowercase SHA-256 hex strings.

The console and optional JSON output must redact the current user profile prefix as
`$CODEX_HOME` or `$HOME` where possible. The local ownership manifest may retain
the normalized target root required for safe ownership validation, but it must
contain no token, password, private key, environment dump, or credentialed remote.

### 8.3 Manifest validity

The manifest is invalid if:

- JSON parsing fails;
- a required field is missing or has the wrong type;
- `schema_version` is unsupported;
- `manager` differs;
- `target_root` differs after normalization;
- a relative path is absolute, escapes the target, or enters `.system`;
- duplicate relative targets exist;
- an entry is outside the V1 source descriptor;
- a fingerprint is malformed;
- the manifest describes a link or an unsupported object role.

Invalid manifests are never auto-repaired, overwritten, adopted, or deleted.

## 9. Fingerprint Contract

Use SHA-256 over file bytes and deterministic tree records.

For every managed regular file:

1. compute SHA-256 from its raw bytes;
2. use the normalized relative path with `/` separators;
3. sort paths with ordinal comparison;
4. create one UTF-8 record per file:
   `<relative-path>\0<lowercase-file-sha256>\n`;
5. compute the entry tree fingerprint as SHA-256 over the concatenated records.

Fingerprint rules:

- timestamps, ACLs, owner names, and filesystem enumeration order are excluded;
- empty directories are not payload and are excluded;
- file path case remains as declared by the source descriptor;
- source and installed fingerprints use the same algorithm;
- a managed entry's `installed_fingerprint` must be recomputed after copying and
  must equal its staged `source_fingerprint` before commit;
- any unexpected file inside a managed directory changes the tree fingerprint and
  is a local modification;
- a source or target link/reparse point is never followed for hashing.

## 10. Ownership and Conflict Contract

The tool may replace or remove an existing object only when all conditions hold:

1. the ownership manifest records the exact relative target;
2. the manifest manager equals the frozen manager identifier;
3. the manifest target root equals the current resolved target root;
4. the current object is a normal file or directory of the expected role;
5. the current installed fingerprint equals the manifest
   `installed_fingerprint`;
6. the path is outside `.system`;
7. neither the object nor its managed descendants are symlinks, junctions,
   reparse points, or broken links.

Fail closed for:

```text
UNKNOWN_EXISTING_DIRECTORY
UNKNOWN_EXISTING_FILE
UNKNOWN_JUNCTION
UNKNOWN_SYMLINK
BROKEN_LINK
LOCAL_MODIFICATION_DETECTED
MANIFEST_MISSING
MANIFEST_INVALID
MANIFEST_TARGET_MISMATCH
SYSTEM_MANAGED_TARGET
DEPENDENCY_CLOSURE_INCOMPLETE
CONCURRENT_MANAGER_OPERATION
STALE_TRANSACTION_ARTIFACT
PATH_SAFETY_VIOLATION
```

Required behavior:

- absent manifest plus absent V1 targets means `NOT_INSTALLED`, not an error;
- absent manifest plus any V1 target means `MANIFEST_MISSING` and blocks;
- a valid manifest plus a missing managed entry means `PARTIAL_INSTALL` and
  blocks Apply/Uninstall until reviewed; it is not silently recreated;
- an unknown ordinary same-name file or directory blocks;
- even a junction that points to the expected canonical source blocks because V1
  is controlled-copy only and never adopts links;
- a broken junction or symlink blocks without dereference;
- a locally edited owned copy blocks update and uninstall;
- no action may claim ownership of an existing unowned object;
- no action may delete or mutate a non-manifest object in the target root.
- a manager-prefixed staging, backup, temporary-manifest, or lock artifact left by
  an earlier process blocks a new write action; it is reported for manual review
  and is never assumed safe to delete.

## 11. Machine Readiness Check

All actions must evaluate and report:

```text
Repository root recognizable
Source commit resolvable
Managed source paths tracked and clean at source commit
Source descriptor valid
Canonical skill directories present
Canonical SKILL.md present
Frontmatter names match directory names
Dependency closure complete
CODEX_HOME resolvable
Target root path safe
Target root distinct from repository and canonical source
.system recognized and protected
Target writable for write actions
Ownership manifest absent-valid or present-valid
Managed targets free of unknown links and conflicts
```

For `Check` and `Plan`, target writability may be reported as `NOT_TESTED_NO_WRITE`
when proving it would require a write. For `Apply` and `Uninstall`, writability
must be verified before any payload mutation, using a manager-owned temporary
probe that is removed immediately and never placed under `.system`.

## 12. State and Decision Contract

### 12.1 Current status vocabulary

```text
NOT_INSTALLED
CURRENT
SOURCE_UPDATE_AVAILABLE
LOCAL_MODIFICATION
TARGET_CONFLICT
MANIFEST_INVALID
PARTIAL_INSTALL
```

### 12.2 Success and no-change Decisions

```text
PASS_CODEX_USER_SKILLS_CHECK
PASS_CODEX_USER_SKILLS_PLAN
PASS_CODEX_USER_SKILLS_APPLY
PASS_CODEX_USER_SKILLS_UNINSTALL
NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT
NO_CHANGE_CODEX_USER_SKILLS_NOT_INSTALLED
```

Decision rules:

- `Check` returns `PASS_CODEX_USER_SKILLS_CHECK` when the state is safe and
  actionable but not current;
- `Plan` returns `PASS_CODEX_USER_SKILLS_PLAN` when it produces a non-empty safe
  plan;
- `Apply` returns `PASS_CODEX_USER_SKILLS_APPLY` only after verified mutation and
  manifest commit;
- `Uninstall` returns `PASS_CODEX_USER_SKILLS_UNINSTALL` only after verified
  removal of managed entries and manifest;
- any action observing an exact current install returns
  `NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT`;
- `Uninstall` against a completely absent install returns
  `NO_CHANGE_CODEX_USER_SKILLS_NOT_INSTALLED`.

### 12.3 Blocking Decisions

```text
BLOCKED_CODEX_HOME_UNRESOLVED
BLOCKED_CANONICAL_SOURCE_INVALID
BLOCKED_DEPENDENCY_CLOSURE_INVALID
BLOCKED_TARGET_CONFLICT
BLOCKED_UNKNOWN_PROVENANCE
BLOCKED_LOCAL_MODIFICATION
BLOCKED_BROKEN_LINK
BLOCKED_MANIFEST_MISSING
BLOCKED_MANIFEST_INVALID
BLOCKED_MANIFEST_TARGET_MISMATCH
BLOCKED_SYSTEM_MANAGED_TARGET
BLOCKED_CONCURRENT_OPERATION
BLOCKED_STALE_TRANSACTION_ARTIFACT
BLOCKED_PATH_SAFETY_VIOLATION
BLOCKED_ROLLBACK_FAILURE
BLOCKED_UNEXPECTED_ERROR
```

Blocking precedence is:

1. path and `.system` safety;
2. canonical source and dependency closure;
3. manifest validity and target match;
4. link/reparse and provenance conflicts;
5. local modification or partial state;
6. action-specific readiness;
7. mutation and rollback outcome.

The tool must emit one primary `Decision` and may emit additional findings. It must
not hide a higher-priority safety block behind a generic conflict result.

### 12.4 Exit behavior

- success and no-change Decisions: exit `0`;
- safe blocking Decisions: exit `2`;
- rollback failure or unclassified unexpected failure: exit `3`;
- PowerShell parameter-binding failure: native nonzero exit and no writes.

## 13. Structured Output Contract

Every completed tool run must output at least:

```text
Decision
Action
Repository
Source_Commit
Codex_Home
Target_Root
Requested_Skills
Resolved_Dependencies
Managed_Entries
Current_Status
Planned_Actions
Conflict_Count
Changed_Count
Unchanged_Count
Rollback_Status
Restart_Required
```

Additional required safety fields:

```text
Manifest_Status
System_Skill_Protection
Local_Modification_Count
External_Verification_Required
```

For `-OutputFormat Json`:

- stdout must contain one valid JSON document and no mixed human prose;
- diagnostics go to stderr;
- the JSON `Decision` must equal the text-mode Decision for the same state;
- arrays remain arrays even when empty;
- user-profile path prefixes must be redacted;
- secrets and broad environment values must never be emitted.

`Restart_Required` is:

- `NO` for Check, Plan, and all no-change outcomes;
- `YES` after a changed Apply or changed Uninstall, pending external validation.

## 14. Apply Transaction and Rollback Contract

### 14.1 Concurrency

`Apply` and `Uninstall` must acquire an exclusive manager lock at:

```text
$CODEX_HOME\skills\.ai-skill-hub-user-skills.lock
```

The lock is temporary manager metadata:

- it must be created only after complete read-only preflight;
- it must be held through mutation, verification, and manifest commit;
- it must be removed in `finally`;
- inability to acquire it returns `BLOCKED_CONCURRENT_OPERATION`;
- Check and Plan must not create it.

### 14.2 Apply sequence

The sequence is frozen:

```text
Read-only preflight
→ Resolve and validate dependency closure
→ Create only missing normal CODEX_HOME/target directories and journal that creation
→ Acquire exclusive manager lock
→ Verify write readiness
→ Build unique same-volume staging payload
→ Validate staged paths and fingerprints
→ Create unique same-volume backup area
→ Backup only currently owned targets and prior manifest
→ Move staged entries into their exact targets
→ Recompute and verify installed fingerprints
→ Atomically write/replace ownership manifest
→ Verify final manifest and targets
→ Delete transaction backup only after success
→ Release lock
```

If read-only preflight determines the installation is already current, Apply must
return the no-change Decision before acquiring the lock, probing writability, or
creating transaction objects.

Any manager-created CODEX_HOME or target directory is part of the transaction
journal. A failed fresh Apply must remove it only when it remains empty and was
created by that transaction; pre-existing directories are never removed.

Temporary names must be manager-prefixed, unique, inside the target root's volume,
outside `.system`, and recorded in the in-memory transaction journal.

The manifest must be serialized to a unique adjacent temporary file, flushed and
closed, then atomically renamed into place when absent or atomically replaced when
present. The previous manifest remains in the transaction backup until final
verification completes.

### 14.3 Apply failure

On failure after mutation starts:

1. stop forward progress;
2. remove only new targets recorded by the current transaction journal;
3. restore only the backed-up owned targets and prior manifest;
4. verify restored fingerprints and manifest bytes;
5. remove staging, backup, and lock only after verified restoration;
6. report the original failure and `Rollback_Status`.

If restoration cannot be verified:

```text
Decision=
BLOCKED_ROLLBACK_FAILURE
```

The tool must preserve the backup and transaction evidence path, redact the user
profile prefix in output, and require manual recovery. It must not write a
half-install manifest or claim success.

## 15. Uninstall Transaction

The sequence is frozen:

```text
Resolve target
→ Read and validate ownership manifest
→ Validate manager and target ownership
→ Verify every current installed fingerprint
→ Refuse on local modification or partial state
→ Acquire exclusive manager lock
→ Backup manifest and managed entries
→ Remove only manifest-managed entries
→ Remove an owned dependency container only if the manifest covers it and it is empty
→ Remove ownership manifest
→ Verify .system and unrelated target entries remain
→ Delete backup only after success
→ Release lock
```

If read-only preflight determines the bundle is fully absent, Uninstall must
return the not-installed no-change Decision before acquiring the lock or creating
transaction objects.

Uninstall must never:

- enumerate the target root and delete entries not in the manifest;
- use `robocopy /MIR`;
- run whole-directory stale cleanup;
- remove an unexpected file from `_protocol`;
- remove `.system`;
- remove a locally modified managed entry;
- remove an unowned same-name entry;
- infer ownership from matching content alone.

Uninstall failure uses the same rollback journal and restoration guarantees as
Apply.

## 16. Idempotency and Upgrade Rules

| Scenario | Required result |
| --- | --- |
| First Apply to an absent clean target | Install full bundle and write manifest |
| Second identical Apply | `NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT`; zero writes |
| Check/Plan on current install | no writes; no temporary objects |
| Canonical source changed, target still equals installed fingerprint | update owned entries only |
| Canonical source changed, target locally modified | `BLOCKED_LOCAL_MODIFICATION` |
| Unknown same-name copy exists | blocked; never overwrite or adopt |
| Manifest absent and all managed targets absent | safe `NOT_INSTALLED` |
| Manifest absent and any managed target exists | `BLOCKED_MANIFEST_MISSING` |
| Clean Uninstall | remove only owned entries and manifest |
| Repeated Uninstall after clean removal | `NO_CHANGE_CODEX_USER_SKILLS_NOT_INSTALLED` |

An upgrade must preserve `installed_at`, update `updated_at` and `source_commit`,
and refresh only entries whose source fingerprint changed. It must not recopy
unchanged entries to simulate idempotency.

V1 does not migrate an unsupported ownership-manifest schema. It blocks and
requires a separately reviewed migration plan.

## 17. `.system` Protection

The implementation must treat:

```text
$CODEX_HOME\skills\.system
```

as system-managed and permanently outside ownership.

Required protections:

- reject any source descriptor or manifest path that enters `.system`;
- never traverse `.system` for cleanup, ownership, or stale detection;
- never include `.system` in staging, backup, replacement, or uninstall;
- allow an existing normal `.system` directory to coexist without treating it as
  a conflict;
- snapshot `.system` in tests and prove it is unchanged after Check, Plan, Apply,
  failed Apply rollback, Uninstall, and failed Uninstall rollback.

## 18. Future Implementation File Allowlist

### 18.1 Required_New_Files

```text
tools/manage_codex_user_skills.ps1
tools/codex_user_skills_manifest.json
docs/human/CODEX_USER_SKILLS_BOOTSTRAP_WINDOWS.md
tests/test_codex_user_skills_bootstrap.py
```

### 18.2 Required_Modified_Files

```text
tools/README.zh-CN.md
tools/run_local_checks.ps1
```

Required modification purposes only:

- `tools/README.zh-CN.md`: document the frozen action interface and safety boundary;
- `tools/run_local_checks.ps1`: invoke the isolated bootstrap test suite without
  installing into a real user directory.

### 18.3 Conditional_Modified_Files

```text
README.md
SYNC.md
docs/human/REPOSITORY_OVERVIEW.md
```

A conditional file may be changed only if the Implementer records concrete
evidence that users would otherwise be directed to the prohibited non-git sync
tool or could not discover the new human guide. The change must be a short link or
boundary clarification. Absence of a preferred cross-link is not sufficient
evidence to change all three files.

### 18.4 Explicitly_Out_Of_Scope

All other repository paths are out of scope, including:

```text
skills/**
.agents/**
.github/**
AGENTS.md
SKILLS_INDEX.md
skills_index.json
config/**
docs/HANDOFF.md
docs/status/**
tasks/**
business repositories
```

The implementation execution report is returned in the task/PR conversation by
default. Persisting a new report file requires separate exact-path authorization.

## 19. Test Isolation Contract

All automated tests must:

- use a unique temporary repository fixture when source mutation is required;
- use a unique temporary `CODEX_HOME`;
- set `CODEX_HOME` only for the child process under test and restore the parent
  process environment;
- use only temporary regular files/directories and synthetic fixtures;
- never write to the real `$HOME\.codex`;
- never write to the real `$HOME\.agents`;
- never write to a repository under `D:\dev` other than the implementation
  worktree authorized by the later task;
- never invoke the existing non-git sync tool;
- clean up only the exact temporary paths created by the test.

Tests must not require Codex App discovery, Codex CLI discovery, a network, Gitea,
GitHub, credentials, or a business repository.

## 20. Required Test Matrix

| # | Scenario | Required assertion |
| --- | --- | --- |
| 1 | Fresh target | Apply installs both skills, dependency payload, and valid manifest |
| 2 | Repeated install | Second Apply returns exact no-change Decision and performs zero writes |
| 3 | Correct owned copy | Check reports `CURRENT`; fingerprints and ownership validate |
| 4 | Stale owned copy | Apply updates only source-changed owned entries |
| 5 | Unknown conflicting skill | Block; unknown content remains byte-for-byte unchanged |
| 6 | Existing correct junction | Block as unknown provenance; do not follow, adopt, or replace |
| 7 | Broken junction | Return `BLOCKED_BROKEN_LINK`; no writes |
| 8 | Missing canonical `SKILL.md` | Return `BLOCKED_CANONICAL_SOURCE_INVALID` |
| 9 | Missing dependency | Return `BLOCKED_DEPENDENCY_CLOSURE_INVALID` |
| 10 | Hub path containing spaces | Check, Plan, and Apply operate correctly |
| 11 | `CODEX_HOME` containing spaces | Check, Plan, Apply, and Uninstall operate correctly |
| 12 | Preserve `.system` | `.system` tree fingerprint is identical before and after every action |
| 13 | Apply failure rollback | Prior targets and manifest are restored; no half-install manifest |
| 14 | Manifest corruption | Block; do not overwrite, repair, or remove corrupt manifest |
| 15 | Local modification before update | Return `BLOCKED_LOCAL_MODIFICATION`; preserve local bytes |
| 16 | Local modification before uninstall | Return `BLOCKED_LOCAL_MODIFICATION`; remove nothing |
| 17 | Uninstall clean owned install | Remove only managed entries and manifest |
| 18 | Repeated uninstall | Return exact not-installed no-change Decision |
| 19 | Check/Plan no side effects | Full temporary tree snapshot remains identical |
| 20 | Business repository remains untouched | No tool path targets a business repo; synthetic sentinel remains identical |

Additional required cases:

- source descriptor path traversal is blocked;
- ownership manifest target mismatch is blocked;
- unsupported manifest schema is blocked;
- unknown extra file in managed `_protocol` is treated as local modification;
- existing unrelated user skill is preserved across Apply and Uninstall;
- concurrent write action is blocked by the manager lock;
- a stale manager transaction artifact blocks a write action and is not deleted;
- JSON is parseable and its Decision matches text mode;
- output redacts the temporary user-profile prefix consistently;
- failed rollback preserves recovery evidence and returns exit `3`.

## 21. Validation Plan for Later Implementation

The later implementation must run, at minimum:

```powershell
git diff --check
git status --short
git diff --name-only
git diff --stat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1
```

It must also run the focused isolated test command documented by
`tools/run_local_checks.ps1` and report:

```text
Tests_Run
Tests_Passed
Tests_Failed
Dry_Run_Side_Effects
Real_User_Directory_Modified
Business_Repository_Modified
```

Before declaring implementation complete, compare the actual changed path set with
the allowlist in section 18. Any unapproved path blocks completion.

## 22. Human Documentation Requirements

`docs/human/CODEX_USER_SKILLS_BOOTSTRAP_WINDOWS.md` must clearly explain:

- the four control planes from section 2.2;
- prerequisites and offline local-checkout use;
- `CODEX_HOME` resolution;
- no-argument Check behavior;
- Check, Plan, Apply, and Uninstall examples;
- the exact V1 bundle and dependency closure;
- ownership manifest location and purpose;
- conflict and local-modification handling;
- safe upgrade behavior;
- rollback and uninstall behavior;
- `.system` protection;
- why user installation does not satisfy a project-relative `.codex/skills` path;
- why the old non-git sync tool must not target the user skill root;
- why a changed install may require an App restart or new session;
- which external E2E checks remain required.

The documentation must not claim:

- user installation automatically fixes `Derivative_Data` or another consumer
  repository;
- project runtime copies are deprecated;
- plugin installation was validated;
- junction behavior was validated;
- copying files proves Codex discovery;
- no restart or new session is required;
- external E2E is complete.

## 23. Business Repository Boundary

The implementation, tests, and docs must not modify:

```text
D:\dev\Derivative_Data
D:\dev\AMS_Data
D:\dev\Workstation_Ops
any other business repository
```

They must not:

- edit a business repository `AGENTS.md`;
- create a business repository `.codex\skills`;
- run a sync or installer in a business repository;
- fold consumer migration decisions into the installer;
- report a consumer repository as migrated because user skills were installed.

Consumer decisions require a later independent task:

```text
Consumer Repository Skill Reference Migration
```

That task must decide per repository whether to retain the project runtime copy,
use user-level invocation, or use a reviewed two-level fallback.

## 24. External Host-level E2E Boundary

After implementation review, merge, and separate authorization for a real user
installation, host-level validation must check:

```text
Codex App discovers both user-level skills
Codex CLI discovers both user-level skills
A new session observes the installation
Whether the Codex App must restart
Both skills can read the shared _protocol dependency
Project-relative .codex/skills references remain independently evaluated
```

Unit tests and a successful file copy do not prove these statements.

```text
External_E2E_Performed_During_Implementation=
NO

Real_User_Installation_During_Implementation=
PROHIBITED
```

## 25. Stop Conditions

Stop without scope expansion if:

1. canonical skill paths differ from this package;
2. a skill frontmatter name differs from its directory;
3. dependency closure cannot be resolved completely;
4. `CODEX_HOME` cannot be resolved unambiguously;
5. a target same-name skill has unknown provenance;
6. a target is an unknown junction, symlink, reparse point, or broken link;
7. progress would require deleting an unknown object;
8. progress would require modifying `.system`;
9. progress would require modifying a business repository;
10. progress would require modifying canonical skill content;
11. Apply atomicity and rollback cannot be demonstrated;
12. Uninstall cannot be limited strictly by the ownership manifest;
13. tests would write to a real user directory;
14. the implementation would create a second canonical source;
15. progress would change the existing non-git project sync contract;
16. an implementation file outside section 18 is required;
17. a real installation is required to make unit tests pass;
18. a corrupted or unsupported manifest would need automatic repair;
19. a local modification would need force-overwrite behavior;
20. a complete rollback cannot be verified.

```text
Decision=
BLOCKED_TASK_PACKAGE_STOP_CONDITION
```

The Implementer must report the exact condition and must not add a `-Force`,
`-Adopt`, or cleanup bypass.

## 26. Bounded Implementation Sequence

When explicitly activated after independent review:

1. verify the implementation repository, branch, exact baseline, clean working
   tree, empty staging area, and absence of a Git operation;
2. read `AGENTS.md`, this package, both canonical `SKILL.md` files, the shared
   protocol, commit convention, current handoff/status surfaces, and existing tool
   conventions;
3. restate the exact allowed and forbidden path sets;
4. implement only the required files and evidence-supported conditional links;
5. run only isolated temporary-`CODEX_HOME` tests;
6. run the validation in section 21;
7. inspect the full diff and changed path set;
8. produce the structured execution report in section 27;
9. obtain independent review before merge;
10. merge through the normal repository process only after review approval;
11. do not perform a real user install in the implementation round.

## 27. Required Implementation Report

The Implementer must return:

```text
Decision
Repository
Starting_Branch
Starting_HEAD
Source_Branch
Source_Parent
Source_Commit
Changed_Files
Diff_Stat
Working_Tree
Staging
Git_Operation

Installation_Mode
Canonical_Source
Target_Contract
Manifest_Contract
Ownership_Contract
Rollback_Contract
Dependency_Closure
System_Skill_Protection

Tests_Run
Tests_Passed
Tests_Failed
Dry_Run_Side_Effects
Real_User_Directory_Modified
Business_Repository_Modified
External_E2E_Performed
Residual_Risks
```

The report must also state:

- what was changed;
- what was explicitly not implemented;
- whether any conditional file was changed and the exact evidence;
- whether every test used a temporary `CODEX_HOME`;
- whether `.system` remained unchanged;
- whether an independent reviewer can reproduce the boundary and validation;
- the one recommended next action.

## 28. Review, Merge, Release, and Installation Gates

```text
Task package independent review
→ Task package merge
→ Separate implementation activation
→ Bounded implementation
→ Isolated test and rollback evidence
→ Independent code/security review
→ Normal merge
→ Release/availability decision
→ Separate real-user-install authorization
→ Host-level external E2E
→ Separate consumer-repository migration decisions
```

No gate may infer the next:

- package creation is not implementation approval;
- implementation success is not merge;
- merge is not real installation approval;
- file installation is not Codex discovery verification;
- user-level discovery is not consumer repository migration.

## 29. Acceptance Standard

Implementation passes only if:

1. the exact user-facing interface in section 4 is implemented;
2. only the approved implementation files changed;
3. the V1 descriptor resolves the exact two-skill plus shared-protocol bundle;
4. Check and Plan produce zero filesystem side effects;
5. Apply is explicit, idempotent, fingerprint-verified, and rollback-capable;
6. Uninstall removes only manifest-owned unmodified entries;
7. unknown content, links, corrupt manifests, and local modifications fail closed;
8. `.system` and unrelated user skills remain unchanged;
9. all automated tests use temporary paths;
10. the required test matrix passes;
11. no business repository or real user directory was modified;
12. docs preserve the four-control-plane distinction;
13. the implementation report is complete;
14. independent review finds no critical ownership, rollback, or target-safety gap.

The accepted V1 result remains a local controlled-copy manager for a frozen skill
bundle. It is not a plugin, a network installer, a project runtime migration, or a
claim that Codex discovery has been externally verified.
