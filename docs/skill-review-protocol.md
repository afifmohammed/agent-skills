---
artifact: reference
title: Skill Review Protocol
created: 2026-04-13
status: draft
---

# Skill Review Protocol

A reusable protocol for reviewing agent skill files for structural coherence. Derived from the first structural review of `cs-implement-plan` against `w-implement-plan`.

## When to use

Use this when reviewing a skill file (SKILL.md) with a code-review mindset — not for prose style or elegance, but for agent clarity, determinism, and internal coherence.

## Review focus

1. Does the skill remain cohesive and coherent as a standalone document to an agent or reader who does not know how it was derived?
2. Are there conflicting control surfaces between:
   - any state or flow model (e.g. Mermaid diagrams)
   - written state or phase contracts
   - the phase/gate flow
   - the verification policy
   - the closeout contract
3. Are there places where the skill introduces:
   - loop risk
   - ambiguous resume behavior
   - duplicate or conflicting status vocabularies
   - vague discovery work
   - instructions that are individually reasonable but collectively muddy
4. Does added structure genuinely improve determinism, or does it add a second competing model of execution?

## Operating assumption

Assume that any place where two sections give different routing or status semantics is a likely bug unless proven otherwise.

## Output shape

1. Findings first, ordered by severity.
2. For each finding:
   - concise title
   - exact file/line evidence
   - why this could confuse the agent or cause spin
   - classification: contradiction, ambiguity, duplication, or drift
3. Then:
   - "What still works well" — signal that should be preserved
   - "Minimal cleanup pass" — smallest changes that restore coherence
4. If no material issues exist, say so explicitly and state any residual risks.

## Constraints

- Do not review as prose style.
- Do not optimize for elegance.
- Optimize for agent clarity, determinism, and internal coherence.
- Be skeptical of borrowed structure that duplicates an existing control mechanism.
- Prefer identifying the smallest changes that would restore coherence over suggesting broad rewrites.
- Treat the baseline (if one exists) as the source of proven signal.
