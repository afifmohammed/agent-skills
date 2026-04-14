---
artifact: design-rationale
title: w-plan-a-feature Design Rationale
created: 2026-04-13
status: draft
---

# w-plan-a-feature Design Rationale

Living document. Updated in place as the planning-skill hypothesis changes. Git history preserves the trail.

## Context

This document captures observed signal about `w-plan-a-feature` before changing the skill itself.

The current focus is the period after the interview concludes and before a reviewed plan is ready for implementation. The goal is to preserve what was observed in real runs, separate that from inference, and avoid treating early hypotheses as settled design conclusions.

## Observed signal

From the session evidence gathered so far:

- The main bottleneck in the cited run was the Plan phase, especially broad research and alternative exploration before checking whether the conversation and codebase already contained enough context to draft.
- Existing context from the interview and conversation was not being treated as the default starting point for later actions.
- Expensive actions were budgeted by count, but not strongly gated by relevance or by a requirement to justify why the action was needed.
- Delegation widened the search space instead of consistently answering one bounded unknown.
- Asking the user appears to have been treated as more expensive than it should have been in cases where the user was likely the fastest authoritative source.
- The codebase and conversation reportedly already held answers that were still searched for through slower paths.

## Revised hypothesis

The current best explanation is not just "context was lost."

The stronger hypothesis is:

- the workflow does not force the planner to prove it needs more context before spending effort to get it
- the workflow does not strongly prefer the cheapest authoritative source
- delegation can happen before the parent agent has externalized what is already known and what exact gap remains

Under this hypothesis, phase-to-phase context carry is still part of the problem, but it is not the whole problem. The larger failure mode is weak pre-action justification: repo reads, web research, and sub-agent launches can still happen even when the existing conversation and code context are already sufficient to draft.

## What this evidence strengthens

- The case for a stronger "what I already know" checkpoint before exploration or delegation.
- The case for budget gates that require justification, not just action counts.
- The case for a stricter source hierarchy:
  - conversation and interview context first
  - repository evidence second
  - user question when the user is likely authoritative and the search path is expensive or uncertain
  - broader research last
- The case for tighter sub-agent escape hatches so a bounded unknown returns early instead of widening into rediscovery.

## What this evidence weakens

- The claim that missing top-level repo context was the primary bottleneck in this run.
- The claim that the main failure was only in the Review phase.
- The claim that phase-to-phase context loss alone explains the observed waste.

## What remains unproven

- Whether the skill wording was itself insufficient, or whether the main issue was execution discipline against already reasonable instructions.
- Whether the root waste came more from parent-agent choices or from sub-agent behavior after delegation.
- Whether a state model is the right primary intervention for this problem.
- Whether the actual planning artifacts from the run successfully externalized interview findings or left them trapped in conversation context.

## Open questions

- What did the actual sub-agent briefs contain, and where did they allow rediscovery or widening?
- How much time was spent on repo re-reading, web research, and review re-litigation respectively?
- Did the plan artifact clearly distinguish `user-confirmed`, `code-verified`, and `inferred` claims?
- Was there an obvious point where asking the user would have been the cheaper authoritative move?
- Are the most effective fixes structural, instructional, or both?

## Forward direction

Do not change `w-plan-a-feature` yet on the basis of this document alone.

Use this as a holding place for:

- additional evidence that confirms or contradicts the current hypothesis
- competing explanations
- draft structural interventions worth testing later

The current posture is exploratory and evidence-led, not yet prescriptive.
