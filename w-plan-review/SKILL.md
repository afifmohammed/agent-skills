---
name: w-plan-review
description: Review a plan or design doc for a C# backend repository by checking feasibility, constraints, risks, compatibility, and validation strategy before implementation starts. Use when the user says "review the plan", "review this design", "pressure-test this proposal", "is this plan sound?", or "what is missing from this plan?"
---

# Plan Review

Review a plan before implementation. Focus on whether the proposal is correct, feasible, and complete enough to execute safely.

Use this for design docs, implementation plans, ADRs, and proposal markdown files. If the user is primarily asking about shipped code or a diff, use `w-code-review` instead. If the main question is subsystem boundaries or long-term system shape, use `w-architecture-review`.

## Inputs

Before starting, gather:

1. The artifact to review.
2. Any stated goals, non-goals, constraints, and success criteria.
3. The codebase areas the plan claims to touch.
4. Any repo-local review context if present, such as `docs/repo-review-context.md`, `docs/architecture/conventions.md`, or similar guidance.

<budget>
- Initial pass: prefer no more than 4 verification actions before returning a recommendation, top findings, and open uncertainties.
- Deep pass: only continue beyond the initial pass if the caller explicitly asks for more depth, or if a likely high-severity issue needs one more check to confirm.
- Prefer targeted verification actions over exhaustive reading.
- Spend the most effort on claims that would cause the most damage if wrong: breaking changes, invalid assumptions, migration gaps, incorrect boundaries, or operational risk.
- If a claim cannot be verified from the plan and repository evidence, flag it as `Unverifiable`.
</budget>

<constraints>
- If this review is delegated, start from the caller's brief. Do not re-discover the artifact, intent, linked context, or focus areas if they were already provided.
- Do not spend more than 1 discovery action looking for repo-local review guidance unless the caller named a specific file.
- Do not trust the plan's description of the current system without checking the codebase.
- Distinguish missing information from actual design flaws. If something may be fine but is not evidenced, mark it `Unverifiable` or `Concern` rather than overstating.
- Pressure-test the proposal before agreeing with it. Build the strongest plausible case against it first.
- Do not recommend amendments that you have not checked against repository facts or stated constraints.
- If repo-local review guidance exists, apply it as an overlay rather than replacing the method below.
- Do not expand the review beyond the decision under review. Avoid broad system critique unless it is directly relevant to the recommendation.
- If the initial pass already supports a clear recommendation, stop and return rather than broadening the review.
</constraints>

<phase name="Restate and Scope">

<goal>
Restate the proposal in neutral terms and identify the claims that must hold for the plan to work.
</goal>

<procedure>
1. Restate the proposal without copying the plan's framing.
2. List the key claims the plan makes about:
   - the current system
   - the intended change
   - the expected outcome
3. Identify the codebase areas and evidence sources needed to verify those claims.
4. Pick the smallest set of claims that must be checked to produce a useful initial recommendation.
</procedure>

<gate>
- Proposal restated neutrally.
- Key plan claims identified.
- Evidence sources identified.
- Minimal initial-pass verification scope identified.
</gate>

</phase>

<phase name="Counter-case">

<goal>
Build the strongest plausible case that the plan is unsound before gathering supporting evidence.
</goal>

<procedure>
1. Without endorsing the plan, write the strongest plausible argument against it.
2. Identify the smallest set of verification actions needed to test that counter-case.
3. Execute those checks and record which objections survive, collapse, or remain unverifiable.
4. If the initial pass already supports a clear recommendation, stop and return rather than broadening the review.
</procedure>

<gate>
- At least one plausible counter-case constructed.
- Surviving objections separated from disproved objections.
- Unverifiable objections flagged explicitly.
</gate>

</phase>

<phase name="Lens Review">

<goal>
Evaluate the plan through the required review lenses using repository evidence where possible.
</goal>

<procedure>
Assess each lens below and end each one with `Sound`, `Concern`, `Gap`, or `N/A`.
Use evidence already gathered in earlier phases where possible. Any additional verification actions for lens review still count against the shared skill budget.

### 1. Problem / Solution Fit

- Does the proposal solve the stated problem?
- Is the scope appropriate, or is it solving something adjacent?
- Is there a simpler approach that would achieve the same outcome?

### 2. Feasibility

- Can this be implemented with the existing codebase structure and dependencies?
- Does the plan rely on behavior, extension points, or APIs that do not appear to exist?
- Are important prerequisites missing?

### 3. Architecture and Boundaries

- Are responsibilities assigned to the right layer, project, or component?
- Does the proposal preserve sensible dependency direction?
- Does it introduce coupling that will be hard to unwind later?

### 4. Compatibility and Migration

- Are there source, binary, behavioral, configuration, or data compatibility risks?
- If behavior changes, is the migration path clear?
- Are versioning or rollout implications missing?

### 5. Operability

- Does the plan address configuration, observability, failure handling, and local development impact where relevant?
- Are operational assumptions explicit?

### 6. Validation Strategy

- Does the plan say how success will be verified?
- Are tests, diagnostics, or rollout checks sufficient for the risk level?
- Are important edge cases or failure modes missing?

### 7. Hidden Assumptions

- What must be true for the plan to work?
- Which assumptions are verified versus merely asserted?
</procedure>

<gate>
- Every lens assessed with a visible verdict.
- High-risk claims checked against repository evidence where possible.
- Unverifiable areas called out explicitly.
</gate>

</phase>

<phase name="Verdict">

<goal>
State whether the plan should be implemented as-is, implemented with amendments, or revisited.
</goal>

<procedure>
1. List the top findings first, ordered by severity.
2. List open questions and unverifiable claims.
3. State one recommendation:
   - `Implement as-is`
   - `Implement with amendments`
   - `Revisit design`
4. For each amendment you recommend:
   - state the amendment
   - state the repository fact or stated constraint you checked it against
   - state why it is compatible
5. End with a short plain-language summary.
6. If you stopped after the initial pass, say what deeper checks were intentionally deferred.
</procedure>

<gate>
- Recommendation supported by evidence from the counter-case and lens review.
- Amendments validated against repository facts or explicit constraints.
- Residual uncertainty stated explicitly.
- Deferred deeper work called out when applicable.
</gate>

</phase>
