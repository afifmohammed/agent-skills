---
name: w-implement-plan
description: Implement a reviewed feature from `hand-off.md` or `plan.md` by identifying the artifact type, loading the referenced planning artifacts, executing the work, and verifying the result. Use when the user says "implement the plan", "execute this hand-off", "build from this plan", or "carry out this reviewed feature."
---

# Implement Plan

Implement a feature from planning artifacts. Prefer `hand-off.md`, accept `plan.md`, and use `spec.md` as intent context.

`hand-off.md` is the preferred entry point because it is the execution-facing contract. `plan.md` is an acceptable fallback. `spec.md` alone is usually insufficient to implement safely.

<constraints scope="global">
- Prefer explicit artifact identity over inference. Use YAML frontmatter `artifact: hand-off|plan|spec` first, filename second, and content heuristics only as a fallback.
- `hand-off.md` is the primary execution contract. `plan.md` describes the implementation approach. `spec.md` defines the intended behavior. If they conflict, do not guess: `spec.md` wins on intent, `plan.md` wins on implementation approach, and `hand-off.md` wins on execution priority and focus.
- Do not revisit fixed decisions from `hand-off.md` unless the artifacts conflict or the codebase makes the decision impossible to implement as written.
- If required implementation context is missing, ask or stop. Do not silently invent requirements.
- If you delegate implementation or verification subwork, brief the sub-agent with the current work item, relevant artifact excerpts, fixed decisions, files already checked, any known risks, and the evidence budget. Do not make the sub-agent rediscover the artifacts.
</constraints>

## Inputs

Before starting, gather:

1. The primary artifact path or text the user supplied.
2. Any explicit scope limits or focus areas from the user.
3. Any referenced sibling artifacts.
4. Any repo-local implementation guidance if the artifact points to it.

<budget>
- Intake: max 3 verification actions to identify the artifact type and load required sibling artifacts.
- Execution: follow the implementation steps and only read outward where the artifacts leave a necessary gap.
- If a step requires facts not present in the artifacts: max 3 targeted verification actions to resolve that step before surfacing a blocker.
</budget>

<phase name="Intake">

<goal>
Identify the input artifact and establish the execution contract.
</goal>

<procedure>
1. If the user supplied a file path, inspect that file first.
2. Determine artifact type in this order:
   - YAML frontmatter `artifact`
   - filename (`hand-off.md`, `plan.md`, `spec.md`)
   - content structure
3. Apply the entry rules:
   - If `artifact: hand-off`, use it as the primary contract and load referenced `plan.md` and `spec.md`.
   - If `artifact: plan`, use it as the primary contract, load referenced `spec.md`, and load `hand-off.md` if present.
   - If `artifact: spec` only, stop and ask for `plan.md` or `hand-off.md` unless the user explicitly wants you to derive an implementation plan first.
   - If the input is unstructured text, ask for the missing artifact or a concrete path unless the user clearly wants ad hoc implementation.
4. Record which artifact is primary and what supporting artifacts were loaded.
5. If the primary artifact is `hand-off.md`, verify it contains these expected sections:
   - `Execution scope`
   - `Inputs`
   - `Fixed decisions`
   - `Ordered worklist`
   - `Verification expectations`
   - `Watch-fors and risks`
   - `Unresolved items`
   Flag any missing sections before proceeding. Missing sections are a risk to manage, not a reason to silently skip them.
</procedure>

<gate>
- Primary artifact type identified.
- Required supporting artifacts loaded or explicitly found missing.
- Execution contract established before coding begins.
</gate>

</phase>

<phase name="Scope">

<goal>
Translate the planning artifacts into an execution-ready work boundary.
</goal>

<procedure>
1. From `hand-off.md` or `plan.md`, extract and record:
   - execution scope
   - inputs
   - fixed decisions
   - ordered worklist
   - watch-fors and risks
   - verification expectations
   - unresolved items
2. If you entered through `plan.md` and there is no `hand-off.md`, derive a minimal execution checklist and state any assumptions you had to make.
3. Identify the smallest set of files, types, and tests needed to start implementation.
</procedure>

<gate>
- Execution scope identified.
- Fixed decisions identified.
- Starting file/type/test set identified.
</gate>

</phase>

<phase name="Implement">

<goal>
Execute the reviewed plan without drifting from the artifacts.
</goal>

<constraints>
- Follow `hand-off.md` when present. When absent, follow `plan.md` conservatively.
- Do not improvise across scope boundaries.
- If you encounter an ambiguity or want to deviate from the plan:
  - state what you already know
  - assess whether the deviation is compatible with the artifacts
  - decide, or surface the blocker instead of guessing
- Before executing a worklist item that touches a surface flagged in `Watch-fors and risks`, re-read that risk entry and decide whether it applies to the current change. If it does, state how you are mitigating it.
- Surface progress at natural work boundaries for multi-step implementation, typically after a completed worklist item, before delegation, or when shifting to verification. Keep the update brief: what was done, what is next, and whether anything is blocked.
- If a single worklist item takes 5 consecutive tool actions without reaching a natural progress boundary, give a brief status update before continuing. State what you are doing, why the item is taking longer than usual, and what remains.
- If you spend 3 consecutive exploration or verification actions on the same unresolved worklist item without closing the question, stop and tell the user what is blocking progress, what you already checked, and whether you can continue autonomously.
</constraints>

<procedure>
1. Execute the work in the artifact order.
2. Re-read the relevant artifact section before changing direction.
3. If a step depends on a missing fact, spend the targeted step budget to resolve it.
4. If still unclear after the step budget, stop and surface the blocker.
</procedure>

<gate>
- Planned implementation work completed, or
- blocker surfaced with the exact missing fact or decision.
</gate>

</phase>

<phase name="Verify">

<goal>
Verify the implementation against the artifacts and repository behavior.
</goal>

<budget>
- Run the planned verification steps once each unless an in-scope fix requires re-running a directly affected step.
- If a verification step fails, surface the failure promptly instead of investigating silently.
- After surfacing a failure, spend at most 2 targeted diagnostic reads before deciding whether the issue is an in-scope fix, a deviation to report, or a blocker to escalate.
</budget>

<constraints>
- Before starting verification, tell the user which verification steps you are about to run when there is more than one meaningful step.
- After verification, summarize which steps passed, which failed, and any residual risks or skipped checks.
- If a verification failure clearly points to an in-scope fix, you may fix it and re-run the directly affected verification step. Do not drift into an unplanned debug loop.
</constraints>

<procedure>
1. Run the verification steps called for by `hand-off.md` or `plan.md`.
2. Check that the implementation still matches the intent in `spec.md`.
3. Record any deviations, missing tests, or residual risks.
</procedure>

<gate>
- Verification executed or explicit verification blocker stated.
- Deviations from the artifacts, if any, surfaced explicitly.
</gate>

</phase>

<phase name="Closeout">

<goal>
Report implementation status in terms of the planning artifacts.
</goal>

<procedure>
1. Summarize what was implemented.
2. State whether the implementation matches:
   - `hand-off.md`
   - `plan.md`
   - `spec.md`
3. List any deviations, blockers, or follow-up work.
</procedure>

<gate>
- Final status reported against the planning artifacts.
- Any deviation or blocker stated explicitly.
</gate>

</phase>
