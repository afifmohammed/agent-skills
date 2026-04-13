# Structural Review (pass 2): cs-implement-plan vs w-implement-plan

**Baseline:** `skills/w-implement-plan/SKILL.md`
**Candidate:** `skills/cs-implement-plan/SKILL.md`
**Focus:** Agent clarity, determinism, and internal coherence

---

## Prior Findings — Resolution Status

All 8 findings from pass 1 have been addressed:

| # | Finding | Resolution |
|---|---------|------------|
| 1 | Fix → VerifyPlanned hardcoded | Lines 69-71: three return edges (VerifyPlanned, VerifyBuild, VerifyTests) |
| 2 | HumanInput → Implement only | Lines 74-76: context-dependent returns (Intake, Scope, Implement) |
| 3 | Missing Implement → HumanInput | Line 57: edge added |
| 4 | Two competing execution models | Line 80: reconciliation sentence. Section renamed to "State Semantics." Closeout state entry added (lines 136-140) |
| 5 | Fix-loop limit x4 | Lines 134, 154, 181 now reference "the fix-loop budget." Budget line 199 is the single authoritative source |
| 6 | w-implement-plan reference | Line 14: self-contained description |
| 7 | Scope/Verify discovery ambiguity | Scope steps 4-5 (lines 256-262) classify with Run/Skip/Block. Verify step 1 (line 324) defers to Scope's classification |
| 8 | Status vocabulary unmapped | Closeout step 2 (lines 358-361): explicit mapping at point of use |

---

## New Findings

### 1. "Inferred" vs "repo-standard" — minor vocabulary inconsistency

**Type:** Ambiguity (low severity)

**Evidence:**
- Verification Policy (line 152): "Prefer artifact-specified commands over **inferred** commands."
- Scope step 5 (line 261): `source: artifact-specified or **repo-standard**`

The Verification Policy uses "inferred" where every other section uses "repo-standard" for the same category. An agent building a mental model of command sources will encounter two labels for one concept.

**Agent risk:** Minimal. Context makes the meaning clear. But an easy one-word fix: change "inferred" to "repo-standard" in line 152 for consistency with the vocabulary established in Scope.

---

### 2. Verify phase re-entry after Fix → HumanInput → Implement is underspecified

**Type:** Ambiguity (low severity, edge case)

**Evidence:**
- Mermaid (line 72): `Fix --> HumanInput: blocker / repeated failure / required deviation`
- Mermaid (line 76): `HumanInput --> Implement: clarified implementation blocker`
- Verify procedure step 5 (line 336): "re-run only the affected state, subject to the fix-loop budget"
- Verify procedure step 1 (line 324): "Use the verification stack classified during Scope"

If a verification fix escalates through Fix → HumanInput → Implement → back to Verify, the agent re-enters the Verify phase from step 1. The procedure would re-run VerifyPlanned (already passed) before reaching the step that originally failed. Step 5's "re-run only the affected state" applies to inline fix loops within the phase, not to full phase re-entry.

**Agent risk:** The redundant re-run of already-passed verification states is wasteful but not harmful — they'll pass again quickly. This path is uncommon (requires a verification fix to escalate to human input). The alternative — adding HumanInput return edges directly to each verification substep — would significantly complicate the Mermaid for a rare scenario. Not worth the added complexity.

**Recommendation:** Acceptable as-is. If it ever causes real waste, adding a note to the Verify phase preamble ("If re-entering Verify after a human-resolved blocker, resume from the verification state that triggered the escalation") would be sufficient.

---

## No Material Issues Remain

The skill is internally coherent. The two findings above are low-severity: one is a one-word vocabulary fix, the other is an edge-case redundancy that is cheaper to accept than to eliminate.

### Residual risks (non-actionable, for awareness):

- **Structural weight.** The candidate is ~380 lines vs the baseline's ~184. The added structure (state model, state semantics, verification policy, delegation contract, stop conditions, output contract) is individually justified, but the combined surface area means an agent must parse more instruction before executing. If agent performance degrades on this skill compared to the baseline, over-specification is the first hypothesis to test.
- **Scope-phase verification discovery.** Scope now classifies verification intent upfront (lines 256-262). This is a good addition, but it means the agent must do verification discovery work before writing any code. For repos where the build/test commands are obvious, this is fast. For repos where they are not, the agent may spend its Intake budget on artifact loading and then hit discovery friction in Scope. The 3-action budget applies to Intake, not Scope — Scope has no explicit budget. Worth monitoring.

---

## What Works Well

Everything noted in pass 1 still holds, plus:

1. **Reconciliation sentence (line 80)** is concise and decisive. "Phases are the execution driver" is an unambiguous authority assignment. The renamed "State Semantics" heading (line 82) correctly signals that these are descriptive, not prescriptive.

2. **Fix-loop budget deduplication** is clean. The three reference sites (lines 134, 154, 181) use natural language that points to the budget without restating it. An agent scanning for the limit will find it once in the budget block.

3. **Scope verification classification** (lines 260-262) with `Run`/`Skip`/`Block pending clarification` gives the Verify phase a pre-built decision surface. The Verify preamble (line 324) correctly chains from it with a clear override condition ("unless new information emerged during Implement").

4. **Closeout status mapping** (lines 358-361) is at the point of use, not a separate reference table. This is the right placement — the agent encounters the mapping exactly when it needs to translate.

5. **Mermaid routing** is now accurate to the state semantics and phase contracts. Fix returns to the affected state. HumanInput returns to the originating state. Implement has a human exit. No silent gate-skipping paths remain.
