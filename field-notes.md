---
artifact: field-notes
title: Session Notes for cs-* Skill Experiment
created: 2026-04-10
---

# Field Notes

These notes capture session-specific conclusions and operating heuristics that are useful in follow-up work but do not belong in the RFC.

## Current State

- `w-*` remains the stable baseline.
- `cs-*` is the experimental line.
- `cs-implement-plan` is the first experimental skill and has already gone through two structural review passes.
- The latest review concluded that no material structural issues remain in `cs-implement-plan`; only minor language and edge-case clarifications were required.
- The outer orchestrator is intentionally deferred until the underlying `cs-*` skills are proven in real use.

## Why `cs-*` Exists

- The goal is not to replace the strong internal structure of `w-*`.
- The goal is to preserve the best signal from `w-*` and add a stronger outer contract:
  - clearer inputs
  - clearer outputs
  - deterministic verification
  - explicit stop conditions
  - bounded delegation
  - state-based routing where there is real workflow state

## Preserved Invariants from `w-*`

These should be treated as high-value and preserved by default in future `cs-*` skills:

- `<phase>`
- `<goal>`
- `<procedure>`
- `<gate>`
- `<constraints>`
- `<budget>`
- artifact hierarchy and conflict rules
- blocker surfacing instead of guessing
- evidence-oriented closeout

If a future `cs-*` draft weakens one of these, assume that is a regression unless there is a strong reason.

## What We Learned About Borrowing from RP1

- Borrow the contract structure, not the whole style.
- Good things to borrow:
  - explicit `Inputs`
  - explicit `Output Contract`
  - state diagrams for real workflows
  - deterministic verification sequencing
  - explicit stop conditions
  - companion templates/references where bulk structure is repetitive
- Things not to borrow blindly:
  - harness-specific syntax
  - extra structure that duplicates an existing control mechanism
  - workflow/state machinery inside skills that are mostly analytical

## State Model Guidance

- Use state diagrams only for skills with real execution transitions.
- Phases are authoritative.
- State diagrams are routing references unless explicitly stated otherwise.
- Mermaid must never contradict:
  - the phase flow
  - the written state semantics
  - the verification policy
  - the closeout contract

When reviewing a stateful skill, treat any mismatch between those surfaces as a likely bug.

## Review Heuristic That Worked Well

The most useful review lens in this session was:

- compare the `cs-*` skill directly against the matching `w-*` baseline
- review with a code-review mindset, not a prose-style mindset
- look specifically for:
  - conflicting control surfaces
  - duplicate status vocabularies
  - ambiguous resume paths
  - hidden loop triggers
  - vague discovery work
  - places where borrowed structure duplicates existing structure without adding control

Helpful reviewer assumption:

- Any place where two sections give different routing or status semantics is a likely bug unless proven otherwise.

## Useful Review Prompt Shape

When re-reviewing a `cs-*` skill from another session, ask for:

- findings first
- exact file/line evidence
- why the issue could confuse the agent or cause spin
- classification as contradiction, ambiguity, duplication, or drift
- a short section for:
  - what still works well
  - minimal cleanup pass

The key is to review for agent clarity and determinism, not elegance.

## Delegation / Subagent Conclusions

- Explicit custom subagents are promising, but only later and only for bounded roles.
- Subagents should narrow responsibility, not widen it.
- Parent skill must still own:
  - workflow
  - final judgment
  - closeout
  - budgets and stop conditions
- Candidate future roles:
  - `surface-mapper`
  - `claim-verifier`
  - `artifact-auditor`
  - `risk-checker`

Do not introduce them just because the architecture allows it. Add them only when a real delegation seam is repeatedly fuzzy in practice.

## Current Status of `cs-implement-plan`

The skill currently includes:

- explicit `Inputs`
- explicit `Output Contract`
- explicit `State Model`
- `State Semantics`
- `Deterministic Verification Policy`
- `Delegation Contract`
- `Stop Conditions`
- preserved `Intake / Scope / Implement / Verify / Closeout` phase structure from `w-implement-plan`

Important design choices already made:

- phases are the execution driver
- state model is secondary and routing-oriented
- verification order is:
  1. planned checks
  2. repo-standard build
  3. repo-standard tests
- fix-loop limit is budget-driven
- closeout explicitly maps execution outcomes to output-contract terms

## What Not to Do Next

- Do not start with the outer orchestrator.
- Do not rewrite all `w-*` skills into `cs-*` variants in one pass.
- Do not force state diagrams into review-only skills unless there is a real workflow need.
- Do not expand `cs-implement-plan` again before using it on real artifacts.

## Recommended Next Steps

1. Use `cs-implement-plan` on real `hand-off.md` / `plan.md` inputs.
2. Observe whether the added structure helps or causes friction.
3. Only after that, draft `cs-plan-a-feature`.
4. Revisit explicit custom subagents only after at least one more `cs-*` skill exists and a delegation seam actually hurts.
5. Consider the orchestrator only after both planning and implementation experimental skills are stable in repeated use.

## Questions to Re-Ask in a Future Session

- Did `cs-implement-plan` actually improve determinism in real runs?
- Did the extra structure slow the agent down or improve its reliability?
- Is `cs-plan-a-feature` the right next skill, or did real use reveal a different priority?
- Are there recurring delegation problems that justify a bounded custom subagent?
- Are any parts of `cs-implement-plan` over-specified and removable without losing control?

## Session Bootstrap for Future Work

If context is tight in a future session:

1. Read `rfc-0001-cs-skills.md`
2. Read this `field-notes.md`
3. Compare `skills/w-implement-plan/SKILL.md` to `skills/cs-implement-plan/SKILL.md`
4. Treat `w-*` as baseline and `cs-*` as experimental
5. Optimize for coherence and determinism, not novelty
