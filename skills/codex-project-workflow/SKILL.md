---
name: codex-project-workflow
description: "Use when starting, implementing, reviewing, closing, or handing off a repository task that needs a compact Task Card, explicit edit boundaries, repository preflight, risk-based sub-agent decisions, and a concise final report."
metadata:
  triggers:
    - start a bounded Codex project task
    - prepare a task card and repository preflight
    - implement a repository change with explicit boundaries
    - review or close a Codex implementation round
    - prepare a compact ChatGPT handoff report
  side_effects:
    - read_only
    - write_files
---
# Codex Project Workflow

Use this skill as a compact workflow layer for a single repository task. Preserve project-local instructions and task packages as the authority for that task. Keep reusable workflow instructions in `ai-skill-hub`; keep project state, business context, and local decisions in the target repository.

## Do not replace adjacent skills

- Use `chatgpt-handoff-pilot` for task-package, bounded-execution, and execution-report protocol.
- Use `workflow-bootstrap` for repository-wide workflow-shell and runtime-pack design.
- Use `project-takeover`, `update-project-status`, `file-structure-check`, or other focused skills when their specialized output is the task objective.
- Do not add adapters, indexes, runtime packs, scripts, or project-local files merely by invoking this skill.

## Workflow

1. Classify the task before planning edits. Use one primary type: `docs-only`, `implementation`, `evidence-only`, `preflight-only`, `review-only`, `closure`, or `takeover`.

   | Type | Primary outcome |
   | --- | --- |
   | `docs-only` | Bounded documentation update and evidence of consistency. |
   | `implementation` | Authorized code, configuration, or instruction change plus validation. |
   | `evidence-only` | Readonly findings, commands, and citations; no edits. |
   | `preflight-only` | Readiness, scope, and validation plan; no implementation. |
   | `review-only` | Readonly assessment of a diff, artifact, or proposal. |
   | `closure` | Final verification, compact report, and a clearly named next action. |
   | `takeover` | Repository orientation and a handoff-ready understanding; defer to `project-takeover` when applicable. |

2. Read the available local context before editing. Read `AGENTS.md` first when present, then `NEXT_ACTION.md`, the active task package or Task Card, and applicable project status or handoff documents. Treat project-local instructions as controlling for that repository. Record absent or conflicting inputs as assumptions or blockers; do not invent their contents.

3. Create or confirm a short Task Card using [references/task_card_template.md](references/task_card_template.md). Keep it as the working summary instead of repeating a long prompt. State the primary task type, authorized paths, forbidden paths, validation, and handoff expectation.

4. Apply fixed boundaries from [references/boundary_template_guide.md](references/boundary_template_guide.md) before edits. Name in-scope work, no-touch paths, assumptions, and stop-and-report conditions. Do not perform opportunistic cleanup.

5. Run repository preflight before edits using [references/preflight_checklist.md](references/preflight_checklist.md). Confirm repository state, governing instructions, authorized paths, existing conventions, and proportional validation commands. If preflight exposes an unresolved boundary conflict, stop and report it instead of widening scope.

6. Decide whether sub-agents materially reduce risk. Use [references/subagent_roles.md](references/subagent_roles.md) to assign a narrow readonly investigation, audit, validation, or report-closing role only when it can run independently and safely. Keep sub-agents readonly unless the task package explicitly authorizes delegation with named, disjoint write paths. The main agent retains final judgment, integration, scope control, and the final report.

7. Execute only the authorized delta. Re-check boundaries before any new file family, external action, or scope expansion. Keep canonical workflow assets in `ai-skill-hub`; do not copy this skill or its references into business repositories. A business repository may keep local Task Cards, `NEXT_ACTION.md`, validation commands, and project-specific constraints when it opts in.

8. Validate proportionately, then prepare a compact handoff using [references/final_report_template.md](references/final_report_template.md). State changed files, validation evidence, what was explicitly not implemented, risks or assumptions, workflow-adoption fields, and one recommended next action.

## Reference selection

- Use the Task Card template at the beginning of every non-trivial round.
- Use the boundary guide before edits or delegated work.
- Use the optional `NEXT_ACTION.md` template only when the target repository chooses a one-page state entry; it is never canonical skill content.
- Use the preflight checklist before edits and the final report template at closure.
- Use the sub-agent roles only after the task-risk decision; do not delegate merely to make a task look parallel.

## Constraints

- Keep task instructions short, explicit, and bounded; do not create a second local rulebook.
- Never let a sub-agent's conclusion replace the main agent's final review.
- Do not treat absence of `AGENTS.md`, `NEXT_ACTION.md`, task packages, or status documents as permission to infer project facts.
- Do not make `NEXT_ACTION.md` mandatory.
- Do not convert a preflight, review, evidence, or closure task into implementation without explicit authorization.
