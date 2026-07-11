# Fixed Boundary Template Guide

Use the following fixed sections in a Task Card, implementation note, or delegation message. Fill values from the controlling task package; do not weaken the headings or substitute vague wording.

```markdown
## In scope

Change only: <authorized files, directories, or readonly evidence target>.

## Explicit non-goals

Do not: <features, cleanup, rollout, external actions, or follow-on phases>.

## No-touch paths

Do not modify: <paths>; if no additional paths are named, state `No paths beyond the authorized delta.`

## Assumptions to record

Assume only: <stated assumption>. Record uncertainty instead of inventing facts.

## Stop and report when

Stop before: <scope conflict, missing authority, required fixture/tool change, validation contradiction, unsafe external action, or ambiguous write ownership>.
```

Invoke every section before edits. For a readonly task, set `Change only` to the evidence target and explicitly state that no files will be modified. For a delegated task, copy the same boundaries into the sub-agent request and name its exact authority.

Do not use the template to authorize work that the task package has not authorized. A discovered improvement belongs in the final report or a follow-up Task Card.
