---
name: w-architecture-review
description: Review the architecture of a C# backend plan or implementation by evaluating boundaries, dependency direction, system shape, extensibility, and operational fit. Use when the user says "review the architecture", "does this design fit the system?", "are these boundaries right?", or "is this the right shape?"
---

# Architecture Review

Review whether a design or implementation fits the system well over time. Focus on boundaries, responsibilities, coupling, extension points, and long-term maintainability more than line-by-line correctness.

Use this for architecture proposals, subsystem refactors, cross-project changes, dependency questions, or implementations where the main risk is structural. If the user mostly wants a plan sanity check, use `w-plan-review`. If they mostly want a diff-level implementation review, use `w-code-review`.

## Inputs

Before starting, gather:

1. The plan, diff, files, or subsystem under review.
2. The projects, layers, or components affected.
3. The expected direction of dependencies and ownership boundaries.
4. Any repo-local review context if present, such as `docs/repo-review-context.md`, `docs/architecture/conventions.md`, or similar guidance.

<budget>
- Initial pass: prefer no more than 4 verification actions before returning the top structural findings, key uncertainties, and whether deeper review is warranted.
- Deep pass: only continue beyond the initial pass if the caller explicitly asks for more depth, or if one more check is needed to confirm a likely high-severity structural issue.
- Prefer a few high-signal verification actions over broad exploration.
- Verify the boundary and dependency claims that most affect long-term maintainability.
- If repository evidence is insufficient, mark the claim `Unverifiable`.
</budget>

<constraints>
- If this review is delegated, require a structured brief containing:
  - the exact boundary, dependency, or architecture question
  - the plan, diff, files, or subsystem under review
  - the projects, layers, or components believed to be affected
  - the expected dependency direction or ownership boundary
  - facts already verified by the caller
  - the structural risks or uncertainties that most need checking
  - what not to re-discover or broaden into
  - the evidence budget and expected output
  Start from that brief. If one item is missing, note the gap and proceed conservatively rather than silently re-discovering the whole context. Do not re-discover the artifact, subsystem, boundary question, or focus areas if they were already provided.
- Do not spend more than 1 discovery action looking for repo-local review guidance unless the caller named a specific file.
- Separate structural issues from local implementation bugs. Do not let diff noise crowd out system-shape concerns.
- Verify how the system is currently wired before judging the proposed or implemented architecture.
- Do not treat abstract elegance as evidence. Architectural recommendations must be grounded in repository facts and likely change paths.
- If you propose an alternative, check that it respects visible dependency boundaries and composition constraints.
- If repo-local review guidance exists, apply it as an overlay rather than replacing the method below.
- Do not drift into a general critique of the whole system. Stay focused on the boundary or structural decision under review.
- If you already have enough evidence for 1 to 3 material structural findings, stop and return rather than broadening scope.
</constraints>

<phase name="Restate and Map">

<goal>
Restate the architectural decision and identify the boundaries it changes.
</goal>

<procedure>
1. Restate the architectural change or design decision in neutral terms.
2. Identify the key structural choices being made:
   - ownership
   - dependency direction
   - composition root
   - extension points
   - contracts and data flow
3. Identify which projects, layers, or components must be checked to verify those choices.
4. Choose the smallest set of checks needed to produce a useful initial-pass structural review.
</procedure>

<gate>
- Architectural decision restated clearly.
- Boundary changes identified.
- Verification targets identified.
- Minimal initial-pass verification scope identified.
</gate>

</phase>

<phase name="Counter-case">

<goal>
Build the strongest plausible case that the architecture is the wrong shape before supporting it.
</goal>

<procedure>
1. Write the strongest plausible structural objection to the design or implementation.
2. Identify the smallest set of repository checks needed to test that objection.
3. Record which objections survive, collapse, or remain unverifiable.
4. If the initial pass already supports a clear structural verdict, stop and return rather than widening the review.
</procedure>

<gate>
- At least one structural counter-case constructed.
- Surviving objections separated from disproved objections.
- Unverifiable objections called out explicitly.
</gate>

</phase>

<phase name="Lens Review">

<goal>
Evaluate the architecture through the required structural lenses.
</goal>

<procedure>
Assess each lens below and end each one with `Sound`, `Concern`, `Gap`, or `N/A`.
Use evidence already gathered in earlier phases where possible. Any additional verification actions for lens review still count against the shared skill budget.

### 1. Responsibility Placement

- Are behaviors and policies owned by the right component?
- Is a layer taking on concerns that belong elsewhere?

### 2. Dependency Direction

- Do dependencies point in a sensible direction?
- Does the change create avoidable coupling across layers or projects?

### 3. Composition and Lifecycle

- Is object composition happening in the right place?
- Are DI, resource lifetime, and startup/runtime responsibilities modeled cleanly?

### 4. Contract Shape

- Are interfaces, DTOs, events, and configuration boundaries shaped for stable evolution?
- Is the design overexposed or too tightly bound to one implementation?

### 5. Extensibility and Change Cost

- Will likely future changes fit naturally into this structure?
- Does the proposal make the next likely change easier or harder?

### 6. Operability and Failure Boundaries

- Are configuration, observability, fault handling, and local development implications aligned with the design?
- Are failure boundaries clear, or will faults leak across components unclearly?

### 7. Simplicity

- Is the design simpler than the alternatives for the same outcome?
- Is abstraction being added because it is needed now, or only because it might be useful someday?
</procedure>

<gate>
- Every lens assessed with a visible verdict.
- Structural conclusions grounded in repository evidence where possible.
- Unverifiable areas called out explicitly.
</gate>

</phase>

<phase name="Verdict">

<goal>
State whether the structure is sound, sound with concerns, or should be revisited.
</goal>

<procedure>
1. List the top structural findings first.
2. Return at most the top 5 findings by default unless the caller asked for exhaustive review.
3. List open questions or unverifiable assumptions.
4. State a short verdict such as:
   - `Architecture is sound`
   - `Sound with concerns`
   - `Revisit structure`
5. If you recommend an alternative, state:
   - the alternative
   - the repository facts it was checked against
   - why it better fits the system shape
6. State whether deeper structural review is warranted or intentionally deferred.
7. End with a short plain-language summary.
</procedure>

<gate>
- Verdict supported by the counter-case and lens review.
- Alternatives validated against visible repository constraints.
- Structural issues kept distinct from incidental implementation bugs.
- Deeper review explicitly recommended or deferred.
</gate>

</phase>
