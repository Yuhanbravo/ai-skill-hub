# Readonly Sub-Agent Roles

Use a sub-agent only when its focused result can reduce a material risk without delaying or broadening the main task. The main agent owns final judgment, integration, boundary decisions, and reporting.

| Role | Readonly assignment | Return to main agent |
| --- | --- | --- |
| Context Scout | Locate controlling instructions, active task sources, status documents, and relevant conventions. | Source paths, confirmed facts, conflicts, and missing inputs. |
| Repo Auditor | Inspect repository state, authorized/no-touch paths, related artifacts, and likely boundary risks. | Concise evidence-backed boundary findings. |
| Validation Checker | Identify and, when authorized, run relevant readonly validation; assess whether results cover acceptance. | Commands, results, gaps, and no proposed out-of-scope fix. |
| Report Closer | Review the Task Card, changed-file list, and validation evidence for a compact handoff. | Missing final-report fields, risks, and recommended next action. |

Default all roles to readonly. Use an implementation sub-agent only when the task package explicitly permits it, assigns a named disjoint write scope, explains that other agents may edit concurrently, and leaves the main agent able to review and integrate the outcome.

Do not delegate when the task is small, the next decision depends on the delegated result, write authority is ambiguous, sensitive context should remain narrow, or local instructions prohibit delegation.
