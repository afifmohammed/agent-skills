# Agent Instructions

Repo-level conventions for agents working in this codebase.

## Skill authoring

- Keep SKILL.md files lean. Do not add audit sections, routing logs, eval instrumentation, or reporting fields for the purpose of measuring skill effectiveness. Measurement belongs in external evals, not inside the skill.

## Docs structure

- `docs/{feature-name}/` — one directory per feature or skill.
- Planning artifacts (`spec.md`, `plan.md`, `hand-off.md`) sit at the feature root.
- `design-rationale.md` is a living document per feature capturing design decisions, rejected alternatives, open hypotheses, and forward direction. Updated in place; git history preserves the trail.
- Repo-level docs (e.g. `skill-review-protocol.md`) sit directly under `docs/`.
