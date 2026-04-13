# Agent Workflow Skills

A set of reusable agent skills for planning, reviewing, and implementing features through structured workflows. Designed for cross-session execution where artifacts are the only communication channel between agents.

These skills follow the [Agent Skills specification](https://agentskills.io) and work with any CLI that supports it, including Claude Code, Gemini CLI, GitHub Copilot, and OpenAI Codex CLI.

## Skills

| Skill | Purpose |
|-------|---------|
| `w-plan-a-feature` | Interviews the user, writes `spec.md`, `plan.md`, and `hand-off.md`, runs an in-session review, and stops. Does not implement. |
| `w-implement-plan` | Implements a feature from planning artifacts. Prefers `hand-off.md`, accepts `plan.md`, uses `spec.md` as intent context. |
| `w-plan-review` | Reviews a plan for feasibility, risks, compatibility, and validation strategy. Used by `w-plan-a-feature` during its review phase. |
| `w-code-review` | Reviews code changes from a diff, branch, or file set. Findings-first, evidence-based. |
| `w-architecture-review` | Reviews structural decisions -- boundaries, dependency direction, system shape, extensibility. |
| `w-pressure-test` | Stress-tests a codebase-local claim by building the counter-case before the supporting case. |

## Installation

Clone the repo and run the install script:

```bash
git clone <repo-url> && cd agent-skills
./install.sh
```

This symlinks every skill into the user-level skills directory for each supported CLI:

| CLI | Install path |
|-----|-------------|
| Claude Code | `~/.claude/skills/` |
| GitHub Copilot | `~/.copilot/skills/` |
| OpenAI Codex CLI | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| Cross-tool | `~/.agents/skills/` |

Because these are symlinks, pulling updates takes effect immediately -- no reinstall needed.

### Manual installation

Copy or symlink individual skill folders from `skills/` into the appropriate path for your CLI:

```bash
# Example: install a single skill for Claude Code
ln -s "$(pwd)/skills/w-code-review" ~/.claude/skills/w-code-review
```

## How it works

### Planning and implementation are separate sessions

`w-plan-a-feature` runs in one session and produces three artifacts. `w-implement-plan` runs in a later session and consumes them. The artifacts are the only contract between the two -- there is no shared conversation context.

```
Session 1: w-plan-a-feature
  Interview -> spec.md -> plan.md -> review -> hand-off.md

Session 2: w-implement-plan
  hand-off.md -> scope -> implement -> verify -> closeout
```

### Artifact model

| Artifact | Contains | Source of truth for |
|----------|----------|---------------------|
| `spec.md` | What is being built and why | Intent, goals, constraints, success criteria |
| `plan.md` | How it will be built | Design approach, rationale, review outcome |
| `hand-off.md` | What the implementer needs to execute | Execution scope, worklist, fixed decisions, risks |

Every artifact has YAML frontmatter with an `artifact` field (`spec`, `plan`, or `hand-off`) and paths to its sibling artifacts. This allows skills to identify and cross-reference artifacts reliably.

### Conflict resolution

When artifacts disagree:
- `spec.md` wins on **intent** (what and why)
- `plan.md` wins on **implementation approach** (how)
- `hand-off.md` wins on **execution priority and focus** (what to do first)

### Review family

`w-plan-review`, `w-code-review`, and `w-architecture-review` share the same methodology -- budgeted verification, evidence-based findings, early exit when findings are clear -- but differ in their review lenses. They are intentionally aligned where the methodology overlaps and intentionally different where the review type demands it.

`w-pressure-test` is not part of the review family. It follows a different structure (counter-case before supporting case, structured evidence blocks, strict verdict constraints) because claim validation is a fundamentally different task than review.

## Design principles

### No context loss in handoffs

Every delegation between a main agent and sub-agent requires a structured brief -- not prose, a checklist. Every artifact section written by one skill is explicitly consumed by the next. The system does not rely on the agent inferring what context to pass.

### No silent spinning

Every phase that can run for multiple actions has either a budget ceiling, a checkpoint, or a spinning-detection rule. Budget exhaustion triggers escalation, not softer exploration. The agent must detect when it is not making progress and pull the user in rather than continuing to spend actions.

### No long silences

The agent surfaces progress at natural work boundaries -- after completing a worklist item, before delegating, after a planning checkpoint, before and after verification. The user should never have to interrupt the agent to find out what is happening.

## Usage

Start a planning session:
```
/w-plan-a-feature
```

In a later session, implement from the artifacts:
```
/w-implement-plan path/to/hand-off.md
```

Run a standalone review:
```
/w-plan-review
/w-code-review
/w-architecture-review
```

Stress-test a claim:
```
/w-pressure-test
```

## Customization

The review skills (`w-plan-review`, `w-code-review`, `w-architecture-review`) look for repo-local review guidance at paths like `docs/repo-review-context.md` or `docs/architecture/conventions.md`. If present, repo-local guidance is applied as an overlay on top of the skill's methodology.

The review lenses in the current skills are oriented toward C# backend repositories. To adapt for a different stack, modify the lenses in each review skill while keeping the methodology (budget, counter-case, evidence requirements, verdict structure) intact.
