---
name: w-code-review
description: Review C# backend code changes with a diff-first method focused on bugs, regressions, compatibility risks, design drift, and missing tests. Use when the user says "review the code", "review the changes", "code review", "review this diff", or "re-review."
---

# Code Review

Review an implementation, not just the intention behind it. Start from the change set, verify behavior against surrounding code, and prioritize actionable findings over broad commentary.

Use this for diffs, pull requests, branches, uncommitted changes, or specific source files. If the user is asking whether a plan is sound before coding starts, use `w-plan-review`. If the main question is architectural fit or subsystem boundaries, use `w-architecture-review`.

## Inputs

Before starting, gather:

1. The diff, branch, file list, or implementation to review.
2. Any linked plan, proposal, or issue that defines intended behavior.
3. Any user-supplied focus areas.
4. Any repo-local review context if present, such as `docs/repo-review-context.md`, `docs/architecture/conventions.md`, or similar guidance.

<budget>
- Initial pass: prefer no more than 4 verification actions before returning the top findings, key uncertainties, and whether deeper review is warranted.
- Deep pass: only continue beyond the initial pass if the caller explicitly asks for deeper review, or if one more check is needed to confirm a likely high-severity finding.
- Start from the diff and expand outward only where needed to verify impact.
- Prefer targeted verification actions over broad codebase tours.
- If a claim cannot be verified with reasonable effort, flag it as `Unverifiable`.
</budget>

<constraints>
- If this review is delegated, start from the caller's brief. Do not re-discover the diff, artifact, linked plan, or focus areas if they were already provided.
- Do not spend more than 1 discovery action looking for repo-local review guidance unless the caller named a specific file.
- Findings are the primary output. Do not pad the review with low-signal commentary.
- Prioritize bugs, regressions, compatibility risks, and missing validation over style notes.
- Do not infer safety from the diff alone. Verify suspicious or high-impact behavior against surrounding code.
- If you propose a fix, check it against the surrounding codebase facts before recommending it.
- If repo-local review guidance exists, apply it as an overlay rather than replacing the method below.
- Do not turn a code review into a whole-repo audit. Stay anchored to the changed surfaces and expand only as needed to verify impact.
- If you already have enough evidence for 1 to 3 material findings, stop and return rather than chasing completeness.
</constraints>

<phase name="Scope">

<goal>
Establish what changed, what behavior is affected, and what evidence must be checked.
</goal>

<procedure>
1. Start with the diff or changed files.
2. Identify the behavioral surfaces affected by the change:
   - callers
   - registrations and wiring
   - contracts and serialization
   - persistence and configuration
   - tests
3. Note any claimed intent from a linked plan, issue, or commit context.
4. Choose the smallest set of surfaces that must be checked to produce a useful initial-pass review.
</procedure>

<gate>
- Review starts from the actual change set.
- Affected behavioral surfaces identified.
- Claimed intent recorded if available.
- Minimal initial-pass verification scope identified.
</gate>

</phase>

<phase name="Verification">

<goal>
Verify the highest-risk behaviors before forming conclusions.
</goal>

<procedure>
1. Check the most suspicious or high-impact claims against surrounding code.
2. For each important observation, record:

<evidence>
- **Finding area**: correctness / regression / compatibility / runtime / design / validation
- **Evidence**: path:line, diff hunk, call site, test, configuration, or runtime wiring
- **What exists**: quote or paraphrase
- **Why it matters**: one sentence
- **Status**: verified / partially verified / unverifiable
</evidence>

3. If an initial concern collapses after verification, note what disproved it rather than silently dropping it.
4. If the initial pass already yields materially useful findings, stop and return rather than widening the search.
</procedure>

<gate>
- High-risk observations checked against evidence.
- Evidence recorded for each surviving finding.
- Collapsed concerns accounted for explicitly.
</gate>

</phase>

<phase name="Lens Review">

<goal>
Evaluate the implementation through the relevant review lenses.
</goal>

<procedure>
Assess the lenses below. Use `Sound`, `Concern`, `Gap`, or `N/A`.
Use evidence already gathered in earlier phases where possible. Any additional verification actions for lens review still count against the shared skill budget.

### 1. Correctness

- Does the code do what the change appears to intend?
- Are there logic errors, edge cases, or incorrect assumptions?

### 2. Regression Risk

- Could existing behavior break even if the new code compiles?
- Are call sites, defaults, serialization behavior, or runtime wiring affected?

### 3. Compatibility

- Are there source, binary, behavioral, configuration, or data contract changes?
- If this is a package or shared component, does the change alter public API expectations?

### 4. Lifecycle and Runtime Behavior

- Are DI lifetimes, disposal, async behavior, cancellation, retries, and resource ownership correct where relevant?
- Does the change introduce runtime-only failure modes?

### 5. Design Drift

- Does the implementation fit the surrounding abstractions and patterns?
- Is responsibility landing in the right place, or is the change forcing unrelated concerns together?

### 6. Validation

- Are tests, diagnostics, or safeguards sufficient for the risk level of the change?
- Is important behavior left untested or unverifiable?
</procedure>

<gate>
- Relevant lenses assessed with visible verdicts.
- Findings anchored in verified evidence where possible.
- Unverifiable risks called out explicitly.
</gate>

</phase>

<phase name="Verdict">

<goal>
Produce a findings-first review with clear severity and residual risk.
</goal>

<procedure>
1. List findings first, ordered by severity.
2. Return at most the top 5 findings by default unless the caller asked for exhaustive review.
3. For each finding, include:
   - a concise title
   - file and line evidence where possible
   - why it matters
   - likely impact
4. List open questions or unverifiable claims.
5. State whether a deeper pass is warranted or intentionally deferred.
6. Give a short change summary only if it helps contextualize the findings.
7. If there are no findings, say so explicitly and mention any residual risk or testing gap.
</procedure>

<gate>
- Findings appear before summary commentary.
- Each finding is evidenced or marked unverifiable.
- Residual risk stated even when no concrete bug is found.
- Deeper review explicitly recommended or deferred.
</gate>

</phase>
