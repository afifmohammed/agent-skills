---
artifact: field-note
title: Git context for state diagram simplification commits
created: 2026-04-13
covers_commits:
  - 9908a46 refactor: simplify cs-implement-plan state diagram
  - 43d14ee docs: establish docs/{feature} structure with field notes
---

# Context for future agents

## What happened

The `cs-implement-plan` skill's Mermaid state diagram was simplified by removing `HumanInput` as a standalone state. This was the only change approved from a broader simplification proposal that also considered removing `Fix` (deferred) and collapsing to phase-level only (rejected).

## Why only HumanInput was removed

There was a structural gap in the diagram: `Fix → HumanInput` existed, but no `HumanInput → Verify*` return edges existed. The Verify phase prose at line 319 had to patch this with a resume rule. This was direct evidence that the diagram was not modeling pause/resume behavior honestly.

`Fix` was kept because its 4 outgoing edges are return-to-caller semantics (deterministic dispatch based on prior state), not high routing-judgment branching. The verification substates (`VerifyPlanned → VerifyBuild → VerifyTests`) were kept because they make the verification ordering visible and harder to skip — collapsing them into prose trades scannable ordering for a theoretical complexity win that hasn't been measured.

## Why "Human exit" was renamed to "Pause exit"

After removing `HumanInput` from the diagram, the term "Human exit" in each state's semantics referenced a concept with no diagram counterpart. "Pause exit" is consistent with the new cross-cutting pause rule in prose.

## What was deferred and why

- **Remove Fix (Option 2)**: Weak justification. Fix's routing judgment cost is low. Visible presence signals bounded remediation loop. Defer until real usage shows it causes routing confusion.
- **Phase-level only (Option 3)**: No evidence that current complexity is near the prompt-only routing limit. Loses verification ordering visibility. Defer until real usage evidence warrants it.

## Where to find the full reasoning

- `docs/cs-implement-plan/field-notes/state-diagram-simplification-proposal.md` — the proposal with all three options
- `docs/cs-implement-plan/field-notes/state-diagram-simplification-review.md` — the two-pass review with approval rationale

## What comes next

Evals are the planned approach for gathering evidence on whether the deferred simplifications are needed. The user will provide scenario signal; the agent builds the eval scaffolding. This is not yet started — direction only.

## Docs structure

This session also established `docs/{feature-name}/` as the convention:
- Planning artifacts (`spec.md`, `plan.md`, `hand-off.md`) at the feature root
- Working reasoning under `field-notes/`
