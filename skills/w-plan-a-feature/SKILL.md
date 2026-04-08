---
name: w-plan-a-feature
description: Structured feature planning workflow that interviews the user, writes `spec.md`, `plan.md`, and `hand-off.md`, and runs an in-session review before handoff. Use when starting a new feature, designing a system change, or planning non-trivial work.
---

# Plan a Feature

This workflow turns a feature idea into three reviewed artifacts:

- `spec.md` - the `what` and `why`
- `plan.md` - the `how`
- `hand-off.md` - the execution handoff for `w-implement-plan`

This skill does not implement the feature. It ends when those artifacts are ready.

<constraints scope="global">
- These rules apply in every phase. If a phase adds a narrower rule, the phase-specific rule takes precedence for that phase.
- **Artifact directory**: before writing artifacts, determine one target directory for this feature's planning artifacts. If the user already provided one, use it. Otherwise derive it from an existing artifact path or ask once.
- **Artifact markers**: every generated artifact must begin with YAML frontmatter containing `artifact: spec`, `artifact: plan`, or `artifact: hand-off`. Include paths to the sibling artifacts when known.
- **Review is mandatory**: review the finished plan in this workflow. Do not write a review prompt or wait for the user to manage a separate session.
- **Review standard**: use `w-plan-review` as the review standard. If your environment supports delegation, you may delegate the review with a crisp brief; otherwise perform it directly. You still own the final decision and artifact updates.
- **Stop only for real blockers**: pause for the user only when requirements are unclear, scope needs a decision, a blocking unknown exceeds budget, or a review finding needs user arbitration.
- **No evidence, no claim**: if a factual statement matters to the plan, source it from code, user input, or clearly labeled inference.
- **No implementation prompting here**: `hand-off.md` is an execution artifact, not a prompt. Keep generic implementation behavior in `w-implement-plan`, not in this skill.
</constraints>

<phase name="Interview">

<goal>
Reach high confidence on what the user wants, why they want it, and what constraints matter before designing the solution.
</goal>

<constraints>
- Ask one question at a time by default. You may ask up to 3 tightly related questions in one turn only when that materially reduces back-and-forth and does not increase ambiguity.
- Do not propose technical solutions until the problem, success criteria, and constraints are clear enough to restate.
- Do not fill in important blanks yourself. If a load-bearing requirement is vague, ask a sharper follow-up.
- If you spot a tension between the request and what the codebase likely supports, surface it during the interview rather than hiding it in the plan.
</constraints>

<procedure>
1. Ask questions iteratively until you can restate:
   - the problem
   - the goals and non-goals
   - the success criteria
   - the main constraints
2. Before closing the phase:
   - list any assumptions the user made that you did not challenge
   - challenge them now if they are load-bearing, or mark them as low-impact assumptions
   - list any tensions between the request and likely codebase reality
3. Summarize the intended feature back to the user and ask whether the understanding is complete.
</procedure>

<gate>
- User confirms understanding is complete, or
- remaining ambiguity is explicitly listed as low-impact assumptions and the user accepts that framing.
</gate>

</phase>

<phase name="Spec">

<goal>
Write `spec.md` capturing the stable intent of the feature: what is being built and why.
</goal>

<constraints>
- `spec.md` is the source of truth for intent, not the implementation recipe.
- Keep technical design details out of the spec unless they are externally visible constraints.
- If the user did not provide an artifact directory, determine it before writing the file.
</constraints>

<procedure>
1. Create `spec.md` in the artifact directory with YAML frontmatter:
   - `artifact: spec`
   - `plan_path`
   - `hand_off_path`
2. Write the spec with these sections:
   - `Context`
   - `Problem`
   - `Goals`
   - `Non-goals`
   - `Constraints`
   - `Success criteria`
   - `Edge cases and acceptance notes`
3. Source every load-bearing requirement from the interview or from explicit repository facts.
</procedure>

<gate>
- `spec.md` written.
- Spec captures the `what` and `why` without drifting into implementation mechanics.
</gate>

</phase>

<phase name="Plan">

<goal>
Design the implementation approach and write `plan.md`.
</goal>

<budget>
- Initial exploration pass: max 4 verification actions before a mandatory checkpoint, counting file reads, searches, and agent launches together.
- Agent launches: max 2 in the initial pass, max 3 for the entire phase.
- Deep exploration: allowed only for unknowns explicitly classified as `blocks design` after the checkpoint.
- Follow-up reads after the checkpoint: max 3 targeted reads for blocking unknowns only.
- Verification reads after drafting the plan: max 3 to verify load-bearing claims.
- If still blocked after spending the budget on a blocking unknown: ask the user.
</budget>

<constraints>
- Every agent launch must include a structured brief containing:
  - feature summary in 1 to 2 sentences
  - the exact unknown being investigated
  - file paths, type names, and facts already established
  - approaches already tried that did not resolve the unknown
  - what not to re-discover or re-explore
  - the evidence budget
  Do not launch an agent without this brief. Before delegating, tell the user what is being delegated and what the sub-agent will focus on.
- Trust but spot-check. Treat delegated analysis as provisionally valid, but spot-check the most load-bearing returned facts before depending on them.
- Draft first, verify later. Write the design with assumptions marked, then verify the assumptions that actually matter.
- Design the approach yourself. Do not delegate plan writing.
- Stop when you have enough to draft. Do not keep exploring for completeness once the remaining unknowns are either non-blocking assumptions or user-answerable questions.
</constraints>

<procedure>
1. List the specific unknowns that remain after the interview and spec.
2. Spend the initial exploration budget on the highest-value unknowns only.
3. Run a mandatory checkpoint:
   - write down what you now know
   - re-evaluate the unknowns
   - classify each remaining unknown as `blocks design` or `draftable`
   - stop exploring if no unknown still blocks design
   - tell the user what is now known, what unknowns remain, and whether any unknown still blocks design
4. Design the approach. For each important decision, state the alternative you considered and why you rejected it.
5. Create `plan.md` in the artifact directory with YAML frontmatter:
   - `artifact: plan`
   - `spec_path`
   - `hand_off_path`
6. Write the plan with these sections:
   - `Context`
   - `Design rationale`
   - `Implementation steps`
   - `Compatibility and migration`
   - `Verification strategy`
   - `Assumptions and open questions`
7. Verify load-bearing claims and annotate each important assumption as:
   - code-verified
   - user-confirmed
   - inferred
   After verification, tell the user which claims were verified, which remain inferred, and whether any failed verification.
</procedure>

<gate>
- `plan.md` written.
- Load-bearing claims and assumptions are sourced.
- Exploration stopped at an explicit checkpoint rather than drifting indefinitely.
</gate>

</phase>

<phase name="Review">

<goal>
Review the plan against the spec and repository facts, amend it, and reach a ready-for-handoff state.
</goal>

<budget>
- One full review pass is mandatory.
- One confirmatory pass after amendments is allowed.
- If a likely high-severity issue needs one more verification step to confirm, spend it.
- If the review reveals a disputed scope or intent question, ask the user instead of looping.
</budget>

<constraints>
- Use `w-plan-review` as the review standard.
- Review the plan against both `spec.md` and the repository. The plan is not allowed to drift from the spec silently.
- Findings must be triaged as `accept`, `reject`, or `ask user`.
- If a finding changes intent, amend `spec.md` as well as `plan.md`.
- Do not produce a separate review prompt artifact.
</constraints>

<procedure>
1. If delegating to `w-plan-review`, the brief must include:
   - paths to `plan.md` and `spec.md`
   - the feature summary from the interview in 2 to 3 sentences
   - codebase areas and facts already verified during the Plan phase
   - the load-bearing assumptions from `plan.md` that most need verification
   - any user-stated focus areas or constraints for the review
   Tell the user what is being delegated and what the review will focus on.
   If performing the review directly instead of delegating, apply the `w-plan-review` methodology inline starting from `Restate and Scope`.
2. List the top findings first.
3. For each finding:
   - state the finding
   - state the evidence
   - decide `accept`, `reject`, or `ask user`
   - explain why
4. Amend `plan.md` for accepted findings.
5. Amend `spec.md` too if an accepted finding changes the intended behavior, scope, or success criteria.
6. If amendments were made, run one short confirmatory pass focused on the revised sections and accepted findings.
7. Add a `Review outcome` section to `plan.md` summarizing:
   - findings addressed
   - findings rejected
   - residual concerns or open questions
</procedure>

<gate>
- Mandatory review completed in-session.
- Accepted findings incorporated.
- Rejected findings or user-arbitration items stated explicitly.
- `plan.md` records the review outcome.
</gate>

</phase>

<phase name="Hand-off">

<goal>
Write `hand-off.md` as the primary execution artifact for `w-implement-plan`.
</goal>

<constraints>
- `hand-off.md` is an execution contract, not a generic prompt.
- Do not repeat the full contents of `spec.md` or `plan.md`. Reference them and extract only what the implementer needs at execution time.
- Keep fixed decisions explicit so the implementation skill knows what not to revisit.
- Make the handoff concrete enough that `w-implement-plan` can start from item 1 without re-reading the entire planning session. Name the likely starting files, types, tests, commands, and known risk surfaces when those are known.
</constraints>

<procedure>
1. Create `hand-off.md` in the artifact directory with YAML frontmatter:
   - `artifact: hand-off`
   - `spec_path`
   - `plan_path`
2. Write the hand-off with these sections:
   - `Execution scope`
   - `Inputs`
   - `Fixed decisions`
   - `Ordered worklist`
   - `Verification expectations`
   - `Watch-fors and risks`
   - `Unresolved items`
3. Make each section execution-facing:
   - `Execution scope`: what is in scope, what is out of scope, and any explicit sequencing boundaries
   - `Inputs`: sibling artifact paths, relevant repo-local guidance, likely starting files, types, tests, commands, and any user constraints the implementer must honor
   - `Fixed decisions`: decisions that must not be re-opened during implementation unless they conflict with code reality
   - `Ordered worklist`: concrete implementation tasks in execution order, with touched surfaces or dependencies when known
   - `Verification expectations`: the checks to run, what success looks like, and what to do if verification cannot be completed
   - `Watch-fors and risks`: hazards tied to specific surfaces or steps, not generic warnings
   - `Unresolved items`: genuine open questions, assumptions to preserve, and which ones should trigger escalation
4. Ensure `hand-off.md` is sufficient for `w-implement-plan` to begin without re-reading the entire planning conversation.
</procedure>

<gate>
- `hand-off.md` written.
- `hand-off.md` references both `spec.md` and `plan.md`.
- The handoff is ready for `w-implement-plan`.
</gate>

</phase>

## Artifacts

All artifacts live in the chosen artifact directory:

| File | Purpose |
|------|---------|
| `spec.md` | Stable source of truth for the feature's `what` and `why` |
| `plan.md` | Reviewed implementation approach and review outcome |
| `hand-off.md` | Primary execution handoff for `w-implement-plan` |
