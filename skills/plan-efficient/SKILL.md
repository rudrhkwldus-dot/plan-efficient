---
name: plan-efficient
description: 'An efficient /plan for Claude Code. Builds an implementation plan that keeps the checks that matter, skips pointless retry loops, and shows expected usage (tokens and % of the 5-hour and weekly limits, read from the server when available), a time range, and the recommended model and effort per step. Use when the user types /plan-efficient or asks for an efficient plan, a token-saving plan, or a plan that fits the 5-hour limit or a time limit (e.g. "효율적으로 계획 짜 줘", "토큰 아끼는 계획", "5시간 안에 끝나는 계획"). Plans only: no code or file changes before the user approves.'
argument-hint: "<task | path/to/*.prd.md> [--used N%] [--time 30m] [--budget low|med|high]"
---

# plan-efficient

Plan before implementing: restate the requirements → find evidence in the codebase → split into stages (with dependencies) → risks → **wait for approval**. On top of that, give:

1. a route that balances correctness and cost
2. expected usage (tokens, % of the 5-hour and weekly limits) and a time range
3. a model and effort level per stage

Write the plan in the user's language.

## Hard rules

- **No code or file changes before approval.** The only exceptions are this skill's own state in `{state_dir}` (settings and calibration log) and saving the plan when the user asked for that up front.
- No subagents by default. Planning itself must stay cheap.
- Unknown stays unknown. Never treat missing usage as 0%. Never invent file paths, patterns, model names, or settings.
- Ask only for information that changes the plan. Anything else becomes a stated assumption.

## Inputs

| Input | What to do |
|---|---|
| `*.prd.md` path | Plan the first pending milestone (or the one the user names). Write the plan in chat. **Propose** saving it to `.claude/plans/{kebab-case-name}.plan.md` and, if the PRD has a `Delivery Milestones` table, marking only that row `in-progress` with the plan path. Write both after approval, or right away if the user asked to save up front |
| other Markdown path | Read it as reference; plan in chat |
| plain text | Plan in chat |
| empty | Ask what to plan |

- `--used N%`: share of the current 5-hour window already used. Ignored when server values exist. If neither exists, current usage is **unknown**: skip the "after" values and the 80% check, and show only what this plan will use.
- `--time 30m` (or "within 30 minutes" in the request): time available. The plan must fit it: cut optional scope or set a checkpoint.
- `--budget low|med|high`: budget level for model choice. Default from 5-hour remaining: < 30% → low, 30–70% → med, > 70% → high. Unknown usage → med. Weekly usage ≥ 80% → one level lower.

## Step 0: settings and current usage

`{dir}` is the folder containing this SKILL.md. Run **once**, no retries:

```bash
bash "{dir}/install.sh" usage
```

- If it can't run (no bash, not Claude Code, permission denied), continue with estimates only and write "server values unavailable". Don't look for other sources.
- It prints `key=value` lines, including `state_dir`. Read `{state_dir}/budget.md`.
- **Normal case**: `status=installed`, `snapshot=ok`, `age_sec` ≤ 900, `settings=present`, and `plan:` is set. Use `five_hour_pct`, `seven_day_pct`, and `*_resets_in_sec`. A window with `resets_in_sec` ≤ 0 has reset since the snapshot: treat it as 0%.
- **Anything else** (first run, `plan: unset`, not installed, stale or unparsed snapshot, `migrated=`): read `references/setup.md` and follow it.

## Step 1: evidence (bounded)

Find the conventions the change must follow. For each that applies, give one example with `file:line`.

| Item | Look for |
|---|---|
| Naming | how files, functions, types, commands are named in the area |
| Errors | thrown, returned, or logged |
| Logging | level, format, what gets logged |
| Data access | repositories, services, queries, file handling |
| Tests | location, framework, fixtures, assertion style |

If nothing similar exists, say so. Skip this step for tasks without a repository.

Limits: search with Grep/Glob first. Read whole files only for the files to change plus one representative example. For large files, read line ranges. Re-read a file only if it changed or the earlier range was not enough. About 10 tool calls; beyond that, write the gap as an assumption and turn it into a verification stage.

## Step 2: route

A good route meets all of these:

| Condition | Test |
|---|---|
| Fits the 5-hour window | current + expected ≤ **80%** of the 5-hour limit; otherwise split at a checkpoint. If current usage is unknown, don't judge; for large plans just mark where to split |
| Fits `--time` | when given |
| No pointless loops | every repeating stage has a done condition, a retry cap, and a stop condition |
| Correct | a check at each point that is expensive to get wrong (design decisions, data transforms, public behavior) |

Compare routes in one table (tokens, time, correctness risk) only when there is a real tradeoff; otherwise just recommend one.

Rules every plan must include:

- **Retry cap**: at most 2 attempts per approach. After 2 failures, change the hypothesis or ask the user. Never rerun an unchanged command.
- **Cheap checks first**: type check, one unit test, or a small sample before the full suite or full data run, which happens once at the end.
- **No polling**: run long jobs in the background and get notified. If that isn't supported, use a bounded wait.
- **Subagents only when they pay off**: each costs a noticeable amount of context (roughly 20k tokens, not measured). Use them only for real parallelism or a large saving in main context.
- **Keep for correctness**: final verification, checking what the user will see, and confirmation before irreversible actions. When the budget is tight, cut optional scope or split the work; never silently drop these.

## Step 3: estimate

Estimate each stage, then add:

| Item | Rough value |
|---|---|
| Tool call (call + result + short reasoning) | ~2k tokens |
| Reading a file | lines × ~12 tokens |
| Writing/editing | lines written × ~15 tokens |
| Context growth | total × 1.5 (≤ 30 calls) / × 2.5 (30–80) / × 4 (> 80) |
| Subagent | ~20k + its own work |
| Planning | only the part after Step 0 (the server value already includes earlier usage) |

Model weights (Sonnet = 1): **haiku 0.33, sonnet 1.0, opus 1.67**. These are an **assumption** borrowed from API price ratios; nothing official says subscription limits scale this way.

- 5-hour % = Σ(stage tokens × weight) ÷ `5h_budget_tokens`
- Weekly % = same sum ÷ `7d_budget_tokens`. If that is `unknown`, show only the current weekly value and write "not calibrated" for the estimate.
- State the basis: "calibrated: N samples, same model" or "uncalibrated starting guess, error range unknown". Never attach a ±N% without data. With 2+ samples, show the estimate as a range.

Time: tool calls × 20–40 s + build/test/script time, as a range. Show waits for user approval separately. For stages that can run in parallel, use the longest chain and say so. If the work runs past the 5-hour reset, note that work after the reset counts in a new window, and place checkpoints around the reset.

## Step 4: model and effort

| Model | When |
|---|---|
| haiku | fixed, low-risk, mechanical changes |
| sonnet | default for implementation and refactoring |
| opus | design, deep review, ambiguous requirements |

With budget `low`, consider one model lower first, unless the correctness risk is high. Pick one default model (confidence high/medium/low, the reason, and a fallback if the first attempt fails), then assign per stage by the same rules.

| Effort | When |
|---|---|
| low | renames, formatting, fixed transforms |
| medium | normal implementation, writing tests (default) |
| high | unclear-cause debugging, design decisions, multi-file refactors |
| xhigh / max | only after two failures at a lower level; note the large token increase |

Where the model or effort changes, add one line on how to switch (e.g. `/model`). If the stage is short and the gain is small, say not to switch.

## Output

Use this order. Translate headings into the user's language. For small tasks, drop empty parts.

```markdown
# Efficient plan: {task}

## Requirements
- ...

## Evidence (patterns to follow)
| Item | Location | Pattern |
|---|---|---|

## Recommended route
{1–2 sentences: why this balances correctness and cost; what was cut and which checks stay}

## Stages
### Stage 1: {name} · {model} / effort {level}
- Do: ...
- Done when: ...
- Retry cap / stop condition: ...
- Estimate: ~{N}k tokens · {M1}–{M2} min

## Expected usage
| Stage | Model | Effort | Tokens | Weighted | Time |
|---|---|---|---|---|---|
| Total | | | {N}k | {W}k | {M1}–{M2} min |

| Limit | Now | This plan | After | Resets in |
|---|---|---|---|---|
| 5h | {U5}% | +{P5}% (est.) | ~{U5+P5}% | {time} |
| Weekly | {U7}% | +{P7}% (est. / not calibrated) | ~{U7+P7}% | {time} |

- Current values from: {server (saved N min ago) / --used / unknown}
- Estimate basis: {calibrated: N samples, range P_min–P_max% / uncalibrated: {plan} starting guess, error range unknown}
- Over 80%: {which stage to stop after, and what the next session continues}
- Weekly limit first: {if so, what to cut}

## Model
- Default: {model} (confidence {high/medium/low}): {reason}
- Fallback: {model}: {when to switch}

## Risks
| Risk | Likelihood | Response |
|---|---|---|

**Awaiting approval**: proceed with this plan? (yes / change: ... / other route: ...)

Start record: 5h {U5}% · weekly {U7}% · cost ${C} · session {id} · {time}
```

"Now" from the server: drop decimals. Unknown → "unknown" and "After" → "—". "Resets in" from `*_resets_in_sec`, written like "1 h 20 min" or "3 d 4 h"; missing → "—". Write the start record only when server values were used.

## After approval and execution

Report estimate vs actual in one line (tool calls, time, 5-hour and weekly change). If server values or a user-reported % are available, read `references/calibration.md` and follow it.

## Revising and handing off

- **Revising after a failure or scope change**: keep verified work, say what made the old plan wrong, and re-estimate only the remaining work. Separate what can be deferred from checks that must stay.
- **Pausing or moving to a new session**: write a short handoff in chat: goal, verified work done, unresolved failures and attempt counts, remaining stages, required checks, next action. Save it to a file only if the user asks.

## Credits

Based on the `/plan` and `/model-route` commands from [ECC](https://github.com/affaan-m/ECC) (MIT License, Copyright (c) 2026 Affaan Mustafa): the planning flow, input handling, pattern checklist, and model tiers were adapted. The full upstream license is in `LICENSE-ECC` in this folder.
