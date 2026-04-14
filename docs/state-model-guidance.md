---
artifact: reference
title: State Model Guidance
created: 2026-04-13
status: draft
---

# State Model Guidance

A reusable guide for deciding whether a skill should use a state model and how to review one for agent clarity and determinism.

This is a draft reference, not settled doctrine. It captures working heuristics derived from the repository's `cs-implement-plan` design work, RFC guidance, and later discussion about state-model fit for planning workflows.

## When to use

Use this when designing or reviewing a workflow-style skill and deciding whether a Mermaid state diagram will materially improve execution behavior.

Do not use this as a prose-style guide. The question is not whether a diagram looks elegant. The question is whether it improves routing clarity, determinism, and honest control flow.

## Role

The state model has one job: make important routing and ordering visible.

It is not the execution driver and it is not the full contract for the skill.

- Phases are authoritative for execution flow.
- State models are routing references unless explicitly stated otherwise.
- Budgets are authoritative for numeric limits.
- Output contracts are authoritative for closeout vocabulary.
- The state model should expose control behavior that would otherwise be easy to skip, muddle, or reopen.

If the state model contradicts prose, budgets, or closeout behavior, treat that as a likely bug.

## Fit test

Use a state model only when it adds control signal that the phase structure alone does not carry well.

Good indicators:

- ordered stages that are easy to skip if left implicit
- bounded remediation loops
- deterministic return-to-caller routing
- explicit stop or escalation points
- resume behavior that can be stated honestly
- delegation that benefits from carrying a `current state`

Disqualifiers:

- the skill is primarily analytical, review-oriented, or judgment-based rather than workflow-driven
- the diagram would only restate the phase flow
- the interesting behavior is cross-cutting rather than state-specific
- resume targets depend on context the diagram cannot represent honestly
- transitions depend on broad judgment rather than a small routing rule
- the diagram would create a second competing model of execution

Common trap:

- a standalone `HumanInput` or equivalent state when the real behavior is "pause anywhere, then resume from the originating state unless scope changed materially"

Before adding a state model, answer these questions:

1. What execution mistake becomes harder if the diagram exists?
2. Which states are real control points rather than labels for concepts already covered by phases?
3. Can each edge be stated honestly without hidden resume rules?
4. Does each state have matching prose semantics and procedure support?
5. Does the diagram reduce ambiguity more than it increases surface area?
6. If the diagram were removed, what important ordering or bounded loop would become easier to skip?
7. If delegation occurs, does passing `current state` narrow the task instead of broadening it?

If these questions cannot be answered concretely, the burden of proof is against adding the diagram.

## Modeling rules

If a skill passes the fit test, keep the model narrow and honest.

What belongs in the diagram:

- states with a clear entry condition
- states with a distinct action set
- states with a small number of honest exits
- fixed ordering that matters operationally
- bounded retry or fix loops
- deterministic dispatch back to a prior verification or execution point

What stays in prose:

- cross-cutting pause and resume rules
- detailed budgets and evidence limits
- nuanced escalation criteria
- artifact precedence and conflict resolution
- detailed verification rules
- anything whose truthful routing would require many context-dependent edges

For every state kept in the diagram, the prose should define at least:

- entry
- actions
- success exit
- pause exit

If prose has to patch a routing lie, simplify the diagram rather than documenting around it.

## Review heuristics

When reviewing an existing state model, look for:

- conflicts between phases and the diagram
- conflicts between the diagram and written state semantics
- conflicts between the diagram and budgets or stop conditions
- conflicts between the diagram and closeout vocabulary
- routing gaps patched later in prose
- ambiguous resume behavior
- broad back-edges that permit uncontrolled re-entry
- duplicated or competing status vocabularies
- states whose removal would not reduce real control

Treat any mismatch between those surfaces as a likely structural bug unless proven otherwise.
