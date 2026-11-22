# Setup and edge cases

Read this only when Step 0 is not the normal case. `{dir}` is the skill folder; `{state_dir}` comes from the `install.sh usage` output.

## 1. Settings

- `settings=created` or `plan: unset` in `{state_dir}/budget.md`: ask **once** which plan the user has (Pro / Max 5x / Max 20x). Write `plan:` and set `5h_budget_tokens` to that plan's default from the table in the same file. Say these are uncalibrated starting guesses.
- `migrated=...`: tell the user in one line that their 1.1 settings were moved to `{state_dir}`. If the moved `budget.md` is missing fields or log columns that `{dir}/references/budget-template.md` has, add them and keep the existing values and rows.
- `settings=missing`: the template couldn't be copied. Continue with the Pro default as an uncalibrated guess and say so.

## 2. Usage output

| Output | What to do |
|---|---|
| `snapshot=ok`, `age_sec` > 900 | Stale. Show the values as "saved N min ago". If `--used` was given, use it for the 5-hour value instead |
| `*_resets_in_sec` ≤ 0 | That window reset after the snapshot: treat it as 0% |
| `snapshot=unparsed` | No jq or Python on this machine. Read the JSON at `file=` yourself: use `raw.rate_limits`; age = `now` − `ts` |
| `snapshot=none`, `status=installed` | Just installed. Write "server values from the next reply" and estimate for now |
| `status=not-installed` or `no-settings` | Go to section 3 |
| `status=unknown` | No jq or Python to read `settings.json`. Estimate, and mention the manual setup in the README once |

API-key users, and sessions before the first reply, have no server values. Write "server values unavailable" and estimate.

## 3. Status line connection (asked once)

Only when `statusline: unset` in `budget.md`. Ask in the user's language:

> To show exact usage (the 5-hour and weekly % calculated by the server), I need to connect to your status line. I'll back up `settings.json` and wrap your current status line, so it will look the same. Install it?

- Yes → run `bash "{dir}/install.sh" install`, show its output (including the backup path), and set `statusline: installed`.
- No → set `statusline: declined` and don't ask again. Use `--used` and estimates.
- If the output is the manual-setup message (no jq or Python), show it and continue with estimates.
