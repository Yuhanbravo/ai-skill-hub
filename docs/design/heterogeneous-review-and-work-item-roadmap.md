# Heterogeneous Review and Work Item Roadmap

Status: `ROADMAP_ONLY`
Scope: `ai-skill-hub` / single-consumer pilot follow-up
Current priority: `C3_PRIORITY`

This document records a conservative roadmap for heterogeneous model review and lightweight Work Item / Session management. It is a design and sequencing artifact only. It does not implement a new skill, registry, state machine, adapter, transcript collector, or multi-model runner.

## 1. Problem Statement

In the current working pattern, Codex usually performs the main implementation. High-risk or important changes may need an independent review by a heterogeneous model or tool. That review can happen in VS Code, Kimi, Claude, ChatGPT, or another terminal, while the business repository remains the place where project facts and Git evidence are preserved.

The current pain is not a lack of chat windows. It is the cost of manually maintaining titles, Session IDs, cross-terminal mappings, conversation archives, and review handoffs. Full conversation governance would add ceremony without improving delivery. The useful unit is the formal output and the important event: a Work Item, a frozen reviewed commit, a review artifact, a finding, a decision, or a closure action.

The conversation itself must not become the sole source of project facts. Formal facts belong in the business repository and its task, report, review, status, handoff, and Git evidence surfaces. A future workbench may project lightweight instance state, but it must not replace those project facts.

## 2. Design Principles

1. One Work Item has one formal implementation fact chain.
2. A heterogeneous model is normally a Reviewer, not a new project mainline.
3. Every formal Review freezes the reviewed commit before review begins.
4. Findings are evidence-based; model vote counts do not decide correctness.
5. A Session maps to a Work Item; Session-to-Session mesh mappings are not maintained.
6. A temporary conversation with no formal output does not enter the governance system.
7. Protocol and observed instance state remain separate.
8. Business-project facts take precedence over generic Skill guidance.
9. Automation must lower registration cost rather than add ceremony.
10. Existing ownership boundaries are preserved: `workflow-bootstrap` owns workflow shell guidance; `chatgpt-handoff-pilot` owns Task Package, Bounded Execution, Execution Report, and Review Packet protocol; `codex-project-workflow` owns the compact single-repository Codex workflow; `update-project-status` owns Git-first/workspace/task-source status refresh.

## 3. Existing Capability Map

| Component | Current responsibility | Covered today | Gap for this roadmap |
| --- | --- | --- | --- |
| `workflow-bootstrap` | Workflow shell, role chain, review-tier guidance, and future runtime-pack mapping | Role chain, review tiers, phase boundaries, thin-entry guidance | No heterogeneous-review-specific orchestration protocol |
| `chatgpt-handoff-pilot` | Handoff protocol | Task Package, Bounded Execution, Execution Report, Review Packet | Review provenance and frozen-commit fields are not yet a dedicated extension |
| `codex-project-workflow` | One-repository Codex workflow | Task Card, preflight, fixed boundaries, risk-based sub-agent decision, compact final report | No external Reviewer thin handoff entry |
| `update-project-status` | Status refresh | Git-first, workspace, and task-source status generation | Does not own Work Item, Session, conversation, or model lifecycle |
| `ai-workbench` | Future instance-state center | Future concept only; not a current repository capability | No minimum Work Item / Session registry contract exists |
| Business repository | Project facts and delivery evidence | Task Package, Execution Report, Review Report, Closure Report, status/handoff, Git evidence where adopted | Cross-terminal review mapping is mostly manual and project-specific |

The `ai-workbench` row is intentionally marked as future context, not as a capability already implemented in this repository.

## 4. Target Architecture

The target is a layered arrangement. It is not a request to implement every layer in this roadmap.

```text
ai-skill-hub
├─ canonical protocols
├─ workflow guidance
├─ templates
├─ validators / helper scripts (future candidates only)
└─ does not store concrete business Work Item state

ai-workbench (future instance-state center)
├─ Work Item Registry
├─ Session Registry
├─ Artifact Mapping
├─ Review Run Mapping
└─ Current State Projection

business repository
├─ Task Package
├─ Execution Report
├─ Review Report
├─ Closure Report
├─ Status / Handoff
└─ Git evidence

AI terminals
├─ Codex Implementer
├─ External Reviewer
├─ Governor / Adjudicator
└─ Temporary Consultation
```

Data ownership remains explicit:

- The hub stores reusable protocol and guidance, not concrete business Work Item records.
- The business repository stores project facts, formal artifacts, review evidence, decisions, and commits.
- A future workbench may store instance mappings and projections, but it is not a replacement for business-repository evidence.
- AI terminals are execution or review surfaces, not authoritative project databases.

## 5. Management Levels

Use the lowest level that is sufficient for the risk and the formal output.

### L0 — Temporary Consultation

- No Session registration.
- No formal Decision.
- A useful conclusion is carried back to the main line if needed.
- The conversation may be discarded.

### L1 — Formal Auxiliary Session

- Used for a formal Review, audit, or validation.
- Records the Work Item, role, reviewed commit, and resulting artifact.
- Does not maintain a complete chat transcript or full Session graph.

### L2 — High-risk / Authoritative Execution

- Used for main implementation, real execution, database write, merge, release, or formal remediation.
- Records baseline, role, state, Decision, and Artifact completely enough to reconstruct the event.

## 6. Roadmap Phases

### C3 — Codex Project Workflow Real Pilot

Goal:

- Execute a real, low-risk, tightly bounded pilot.
- Validate Task Card, Repository Preflight, Explicit Boundaries, and Final Report.
- Observe whether repeated prompt text, handoff time, and reviewer search effort decrease.
- Observe whether governance adds noticeable burden.

Entry gate:

- The current C3 design package exists.
- A separate real, non-artificial, low-risk pilot task is selected.
- The project-local rules remain the highest authority.
- The target repository supplies a clean, exact, accepted baseline and its own task authorization.

Completion evidence:

- The pilot has actually run.
- An independent Review is complete.
- Critical findings are zero.
- Major workflow-governance findings are zero.
- The maintainer does not observe obvious unnecessary ceremony.

This roadmap records C3 as the current priority; it does not claim C3 is complete.

### C4 — Heterogeneous Review Protocol

Target flow:

```text
Codex Implementation
→ Frozen Review Packet
→ External Reviewer
→ Normalized Findings
→ Governor Adjudication
→ Fix or Closure
```

Future candidate artifacts (`FUTURE_CANDIDATE_NOT_AUTHORIZED`):

- `skills/workflow-bootstrap/orchestration/heterogeneous_review.md`
- A Review Packet provenance extension owned by `chatgpt-handoff-pilot`
- An external-review handoff reference owned by `codex-project-workflow`
- Finding-normalization guidance

Entry gate:

- C3 shows practical value.
- A real heterogeneous-review need exists.
- Repeated manual Review Packet work is observed, not hypothetical.

Completion evidence:

- At least one real heterogeneous-review loop completes.
- The reviewed commit can be reconstructed.
- Review boundary is clear.
- Findings can be normalized without vote-based adjudication.
- A management thread can make an evidence-based decision.
- No second handoff protocol is created.

Pause or cancel if no real review need exists, the manual process remains cheap, provenance cannot be reconstructed, or the design conflicts with existing ownership.

### C5 — Minimal Work Item Registry

Goal:

- Use minimal mechanical assistance to lower registration cost.
- Keep technical judgment outside the registry.
- Register formal outputs and important events, not every conversation.

Future candidate commands (`FUTURE_CANDIDATE_NOT_AUTHORIZED`):

```text
work-item init
work-item add-session
work-item checkpoint
work-item close-session
work-item close
work-item show
```

Future candidate storage and projections (`FUTURE_CANDIDATE_NOT_AUTHORIZED`):

- Append-only JSONL.
- `STATUS.md`.
- `SESSION_INDEX.md`.
- Title suggestion and next action.

Entry gate:

- C4 produces a real, repeated registration burden.
- Manual registration cost is observed and recorded.
- Fields are stable across at least two real Work Items.

Completion evidence:

- Human-entered fields are materially fewer than automatically collected fields.
- Current state can be rebuilt from events.
- No database or Web UI is required.
- A failure cannot destroy business-repository facts.

Pause or cancel if a registry begins to own technical decisions, requires complete conversation capture, or costs more to maintain than it saves.

### C6 — Optional Transcript Adapters

Goal:

- Discover, redact, and trace local JSONL transcripts for platforms that provide stable logs.
- Use transcripts only as historical evidence assistance.
- Keep the project repository and formal artifacts as the SSOT.

Entry gate:

- A real session-location or traceability pain point exists.
- A platform supplies a stable local log format.
- Privacy, retention, and sensitive-data boundaries are explicit.

No adapter is authorized by this roadmap.

### C7 — Optional Reviewer Harness

Goal:

- Consider a multi-model Review Runner only after real manual benefit is demonstrated.
- Let multiple Reviewer adapters independently inspect the same frozen change package.

Entry gate:

- Manual heterogeneous Review is stable.
- Review Packet contract is frozen.
- At least two Reviewer adapters can be invoked safely and repeatably.
- Automation benefit is materially greater than maintenance cost.

No harness or multi-model invocation is authorized by this roadmap.

## 7. Entry Gates and Global Stop Conditions

Each phase requires evidence from real use, approval by the relevant maintainer or project owner, and an explicit decision to continue. A phase may be paused when evidence is incomplete and cancelled when the underlying need disappears. No phase is approved merely because its candidate artifact is described here.

Global stop conditions:

- No real usage scenario exists.
- The manual process is already cheap enough.
- Automation maintenance costs exceed the saved effort.
- A candidate conflicts with current Skill ownership.
- The design requires an unstable private platform API.
- A pilot would be manufactured only to demonstrate capability.
- State management starts replacing business delivery.
- A formal finding cannot be tied to a frozen commit or evidence artifact.
- The proposal begins managing every chat window rather than formal outputs and events.

## 8. Explicit Non-goals

This roadmap and the current round do not authorize:

- Creating a `work-item-registry` Skill.
- Implementing a JSONL Registry.
- Developing a Web UI.
- Creating a database.
- Automatically changing ChatGPT, Kimi, VS Code, or Codex titles.
- Automatically collecting all chat records.
- Automatically accessing private platform sessions.
- Automatically running multi-model Review.
- Modifying a business repository.
- Creating a project-side runtime pack.
- Changing existing Skill core ownership.
- Copying an external open-source Skill.
- Introducing CI, hooks, or validators.

Future candidates remain labeled `FUTURE_CANDIDATE_NOT_AUTHORIZED` until a separate reviewed task package explicitly authorizes them.

## 9. External References

The following are future research candidates only:

- Agent Skills open specification.
- OpenClaw `agent-skills` directions such as `handoff`, `autoreview`, `agent-transcript`, and `session-viewer`.
- `obra/superpowers` directions such as `requesting-code-review`, `receiving-code-review`, and `verification-before-completion`.

These references are not current repository dependencies. This roadmap does not copy their implementation, claim comprehensive verification, or treat their existence as authorization. Any future use requires source verification and a separate bounded review.

## 10. Decision Log

### Decision: `LAND_DOCS_ONLY_ROADMAP_BEFORE_IMPLEMENTATION`

Rationale: the cross-stage plan has durable value outside the current conversation, but its implementation benefit has not yet been proven by a real C3/C4 pilot.

Current authorization: `ROADMAP_DOCUMENTATION_ONLY`

Current priority: complete C3 before C4 implementation.

Deferred:

- C4 heterogeneous review implementation.
- C5 minimal Work Item Registry implementation.
- C6 transcript adapters.
- C7 Reviewer harness.

## 11. Current Round Boundary

This round creates only the Roadmap and its docs-only task package. It does not claim `ROADMAP_FROZEN`, `C3_COMPLETE`, `C4_AUTHORIZED`, `C5_AUTHORIZED`, or `IMPLEMENTATION_READY`. Independent review is the next gate.
