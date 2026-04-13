---
artifact: design-rationale
title: cs-implement-plan Design Rationale
---

# cs-implement-plan Design Rationale

Living document. Updated in place when decisions change. Git history preserves the trail.

## Lineage

`cs-implement-plan` is derived from `w-implement-plan`. Both exist during the transition. Once `cs-implement-plan` is stable and no teething issues remain, `w-implement-plan` will be removed.

The structural delta from the baseline:

- Added a Mermaid state model as a routing reference alongside the phase/gate execution model
- Added state semantics (entry/exit contracts for each state)
- Added a deterministic verification policy with fixed ordering
- Added an output contract with explicit status vocabulary
- Added a delegation contract
- Added a stop conditions index
- Expanded budget discipline to cover fix loops explicitly

The baseline's core signal — artifact discipline, phase structure, implement-phase anti-spin constraints, budget ceilings — was preserved verbatim.

## Design decisions

### Phases are the execution driver, not the state model

The skill has two structural models: 5 phases (Intake, Scope, Implement, Verify, Closeout) and a Mermaid state diagram with more granular states. Early review found agents could stall trying to reconcile the two. The reconciliation rule is explicit: phases drive execution, the state model is a routing reference. `VerifyPlanned`, `VerifyBuild`, `VerifyTests`, and `Fix` are substeps inside the Verify phase.

### HumanInput is a cross-cutting pause, not a state

Originally modeled as a standalone Mermaid state with edges from Intake, Scope, Implement, and Fix. Removed because:

- The diagram couldn't model resume behavior honestly. `Fix → HumanInput` existed but no `HumanInput → Verify*` return edges existed — the prose had to patch this gap.
- Pause/resume is cross-cutting. Every state can pause when stop conditions require it. Modeling it as a state created routing edges that implied specific resume targets, but the actual resume target depends on context the diagram can't express.

After removal, "Human exit" in each state's semantics was renamed to "Pause exit" to stay consistent with the cross-cutting prose rule.

### Fix is kept as a visible state

`Fix` has 3 outgoing edges (return to VerifyPlanned, VerifyBuild, or VerifyTests) — all deterministic return-to-caller dispatch, not high routing-judgment branching. Its visible presence in the diagram signals that verification failures enter a bounded remediation loop rather than broad re-entry into implementation.

### Verification substates are kept

`VerifyPlanned → VerifyBuild → VerifyTests` makes the verification ordering visible and harder to skip. Collapsing them into prose within the Verify phase would trade scannable ordering for a complexity reduction that hasn't been shown to help.

### Scope classifies the verification stack upfront

Scope builds the verification stack (artifact-specified checks, repo-standard build, repo-standard test) and classifies each step's execution intent (`Run`, `Skip`, `Block pending clarification`). The Verify phase uses this classification rather than re-discovering commands. Override is allowed only if new information emerged during Implement.

### Fix-loop budget lives in one place

The budget section is the single authoritative source for the fix-loop limit (1 focused remediation per failed verification state). Other sections (stop conditions, verification policy, Fix state semantics) reference the budget rather than restating the number. This prevents drift when the limit changes.

### Output contract maps state exits to reporting terms

Closeout translates execution outcomes to output contract terms at point of use: successful completion → `Completed`, paused for user input → `Needs human input`, unresolved blocker → `Blocked`. Verification steps are reported as `Passed`, `Failed`, `Skipped`, or `Blocked`.

## Rejected alternatives

### Remove Fix from the diagram

Considered and deferred. Fix's routing judgment cost is low (deterministic dispatch). Its visible presence signals bounded remediation. Remove only if real usage shows it causes routing confusion.

### Collapse to phase-level diagram only

Considered and rejected. No evidence that current complexity is near the prompt-only routing limit. Loses verification ordering visibility. The phase-level diagram would be:

```
Intake → Scope → Implement → Verify → Closeout
```

with a `Verify → Implement` back-edge for remediation. This is cleaner but hides the `VerifyPlanned → VerifyBuild → VerifyTests` ordering that was deliberately added to make verification harder to skip.

## Open hypotheses

### Over-specification

`cs-implement-plan` is ~380 lines vs `w-implement-plan`'s ~184. The added structure is individually justified, but the combined surface area means an agent must parse more instruction before executing. If agent performance degrades compared to the baseline, over-specification is the first hypothesis to test. The question is whether added determinism outweighs added parsing cost.

### Verification substate value

The verification substates make ordering visible, but it hasn't been measured whether agents actually skip verification more often without them. Evals against real artifacts would answer this.

## Known minor issues

- **"inferred" vs "repo-standard" in Verification Policy.** SKILL.md line 152 says "Prefer artifact-specified commands over inferred commands" but every other section uses "repo-standard" for the same category. One-word fix: change "inferred" to "repo-standard."
- **Scope has no explicit budget.** Intake has a 3-action budget for artifact loading. Scope has no budget cap for verification stack discovery. In repos where build/test commands are not obvious, Scope could spend unbounded actions on discovery before implementation starts.

## Forward direction

The verification flow this skill asks the agent to follow manually is being mechanized by the pipeline orchestrator (`docs/pipeline-orchestrator/spec.md`). That orchestrator moves deterministic verification, retry budgets, and human decision gates out of the agent and into a typed pipeline. cs-implement-plan's verification states, fix-loop budget, and pause exits are the manual precursors to the pipeline's deterministic equivalents.

Evals are the planned approach for gathering evidence on whether the deferred simplifications (removing Fix, collapsing to phase-level) are needed. Not yet started. Constraints on the eval approach:

- The agent writes the evals, not the user. The user provides scenario signal (what realistic `hand-off.md` artifacts look like, what repo shapes matter).
- Complexity must scale linearly — observable from the outside, clear pass/fail.
- Minimal yak shaving. No manual checklist approach.
- What the evals need to probe: does Fix routing work (return-to-caller after verification failure), do verification substates prevent skipping (all three addressed in closeout), does pause/resume work (pause on ambiguity, resume to correct state), does verification ordering hold (Planned → Build → Tests).

## Review protocol

Structural reviews of this skill follow `docs/skill-review-protocol.md`. Key principle: assume conflicting routing or status semantics between sections is a bug unless proven otherwise.
