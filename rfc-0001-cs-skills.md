---
artifact: rfc
title: Experimental cs-* Skills for Deterministic, State-Aware Workflows
status: draft
created: 2026-04-10
---

# RFC 0001: Experimental `cs-*` Skills for Deterministic, State-Aware Workflows

## Summary

Introduce a parallel `cs-*` skill family as an experimental line beside the existing `w-*` skills.

The `cs-*` line preserves the strongest structural properties of the current skills, especially:

- phase-based execution
- explicit goals, procedures, and gates
- constraints and budgets
- artifact discipline
- evidence-oriented closeout

The `cs-*` line adds:

- clearer outer input and output contracts
- deterministic verification behavior where appropriate
- state-based routing for workflow-style skills
- tighter delegation contracts for any subagent use

The `w-*` skills remain the stable baseline during this experiment.

## Motivation

The current `w-*` skills already provide strong signal through explicit phase, gate, constraint, and budget structure.

There is still room to improve:

- input clarity
- output clarity
- deterministic verification steps after implementation
- explicit stop conditions
- delegation contracts
- workflow routing in multi-step execution skills

The goal is to improve determinism without losing the strengths of the current skills.

## Problem Statement

Today the skills are strong internally, but some workflow-oriented behaviors remain implicit:

- build and test verification may not be consistently enforced after implementation
- output shape is not always explicitly contracted
- delegation can still be too free-form
- multi-step skills can benefit from a stronger routing model

At the same time, over-borrowing from other systems risks creating conflicting control surfaces, duplicated semantics, or incoherent skill bodies.

This RFC defines a controlled way to experiment without rewriting the current skill set.

## Goals

- preserve the best structural signal from `w-*`
- add stronger outer contracts to workflow skills
- add deterministic verification sequencing where relevant
- use state-based modeling only where it improves execution clarity
- keep the experimental line coherent and standalone
- delay orchestration until the underlying experimental skills are proven

## Non-Goals

- replace the `w-*` skills immediately
- rewrite every skill at once
- introduce a top-level orchestrator first
- copy RP1-specific harness syntax or runtime assumptions
- add subagents everywhere by default
- force state diagrams into skills that are primarily analytical rather than workflow-driven

## Core Design Principles

### 1. Preserve Proven Internal Structure

The following are treated as high-value signal and should be preserved unless there is a clear reason to change them:

- `<phase>`
- `<goal>`
- `<procedure>`
- `<gate>`
- `<constraints>`
- `<budget>`
- artifact hierarchy and conflict rules
- explicit blocker surfacing
- evidence-oriented closeout

### 2. Add, Don't Replace

The `cs-*` line should add a stronger outer shell around the proven inner structure.

The default pattern is:

1. frontmatter
2. `When to Use`
3. `Inputs`
4. `Output Contract`
5. optional `State Model`
6. optional `State Semantics`
7. `Delegation Contract`
8. `Stop Conditions`
9. preserved phase structure
10. closeout mapping

### 3. One Authoritative Model Per Concern

To avoid structural drift:

- phases are the execution driver
- state models are routing references for workflow-style skills
- budgets are authoritative for numeric limits
- output contracts are authoritative for closeout vocabulary
- Mermaid diagrams must not introduce routes that contradict the written contracts

### 4. Use State Models Only Where There Is Real State

State modeling is appropriate when a skill has meaningful execution transitions, such as:

- intake
- scope
- implementation
- verification
- remediation
- human pause
- closeout

State modeling is not required for skills that are primarily analytical or judgment-based.

### 5. Deterministic Verification Must Be Explicit

For implementation-style skills, verification order should be fixed:

1. artifact-specified checks
2. repo-standard build command when clearly applicable
3. repo-standard test command when clearly applicable

The skill must not silently stop at "implemented" if required verification remains.

### 6. Delegation Must Narrow Scope, Not Expand It

Subagents, if used, should be bounded and contract-driven.

The parent skill remains responsible for:

- workflow ownership
- final judgment
- final closeout
- enforcing budgets and stop conditions

Subagents may be used for:

- bounded evidence gathering
- targeted verification
- narrow remediation tasks
- structured artifact checks

## Proposed Approach

### Stable Baseline

- keep `w-*` as the stable comparison set
- use them for current work unless a `cs-*` variant is intentionally being evaluated

### Experimental Line

- create parallel `cs-*` variants instead of rewriting `w-*`
- each `cs-*` skill must be coherent as a standalone document
- each `cs-*` skill should introduce one main improvement axis at a time

### Skill Categories

Workflow-heavy skills are the first candidates for `cs-*` treatment.

Initial priority:

1. `cs-implement-plan`
2. `cs-plan-a-feature`

Later candidates:

3. `cs-code-review`
4. `cs-plan-review`
5. `cs-pressure-test`
6. `cs-architecture-review`

## Initial Skill Template for `cs-*`

Each `cs-*` skill should follow this pattern where applicable:

- frontmatter
- `When to Use`
- `Inputs`
- `Output Contract`
- `State Model` if the skill has real workflow transitions
- `State Semantics` if state routing is introduced
- `Deterministic Verification Policy` if the skill performs execution checks
- `Delegation Contract`
- `Stop Conditions`
- preserved `<constraints>` and `<budget>`
- preserved `<phase>` structure
- explicit closeout mapping

## Rollout Plan

### Phase 1: `cs-implement-plan`

Purpose:

- test state-based routing on a workflow skill
- add deterministic build/test follow-through
- add an explicit output contract
- preserve the proven `w-implement-plan` phase structure

Success signals:

- less ambiguity about whether verification must run
- fewer skipped build/test steps without explicit justification
- cleaner closeout reporting
- no new structural contradictions between phases and states

### Phase 2: `cs-plan-a-feature`

Purpose:

- strengthen artifact contracts
- improve handoff clarity
- preserve planning rigor while making outputs more explicit

Success signals:

- higher-quality `spec.md`, `plan.md`, and `hand-off.md`
- cleaner downstream implementation intake
- less re-discovery during implementation

### Phase 3: Evaluate Review Skills

Only after the workflow skills feel stable.

Likely changes:

- stronger input and output contracts
- tighter evidence contracts
- possible bounded subagent roles for evidence gathering

State modeling is optional here and should be used sparingly.

### Phase 4: Consider Orchestrator

Do not introduce the outer orchestrator until:

- `cs-implement-plan` is stable across repeated use
- `cs-plan-a-feature` produces reliable artifacts
- verification behavior is trustworthy
- stop conditions are well understood
- closeout contracts are consistent

## Orchestrator Entry Criteria

The future orchestrator is allowed only when these conditions hold:

- the underlying `cs-*` skills are coherent standalone skills
- their inputs and outputs are explicit and stable
- their verification behavior is deterministic enough to compose
- human-input conditions are named and narrow
- there is confidence from real usage, not just design quality

## Risks

### Risk: Overlapping Control Surfaces

Adding state models on top of phases can create contradictions.

Mitigation:

- phases remain authoritative
- state model is declared secondary and routing-only
- every new `cs-*` skill is reviewed for routing contradictions

### Risk: Vocabulary Drift

Different sections may use different status labels.

Mitigation:

- one output contract vocabulary per skill
- explicit mapping from execution outcomes to closeout terms

### Risk: Over-Ambitious Scope

Trying to redesign everything at once will reduce coherence.

Mitigation:

- one parallel skill at a time
- one main improvement axis per pass
- defer orchestrator until later

### Risk: Subagent-Induced Drift

Delegation can make skills less deterministic if the subagent contract is loose.

Mitigation:

- narrow subagent roles only
- parent owns final judgment
- explicit delegation contract
- bounded expected output shapes

## Review Standard for New `cs-*` Skills

Every new `cs-*` skill should be reviewed against these questions:

- does it preserve the strongest signal from the matching `w-*` skill?
- is it coherent as a standalone skill?
- do the phases, states, budgets, and stop conditions agree?
- is there only one authoritative model for each concern?
- does the new structure improve determinism rather than merely add complexity?

## Decision

Proceed with the `cs-*` experimental line.

Start with `cs-implement-plan`.
Do not start with the outer orchestrator.
Use the `w-*` skills as the baseline.
Preserve the strongest structural properties of the existing skills.

## Open Questions

- How much state modeling is actually useful for `cs-plan-a-feature`?
- Which review skills, if any, truly benefit from state diagrams?
- When should explicit custom subagents be introduced?
- What usage threshold is sufficient before attempting the orchestrator?
