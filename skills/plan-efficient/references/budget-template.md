# plan-efficient settings

This file lives in `~/.claude/plan-efficient/budget.md`, outside the skill folder, so updating the skill never erases it.

plan: unset              # Pro | Max 5x | Max 20x  (asked once on first run)
5h_budget_tokens: unset  # Sonnet-weighted tokens per 5-hour window. Starts from the plan default below
7d_budget_tokens: unknown  # no default; filled only by calibration
calibrated: no           # yes only with 2+ valid samples for the same main model
statusline: unset        # unset | installed | declined  (install prompt is shown once)

## Plan defaults (uncalibrated starting guesses)

Anthropic does not publish the 5-hour limit as a token count. These values are unverified starting guesses. Max 5x and 20x follow only the advertised 5x / 20x multiples of Pro.

| plan | 5h_budget_tokens |
|---|---|
| Pro | 1,000,000 |
| Max 5x | 5,000,000 |
| Max 20x | 20,000,000 |

## Calibration log

| date | task | main model | est. weighted tokens | 5h Δ% | 7d Δ% | cost Δ$ | source | 5h limit after | 7d limit after |
|---|---|---|---|---|---|---|---|---|---|
