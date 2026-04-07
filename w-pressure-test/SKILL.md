---
name: w-pressure-test
description: Stress-test a codebase-local claim by defining what must be true, building the counter-case first, gathering evidence for both sides, and disclosing assumptions. Use when the user says "is this actually a gap?", "validate this independently", "pressure-test this", "are you sure?", "check this claim."
---

# Pressure Test

Validate whether a codebase-local claim holds under scrutiny. The user states a claim; your job is to try to break it before confirming it.

Use this for claims that can be evaluated from repository evidence such as source, tests, configuration, generated artifacts, wiring, or runtime setup in the repo. If the claim depends on production state, external systems, recent web facts, or behavior you cannot observe locally, say so and mark the result as partially verifiable or unverifiable.

<phase name="Restate">

<goal>
Restate the claim in your own words without the user's framing. Identify what must be true for the claim to hold.
</goal>

<constraints>
- Do not copy the user's phrasing. Rephrase from scratch.
- Do not state a position yet.
- List the concrete, verifiable conditions the claim depends on.
- If you do not yet know the relevant files, types, or methods, first do a minimal discovery pass to find them.
</constraints>

<procedure>
1. Restate the claim.
2. Identify the evidence modes needed to evaluate it: source, search, tests, configuration, generated code, or runtime wiring.
3. List each condition that must hold for the claim to be true. Each condition should name a file, type, method, config entry, test, or relationship that can be checked. If exact locations are not known yet, name the relationship to discover.
</procedure>

<gate>
- Claim restated without copying the user's words.
- At least one verifiable condition identified.
- Evidence mode chosen for the claim.
</gate>

</phase>

<phase name="Counter-case">

<goal>
Build the strongest argument that the claim is wrong. This phase runs before gathering supporting evidence. Construct the counter-case from reasoning first, then verify it.
</goal>

<budget>
- Prefer no more than 5 targeted evidence actions.
- An evidence action may be a repo search, a file read, a test run, or a config/runtime inspection.
- Each action must target a specific uncertainty.
</budget>

<constraints>
- You must produce at least one plausible counter-argument. If you genuinely cannot, explain why the claim is unfalsifiable and flag that to the user.
- Do not dismiss your own counter-arguments prematurely. Verify them against the codebase before discarding.
- State any assumptions you are making. For each, note whether it is verified, partially verified, or unverified.
</constraints>

<procedure>
1. Before gathering supporting evidence, write the strongest argument for why the claim is wrong.
2. Identify the smallest set of evidence actions needed to verify or refute that counter-argument.
3. Execute those actions. For each counter-point:

<evidence-against>
- **Claim condition being challenged**: (from Phase 1)
- **Evidence**: path:line, search result, test, or config/runtime observation
- **What you found**: (quote or paraphrase)
- **Why this matters**: explain how it weakens the claim
- **Status**: verified / partially verified / unverified
</evidence-against>

4. If a counter-argument collapsed, state exactly what disproved it.
</procedure>

<gate>
- At least one counter-argument constructed.
- Each counter-point either verified, partially verified, or explicitly marked unverified.
- If all counter-arguments collapsed, state what evidence disproved each one.
</gate>

</phase>

<phase name="Supporting case">

<goal>
Gather evidence that the claim IS correct.
</goal>

<budget>
- Prefer no more than 5 additional targeted evidence actions.
</budget>

<constraints>
- Reuse evidence from the counter-case phase where possible.
- Re-read a file if you need a distinct citation or a different part of the same file.
- For each supporting point, check whether any counter-evidence from Phase 2 weakens it.
</constraints>

<procedure>
For each condition from Phase 1:

<evidence-for>
- **Claim condition being supported**: (from Phase 1)
- **Evidence**: path:line, search result, test, or config/runtime observation
- **What you found**: (quote or paraphrase)
- **Why this matters**: explain how it supports the claim
- **Survives counter-evidence?**: yes / no / partly
</evidence-for>
</procedure>

<gate>
- Every condition from Phase 1 addressed — either supported with evidence, refuted by counter-evidence, or flagged as unverifiable.
</gate>

</phase>

<phase name="Verdict">

<goal>
State whether the claim holds, partially holds, or does not hold.
</goal>

<constraints>
- If any part of the verdict depends on evidence outside the repository that you cannot observe locally, the verdict must be `Unverifiable` or `Partially holds`, not `Holds`.
- If your verdict agrees with the claim, point to specific evidence that ruled out each surviving counter-argument. If you cannot, the verdict is "Unverifiable," not "Holds."
- If your verdict disagrees with the user's claim, state which evidence from Phase 2 survived and was not overturned by Phase 3.
- If the claim can be checked only in part, use "Partially holds" or "Unverifiable" instead of over-claiming.
- Never state a verdict without referencing evidence from both Phase 2 and Phase 3.
</constraints>

<procedure>
1. List surviving counter-arguments.
2. List surviving supporting evidence (not weakened in Phase 3).
3. State verdict: **Holds**, **Partially holds** (state what holds and what doesn't), **Does not hold**, or **Unverifiable**.
4. State remaining assumptions or blind spots.
5. One-paragraph summary in plain language.
</procedure>

<gate>
- Verdict references evidence from both phases.
- No counter-argument dismissed without citing what disproved it.
</gate>

</phase>
