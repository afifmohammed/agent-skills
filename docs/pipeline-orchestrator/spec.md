---
artifact: spec
title: Pipeline Orchestrator
sibling_artifacts:
  plan: plan.md
  hand-off: hand-off.md
---

# Pipeline Orchestrator

## What is being built

A lightweight pipeline orchestrator written in C# that composes agentic steps with deterministic steps and human decision gates. The orchestrator is the outer loop that calls agent steps, runs mechanical checks, normalizes agent outputs into a canonical structured signal, accumulates context, and enforces hard budget constraints on retries.

## Why

Today, agent skills are invoked manually in separate sessions. The agent is the outer loop — it decides when and whether to run verification, how to interpret results, and when to stop. `skills/cs-implement-plan` is the current agent-side implementation of this pattern — its verification states, fix-loop budget, and pause exits are the manual precursors to the pipeline's deterministic equivalents. This means:

- Deterministic checks (build, test, lint) depend on the agent remembering to run them and correctly interpreting their output.
- There is no structured feedback loop — if tests fail, the agent decides on its own what that means and what to do next.
- There is no hard enforcement of retry budgets — an agent can spin indefinitely.
- There are no formal human decision points — the human must interrupt or start a new session to redirect.

The orchestrator addresses all four by moving control out of the agent and into a typed pipeline where deterministic steps always run, feedback is structured, budgets are enforced, and human input is requested at defined gates.

## Goals

1. Compose existing agent steps and deterministic steps into an end-to-end pipeline without requiring step-specific changes.
2. Enforce that mechanical verification (build, test, lint) runs outside the agent's judgment after implementation.
3. Normalize non-deterministic step output into a canonical schema before the pipeline routes on it.
4. Enforce hard retry budgets so the pipeline stops or escalates rather than spinning.
5. Support human decision gates where a human (or later, an agent) chooses what happens next.
6. Keep the orchestrator's code immediately obvious to a reader — every handler has the same shape, the pipeline definition reads top to bottom.

## Non-goals

1. Replacing or modifying the underlying agent steps.
2. Building a general-purpose workflow engine.
3. Running agents in parallel (this may come later but is not in scope).
4. Providing a GUI — the interface is a TUI via the terminal.
5. Matching Stripe's blueprint system in sophistication. This is a first-principles foundation, not a feature-complete clone.

## Core abstractions

### Handler

A handler is a function that receives read-only accumulated context and returns a contribution or nil.

- A handler does not have access to the context store.
- A handler does not call `next` — the pipeline manages sequencing.
- A handler that has nothing to contribute returns nil.
- A handler does not contain branching logic that would be better expressed as two separate handlers. If a handler's behavior depends on context, it reads the context and decides whether to contribute. If the decision is "do nothing," it returns nil.

There are two kinds of handler, both with the same function signature:

- **Agentic handler**: invokes an agent step by shelling out to a CLI, captures raw evidence from the step, normalizes that evidence into the canonical schema, and returns a contribution.
- **Deterministic handler**: runs a shell command (e.g., `dotnet build`, `dotnet test`), parses the output, and returns a typed contribution.

Decision gates are not handlers. They are a pipeline-level concern — see "Decision gates and routing" below.

### Contribution

What a single handler returns after execution, or what the pipeline itself records for trace and decision entries. A contribution carries a handler name and a payload. The payload is one of:

- An **Outcome** — the typed result of a handler's work.
- A **TraceEntry** — the pipeline's record of whether a handler executed and whether it contributed.
- A **DecisionResult** — the pipeline's record of a choice made at a gate, including the selected option and any freeform annotation.
- A **LoopState** — the pipeline's record of loop-back count for a phase.

All four payload types are appended to the same store via the same `Append` operation. This keeps the store interface at two operations (`Read` and `Append`) with no special methods for trace, decisions, or loop state.

### Context store

An interface with two operations: `Read` and `Append`. The pipeline is the only caller of both operations. Handlers never access the store directly.

- The pipeline calls `Read` before invoking a handler, producing a read-only context view.
- The pipeline calls `Append` after a handler returns a non-nil contribution, and also for its own trace and decision entries.
- Context properties are lazy-loaded — if a handler inspects one property and returns nil, unread properties are never loaded. In the C# implementation, this should be backed by `Lazy<T>` internally while exposing ordinary read-only properties on `Context`.
- `Read` must capture a point-in-time snapshot of the store's state. The lazy functions returned in the context must be bound to that snapshot, not to live mutable state. This ensures the handler's view does not change during execution.

The store is pluggable. The initial implementation holds contributions in memory. A later implementation may write to SQLite for observability and to avoid context growth problems. The pipeline and handlers do not change when the store implementation changes.

### Context query

A `ContextQuery` controls what a handler sees. It is a filter over the accumulated contributions with these fields:

- **PhaseNames** (optional): restrict to contributions from a specific phase or set of phases.
- **PayloadTypes** (optional): restrict to specific payload types (outcomes, trace entries, decision results, loop state, or a combination).
- **LatestRoundOnly** (optional, default false): when true, return only contributions from the most recent pass through the current phase. Prior rounds are excluded. This is the mechanism that keeps context bounded during loops without requiring compaction logic. The handler and query config do not need to specify which phase they are in — the pipeline injects the current phase name into the query before calling `Read`.
- **Limit** (optional): return at most N contributions, most recent first.

If no fields are set, the query returns all contributions. The pipeline definition specifies a query per handler so that each handler's context is scoped to what it needs. This is declared alongside the handler ordering in the pipeline definition, not inside the handler.

For the in-memory store, the query is a filter over a slice. For a future SQLite store, each field maps to a `WHERE` clause.

### Outcome

The typed result of a step's execution, carried inside a contribution. Outcome variants:

- **Done**: step completed successfully. Move on.
- **FailedWithFeedback**: step failed. Carries structured information about what went wrong. Downstream handlers can use this to attempt a fix.
- **BudgetExhausted**: step has retried up to the allowed limit. Stop retrying, escalate.
- **NeedsEscalation**: the failure cannot be resolved automatically. Surface to the human.
- **NeedsDecision**: the pipeline has reached a point where a choice must be made. Carries the prompt and options.

This set is sealed — only the orchestrator package can define new variants. Downstream code matches on these variants to decide behavior.

### Canonical agent-step output

Every non-deterministic step must be converted into the same canonical output contract before the pipeline uses it for routing or retries. The orchestrator does not trust raw agent prose directly.

The canonical contract is intentionally small:

- `done`
- `failed_with_feedback`
- `needs_escalation`
- `needs_decision`

plus a small set of optional structured fields such as `summary`, `outputs`, `feedback`, `escalation`, and `decision`.

The pipeline may obtain this canonical output in one of two ways:

1. A step-specific deterministic interpretation of the step's evidence.
2. An LLM normalization call that takes the step's evidence and returns the canonical schema.

The default path for agentic CLI steps is LLM normalization, because most agentic CLIs do not expose a reliable machine-readable output format. Deterministic interpretation is still preferred where a step exposes stable signals such as exit codes, file creation, or other concrete artifacts.

When normalization uses a model API with structured output support, the API-facing schema should be a flattened subset that fits the provider's supported JSON Schema features. Conditional rules such as "this field must be present for this status" are enforced in C# after deserialization, not in the provider-facing schema itself.

### Step evidence and normalization

An agentic handler works in two stages:

1. Run the agentic CLI step and collect evidence.
2. Normalize that evidence into the canonical agent-step output.

Evidence may include:

- raw stdout
- raw stderr
- exit code
- files or other artifacts the step created

Normalization is responsible for turning that evidence into the canonical output contract. The orchestrator routes only on the normalized result, not on raw CLI output.

For known steps, the normalizer may incorporate step-specific checks. For unknown or loose step shapes, the normalizer may rely primarily on an API model call with structured output support. In either case, the normalized result must be validated against the canonical schema plus the orchestrator's own conditional business rules.

### Selector

An interface that takes a `NeedsDecision` outcome and returns either a successful selection (including any freeform annotation) or a failure result. The pipeline converts selector failure results into `NeedsEscalation`.

- **TUI selector**: renders options using the configured terminal UI library and waits for human input. May also accept freeform text as an annotation on the choice.
- **Agent selector**: sends the options to an agent and parses its selection from the response.

The pipeline is wired with a selector at startup. The same pipeline definition works in attended (human) or unattended (agent) mode by swapping the selector.

The agent selector is subject to the same failure policy as agentic handlers: timeout, crash, and unparseable output all cause the selector to return a failure result, which the pipeline converts into `NeedsEscalation` and exits. The agent selector is configured with a timeout. If the agent process exceeds it, returns a non-zero exit, or returns output that cannot be interpreted as a valid option selection, the pipeline does not retry the selection — it exits with `NeedsEscalation`. This ensures that unattended mode cannot stall at a decision gate.

### Phases and the pipeline

The pipeline is an ordered sequence of **named phases**. Each phase contains an ordered sequence of handlers. Within a phase, handlers execute linearly. Between phases, execution advances to the next phase unless a decision gate redirects to a different phase by name.

A phase is a grouping mechanism, not a new abstraction. Handlers inside a phase have the same signature and behavior as any other handler. The phase boundary is where decision gates and routing live.

The pipeline:

1. Enters the current phase and iterates through its handlers in order.
2. Before each handler, calls `Read` on the context store with the query configured for that handler.
3. Passes the read-only context snapshot to the handler.
4. Receives the contribution (or nil).
5. Calls `Append` if the contribution is non-nil.
6. Appends a trace entry for every handler: executed with contribution, executed without contribution, or skipped.
7. After processing a handler's outcome, either advances to the next handler, or — for terminal outcomes (`BudgetExhausted`, `NeedsEscalation`) — exits the pipeline.
8. At the end of a phase, advances to the next phase unless a decision gate routes elsewhere.

The pipeline is the only component that knows the phase ordering and handler ordering. Handlers do not know about phases, other handlers, or the pipeline.

### Decision gates and routing

A decision gate sits at a phase boundary. It is not a handler — it is a pipeline-level construct declared in the pipeline definition.

When the pipeline reaches a decision gate:

1. It constructs a `NeedsDecision` with the configured prompt and options.
2. It calls the selector, which returns either the chosen option (with optional annotation) or a failure result.
3. If the selector returns a failure result, the pipeline produces `NeedsEscalation` and exits.
4. Otherwise, it appends a `DecisionResult` contribution to the store, carrying the full typed choice and annotation.
5. It consults a routing table declared in the pipeline definition: each option maps to a target phase name.
6. It jumps to the target phase.

If the target phase has already been visited (a loop-back), the pipeline appends a `LoopState` contribution with the incremented loop count before re-entering. A guard handler at the top of the target phase checks the latest loop state for its phase. If it exceeds the configured maximum, the guard returns `BudgetExhausted`.

Options that map to no target phase (such as "abandon") cause the pipeline to exit.

This keeps routing visible and declarative in the pipeline definition. The handler code never contains routing logic.

### Execution trace

The pipeline appends a trace contribution for every handler it encounters. Each trace entry captures: handler name, phase name, status (executed with contribution, executed without contribution, or skipped), and a timestamp.

Trace entries are contributions in the store, not a separate channel. Handlers that need to check whether an upstream handler ran can read trace entries from the context. The pipeline controls which trace entries a handler sees via the context query, the same as for any other contribution.

A handler is marked **skipped** when the pipeline jumps over a phase that contains it due to a decision gate routing elsewhere.

## Agentic handler failure policy

Agentic handlers shell out to a CLI process, collect evidence, and then normalize that evidence into the canonical schema. Failures can happen in either stage. The orchestrator must handle both explicitly rather than stalling.

- **CLI hang**: each agentic handler is configured with a timeout. If the process exceeds the timeout, the handler kills it and returns `NeedsEscalation` with a reason indicating the timeout was exceeded. The timeout is configurable per handler in the pipeline definition.
- **CLI crash (non-zero exit)**: the handler records the failure evidence and passes it to the normalizer. If the normalizer cannot safely classify it as `failed_with_feedback`, the handler returns `NeedsEscalation`.
- **Normalization failure**: if the normalizer call fails, times out, returns invalid JSON, or returns JSON that does not satisfy the canonical schema and business rules, the handler returns `NeedsEscalation`.

This keeps the failure boundary explicit: raw CLI output is evidence, not control-plane truth. The pipeline trusts only the validated normalized result.

## Context design

Context is accumulated contributions from all handlers and pipeline-level entries (trace, decisions, loop state) that have been appended so far.

- Context is read-only from the handler's perspective. The handler receives a snapshot taken at `Read` time. Mutations to the snapshot do not propagate.
- Context properties are lazy — backed by `Lazy<T>` internally and exposed as ordinary read-only properties on `Context`. If a handler returns early, unaccessed properties never evaluate. If a handler reads the same property more than once, the underlying query runs once for that snapshot (not once per property access). Lazy evaluation is not shared across snapshots.
- The pipeline controls what context a handler receives by specifying a `ContextQuery` per handler in the pipeline definition.

## Feedback loop design

When a deterministic step (build, test, lint) fails:

1. The deterministic handler returns a `FailedWithFeedback` contribution with structured failure data (exit code, error output, failing test names, etc.).
2. The pipeline appends this to the context store.
3. The pipeline consults the phase's **retry pairs** — a declared mapping from a deterministic handler to an agentic fixer handler.
4. If the failed deterministic handler has a configured retry pair, the pipeline runs the fixer handler, passing the accumulated context (which now includes the failure feedback).
5. After the fixer completes, the pipeline reruns the same deterministic handler exactly once.
6. If the deterministic handler fails a second time, the pipeline converts the outcome to `BudgetExhausted` and escalates.
7. If the deterministic handler has no configured retry pair, `FailedWithFeedback` is treated as `NeedsEscalation` — there is no automatic fix path.

Retry pairs are declared in the phase definition, not in handler code. Neither handler knows it is part of a retry pair. The pipeline manages the retry sequence. The budget is per pair — build retries and test retries are independent.

For agentic steps more generally, the same retry and routing mechanics operate on the normalized canonical result rather than on raw CLI text.

## Human decision gates

At defined phase boundaries, a decision gate presents options via the selector. The pipeline routes to the target phase based on the choice.

Defined gates for the default end-to-end flow example:

1. **After planning**: human reviews the planning artifacts. Options: proceed to implementation, revise (with optional annotation), abandon. "Revise" routes back to the planning phase. "Abandon" exits the pipeline.
2. **After implementation and verification**: human reviews the result. Options: run review step A, run review step B, accept, revise (with optional annotation). "Revise" routes back to implementation.
3. **After review step A**: human reviews findings. Options: loop back to implementation, continue to review step B, accept. "Loop back" routes to implementation.
4. **After review step B**: human reviews findings. Options: loop back to implementation, accept. "Loop back" routes to implementation.

When a gate choice includes an annotation, the annotation is part of the `DecisionResult` contribution and is available in the context for the target phase's handlers.

## Loop mechanics

When a decision gate routes back to a previously visited phase, the pipeline appends a `LoopState` contribution for that phase with the incremented loop count. A guard handler at the top of the phase reads the latest `LoopState` for its phase from context. If it exceeds a configured maximum (default: 3 full loops), the guard returns `BudgetExhausted` and the pipeline escalates.

The accumulated context from prior rounds remains in the store. Handlers that don't need prior-round detail use a `ContextQuery` with `LatestRoundOnly: true` to see only the current round's contributions. Handlers that need history (such as a guard checking the loop count) query without that filter.

This avoids the need for a separate context compaction mechanism. If context growth becomes a problem with the in-memory store, the SQLite store can implement `LatestRoundOnly` as an efficient query rather than loading and filtering in memory. This is a store implementation concern, not a pipeline concern.

## Technology choices

- **Language**: C#
- **Runtime**: .NET
- **TUI**: a .NET terminal UI library such as Spectre.Console
- **Agent invocation**: shell out to CLI tools (e.g., `claude` for Claude Code)
- **Agent normalization**: call a model API with structured output support to convert raw agent-step evidence into the canonical schema
- **Context store (initial)**: in-memory slice of contributions
- **Context store (future)**: SQLite via a compatible .NET driver
- **Pipeline definition**: a single C# source file that declares phases, handler ordering, decision gates with routing tables, and context queries per handler. Adding a new deterministic check is: write the handler function, add it to the pipeline definition, rebuild.

## Constraints

- The orchestrator must not require changes to existing agent skills.
- Every handler has the same function signature. No special handler types with extra powers.
- The pipeline definition must be readable top-to-bottom as the full flow.
- Deterministic handlers must not invoke an LLM.
- Agentic handlers must not run deterministic verification — that is the pipeline's job.
- The pipeline must not route on raw agent CLI output. It routes only on the validated canonical result produced by normalization.
- Provider-facing structured-output schemas should be flattened and conservative; conditional business rules are enforced in C# after deserialization.
- The context store interface must remain two operations: `Read` and `Append`.
- Retry budgets are per feedback pair, not global.
- Decision gates are a pipeline-level construct, not a handler type.
- Routing logic lives in the pipeline definition, not in handler code.
- In v1, only `IContextStore` and `ISelector` are interfaces. The pipeline, phases, gates, queries, and contributions are concrete types and methods.
- The initial C# API must avoid builders, fluent chains, middleware stacks, registries, plugin systems, reflection-based registration, and embedded DSLs.
- `ContextQuery` remains a plain data filter interpreted by the store. It must not become an executable query language with callbacks, predicates, or user-defined operators.
- The initial implementation should stay in a small project and namespace layout: a main pipeline namespace and only a minimal number of support namespaces or projects such as a store namespace if needed.
- Prefer ordinary classes, records, lists, dictionaries, and methods over additional abstraction layers. New interfaces or projects should be introduced only when the implementation has a concrete need for them.

## Success criteria

1. The orchestrator can run a full multi-phase flow — plan, gate, implement, build, test, lint, gate, review, gate, secondary review, gate — as a single pipeline invocation.
2. Deterministic steps (build, test, lint) run and produce structured outcomes without agent involvement.
3. A non-deterministic step's raw output can be normalized into the canonical schema and validated before the pipeline routes on it.
4. Human gates present options via TUI and block until a choice is made.
5. The pipeline definition for the full flow is a single readable C# source file that declares phases, handlers, gates, and routing.
6. Adding a new deterministic check is: write a handler function, add it to the pipeline definition, rebuild.
7. An agentic handler that hangs, crashes, or fails normalization produces `NeedsEscalation` rather than stalling the pipeline.
8. An agent-backed decision gate that times out, crashes, or returns an invalid choice produces `NeedsEscalation` rather than stalling the pipeline.

---

## Appendix: Code sketches

These snippets show the shape of the core types and pipeline loop. They are illustrative, not prescriptive — the implementation may adjust naming and signatures as needed.

### Core types

```csharp
namespace Pipeline;

public abstract record Outcome;

public sealed record Done(string Summary) : Outcome;
public sealed record FailedWithFeedback(string Feedback, object? Detail) : Outcome;
public sealed record BudgetExhausted(int Attempts) : Outcome;
public sealed record NeedsEscalation(string Reason) : Outcome;
public sealed record NeedsDecision(string Prompt, IReadOnlyList<Option> Options) : Outcome;

public sealed record Option(string Label, string? Annotation = null);

public abstract record Payload;

public sealed record OutcomePayload(Outcome Value) : Payload;
public sealed record TraceEntry(string HandlerName, string PhaseName, TraceStatus Status, DateTimeOffset Timestamp) : Payload;
public sealed record DecisionResult(string GateName, Option Chosen, string? TargetPhase) : Payload;
public sealed record LoopState(string PhaseName, int Count, DateTimeOffset Timestamp) : Payload;

public enum TraceStatus
{
    Executed,
    ExecutedNoContribution,
    Skipped
}

public sealed record Contribution(string HandlerName, Payload Payload);

public sealed class Context
{
    private readonly Lazy<IReadOnlyList<Outcome>> _outcomes;
    private readonly Lazy<IReadOnlyList<TraceEntry>> _traceEntries;
    private readonly Lazy<IReadOnlyList<DecisionResult>> _decisions;
    private readonly Lazy<IReadOnlyList<LoopState>> _loopStates;
    private readonly Lazy<Outcome?> _latestOutcome;

    public Context(
        Lazy<IReadOnlyList<Outcome>> outcomes,
        Lazy<IReadOnlyList<TraceEntry>> traceEntries,
        Lazy<IReadOnlyList<DecisionResult>> decisions,
        Lazy<IReadOnlyList<LoopState>> loopStates,
        Lazy<Outcome?> latestOutcome)
    {
        _outcomes = outcomes;
        _traceEntries = traceEntries;
        _decisions = decisions;
        _loopStates = loopStates;
        _latestOutcome = latestOutcome;
    }

    public IReadOnlyList<Outcome> Outcomes => _outcomes.Value;
    public IReadOnlyList<TraceEntry> TraceEntries => _traceEntries.Value;
    public IReadOnlyList<DecisionResult> Decisions => _decisions.Value;
    public IReadOnlyList<LoopState> LoopStates => _loopStates.Value;
    public Outcome? LatestOutcome => _latestOutcome.Value;
}

public sealed record Handler(string Name, Func<Context, Contribution?> Fn);

public sealed record AgentStepEvidence(
    int ExitCode,
    string Stdout,
    string Stderr,
    IReadOnlyList<string> ArtifactPaths);

public sealed record NormalizedAgentStepOutput(
    string Version,
    string Status,
    string Summary,
    IReadOnlyList<string>? Outputs,
    string? Feedback,
    string? EscalationReason,
    NeedsDecision? Decision);

public interface IAgentStepNormalizer
{
    Task<NormalizedAgentStepOutput> NormalizeAsync(
        string stepName,
        string originalInput,
        AgentStepEvidence evidence,
        CancellationToken cancellationToken);
}

public sealed record ContextQuery(
    string? HandlerName = null,
    IReadOnlyList<string>? PhaseNames = null,
    IReadOnlyList<string>? PayloadTypes = null,
    bool LatestRoundOnly = false,
    int? Limit = null);

public interface IContextStore
{
    Context Read(ContextQuery query);
    void Append(Contribution contribution);
}

public abstract record SelectorResult;

public sealed record SelectorSuccess(Option Selected) : SelectorResult;
public sealed record SelectorFailure(string Reason) : SelectorResult;

public interface ISelector
{
    SelectorResult Select(NeedsDecision decision);
}

public sealed record GateOption(string Label, string? TargetPhase);

public sealed record Gate(string Prompt, IReadOnlyList<GateOption> Options);

public sealed class Phase
{
    public required string Name { get; init; }
    public required IReadOnlyList<Handler> Handlers { get; init; }
    public required IReadOnlyDictionary<string, ContextQuery> Queries { get; init; }
    public required IReadOnlyDictionary<string, Handler> RetryPairs { get; init; }
    public Gate? Gate { get; init; }
}
```

### Pipeline loop

```csharp
public static class PipelineRunner
{
    public static Outcome Run(IReadOnlyList<Phase> phases, IContextStore store, ISelector selector)
    {
        var phaseIndex = new Dictionary<string, int>(StringComparer.Ordinal);
        for (var i = 0; i < phases.Count; i++)
        {
            phaseIndex[phases[i].Name] = i;
        }

        var phaseVisits = new Dictionary<string, int>(StringComparer.Ordinal);
        var index = 0;

        while (index < phases.Count)
        {
            var phase = phases[index];
            phaseVisits[phase.Name] = phaseVisits.TryGetValue(phase.Name, out var visits) ? visits + 1 : 1;

            foreach (var handler in phase.Handlers)
            {
                var outcome = RunHandler(handler, phase, store);

                switch (outcome)
                {
                    case BudgetExhausted exhausted:
                        return exhausted;
                    case NeedsEscalation escalation:
                        return escalation;
                    case FailedWithFeedback:
                    {
                        if (!phase.RetryPairs.TryGetValue(handler.Name, out var fixer))
                        {
                            return new NeedsEscalation($"No retry pair for: {handler.Name}");
                        }

                        var fixOutcome = RunHandler(fixer, phase, store);
                        if (CheckTerminal(fixOutcome) is Outcome fixTerminal)
                        {
                            return fixTerminal;
                        }

                        var retryOutcome = RunHandler(handler, phase, store);
                        if (retryOutcome is FailedWithFeedback)
                        {
                            return new BudgetExhausted(2);
                        }

                        if (CheckTerminal(retryOutcome) is Outcome retryTerminal)
                        {
                            return retryTerminal;
                        }

                        break;
                    }
                }
            }

            if (phase.Gate is not null)
            {
                var decision = new NeedsDecision(
                    phase.Gate.Prompt,
                    ToOptions(phase.Gate.Options));

                var selection = selector.Select(decision);
                if (selection is SelectorFailure failure)
                {
                    return new NeedsEscalation($"Decision gate failed: {failure.Reason}");
                }

                var chosen = ((SelectorSuccess)selection).Selected;
                if (!TryFindTarget(phase.Gate.Options, chosen.Label, out var targetPhase))
                {
                    return new NeedsEscalation($"Invalid gate option selected: {chosen.Label}");
                }

                store.Append(new Contribution(
                    $"{phase.Name}:gate",
                    new DecisionResult(phase.Name, chosen, targetPhase)));

                if (targetPhase is null)
                {
                    return new Done($"Pipeline exited at gate: {phase.Name}");
                }

                if (!phaseIndex.TryGetValue(targetPhase, out var nextIndex))
                {
                    return new NeedsEscalation($"Unknown target phase: {targetPhase}");
                }

                if (phaseVisits.ContainsKey(targetPhase))
                {
                    store.Append(new Contribution(
                        $"{targetPhase}:loop",
                        new LoopState(targetPhase, phaseVisits[targetPhase], DateTimeOffset.UtcNow)));
                }

                index = nextIndex;
                continue;
            }

            index++;
        }

        return new Done("Pipeline completed all phases");
    }

    private static Outcome RunHandler(Handler handler, Phase phase, IContextStore store)
    {
        var query = BindQueryToPhase(phase.Name, phase.Queries[handler.Name]);
        var context = store.Read(query);
        var contribution = handler.Fn(context);

        if (contribution is null)
        {
            store.Append(new Contribution(
                handler.Name,
                new TraceEntry(handler.Name, phase.Name, TraceStatus.ExecutedNoContribution, DateTimeOffset.UtcNow)));

            return new Done($"{handler.Name} had nothing to contribute");
        }

        store.Append(contribution);
        store.Append(new Contribution(
            handler.Name,
            new TraceEntry(handler.Name, phase.Name, TraceStatus.Executed, DateTimeOffset.UtcNow)));

        return contribution.Payload switch
        {
            OutcomePayload payload => payload.Value,
            _ => new Done($"{handler.Name} completed")
        };
    }
}
```

### Example: deterministic build handler

```csharp
public static Handler BuildHandler(TimeSpan timeout) =>
    new(
        "dotnet-build",
        ctx =>
        {
            using var process = new System.Diagnostics.Process
            {
                StartInfo = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "dotnet",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                }
            };

            process.StartInfo.ArgumentList.Add("build");
            process.StartInfo.ArgumentList.Add("--no-restore");

            process.Start();

            if (!process.WaitForExit((int)timeout.TotalMilliseconds))
            {
                try { process.Kill(entireProcessTree: true); } catch { }
                return new Contribution(
                    "dotnet-build",
                    new OutcomePayload(new NeedsEscalation("Build timed out")));
            }

            var output = process.StandardOutput.ReadToEnd() + process.StandardError.ReadToEnd();

            Outcome outcome = process.ExitCode == 0
                ? new Done("Build succeeded")
                : new FailedWithFeedback("Build failed", output);

            return new Contribution(
                "dotnet-build",
                new OutcomePayload(outcome));
        });
```

### Example: agentic handler with normalization

```csharp
public static Handler ImplementStepHandler(
    IAgentStepNormalizer normalizer,
    string originalPrompt,
    TimeSpan timeout) =>
    new(
        "implement-step",
        ctx =>
        {
            using var process = new System.Diagnostics.Process
            {
                StartInfo = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "claude",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false
                }
            };

            process.StartInfo.ArgumentList.Add("-p");
            process.StartInfo.ArgumentList.Add(originalPrompt);

            process.Start();

            if (!process.WaitForExit((int)timeout.TotalMilliseconds))
            {
                try { process.Kill(entireProcessTree: true); } catch { }
                return new Contribution(
                    "implement-step",
                    new OutcomePayload(new NeedsEscalation("Implementation step timed out")));
            }

            var evidence = new AgentStepEvidence(
                process.ExitCode,
                process.StandardOutput.ReadToEnd(),
                process.StandardError.ReadToEnd(),
                Array.Empty<string>());

            NormalizedAgentStepOutput normalized;
            try
            {
                normalized = normalizer
                    .NormalizeAsync("implement-step", originalPrompt, evidence, CancellationToken.None)
                    .GetAwaiter()
                    .GetResult();
            }
            catch (Exception ex)
            {
                return new Contribution(
                    "implement-step",
                    new OutcomePayload(new NeedsEscalation($"Normalization failed: {ex.Message}")));
            }

            Outcome outcome = normalized.Status switch
            {
                "done" => new Done(normalized.Summary),
                "failed_with_feedback" => new FailedWithFeedback(
                    normalized.Feedback ?? normalized.Summary,
                    evidence.Stdout),
                "needs_escalation" => new NeedsEscalation(
                    normalized.EscalationReason ?? normalized.Summary),
                "needs_decision" when normalized.Decision is not null => normalized.Decision,
                _ => new NeedsEscalation("Normalizer returned an invalid status")
            };

            return new Contribution(
                "implement-step",
                new OutcomePayload(outcome));
        });
```

### Example: default pipeline definition

```csharp
public static IReadOnlyList<Phase> FullPipeline() =>
    new List<Phase>
    {
        new()
        {
            Name = "plan",
            Handlers = new List<Handler> { PlanningStepHandler() },
            Queries = new Dictionary<string, ContextQuery>
            {
                ["planning-step"] = new()
            },
            Gate = new Gate(
                "Review the planning artifacts.",
                new List<GateOption>
                {
                    new("Proceed to implementation", "implement"),
                    new("Revise", "plan"),
                    new("Abandon", null)
                })
        },
        new()
        {
            Name = "implement",
            Handlers = new List<Handler>
            {
                LoopGuardHandler(3),
                ImplementStepHandler(),
                BuildHandler(TimeSpan.FromMinutes(5)),
                TestHandler(TimeSpan.FromMinutes(10)),
                LintHandler(TimeSpan.FromMinutes(2))
            },
            Queries = new Dictionary<string, ContextQuery>
            {
                ["loop-guard"] = new(),
                ["implement-step"] = new(LatestRoundOnly: true),
                ["dotnet-build"] = new(LatestRoundOnly: true),
                ["dotnet-test"] = new(LatestRoundOnly: true),
                ["lint"] = new(LatestRoundOnly: true),
                ["fix-build"] = new(LatestRoundOnly: true),
                ["fix-tests"] = new(LatestRoundOnly: true),
                ["fix-lint"] = new(LatestRoundOnly: true)
            },
            RetryPairs = new Dictionary<string, Handler>
            {
                ["dotnet-build"] = FixBuildHandler(),
                ["dotnet-test"] = FixTestsHandler(),
                ["lint"] = FixLintHandler()
            },
            Gate = new Gate(
                "Review the implementation.",
                new List<GateOption>
                {
                    new("Run review step A", "review-a"),
                    new("Run review step B", "review-b"),
                    new("Accept", null),
                    new("Revise", "implement")
                })
        },
        new()
        {
            Name = "review-a",
            Handlers = new List<Handler> { ReviewStepAHandler() },
            Queries = new Dictionary<string, ContextQuery>
            {
                ["review-step-a"] = new()
            },
            Gate = new Gate(
                "Review the findings from review step A.",
                new List<GateOption>
                {
                    new("Loop back to implementation", "implement"),
                    new("Continue to review step B", "review-b"),
                    new("Accept", null)
                })
        },
        new()
        {
            Name = "review-b",
            Handlers = new List<Handler> { ReviewStepBHandler() },
            Queries = new Dictionary<string, ContextQuery>
            {
                ["review-step-b"] = new()
            },
            Gate = new Gate(
                "Review the findings from review step B.",
                new List<GateOption>
                {
                    new("Loop back to implementation", "implement"),
                    new("Accept", null)
                })
        }
    };
```

The full pipeline definition is a single function. Each phase, its handlers, context queries, and routing are declared in one place, readable top to bottom. This example is a default multi-phase flow, not a requirement that every implementation use these exact phase names or review steps.
