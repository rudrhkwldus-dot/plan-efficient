# plan-efficient

English | [한국어](README.ko.md)

A `/plan` for Claude Code that skips pointless retry loops but keeps the checks that matter. It tells you how much of your 5-hour and weekly limits the plan will use, how long it'll take, and which model and effort fit each step. It shows the plan and waits for your approval before touching any files.

Plans are written in the language you use.

## Versions

All versions stay available. Pick the one you want. Full details are in [CHANGELOG.md](CHANGELOG.md).

| Version | Choose it if | License | Download |
|---|---|---|---|
| **1.2** (latest) | Recommended. Everything in 1.1, with lighter instructions (about 45% fewer tokens per run), a time limit option, more honest estimates, and settings kept outside the skill folder so updates don't erase them. It asks once to add a small wrapper to your status line (backed up, reversible). | Free to use, no selling | [v1.2.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.2.zip) |
| 1.1 | The first version with exact 5-hour and weekly % from the server, time until reset, and automatic calibration. | Free to use, no selling | [v1.1.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.1.zip) |
| 1.0 | You only want estimates and don't want any settings touched. | MIT | [v1.0.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.0.zip) |

To clone a specific version: `git clone --branch v1.0 https://github.com/rudrhkwldus-dot/plan-efficient.git`

## Install

Copy the `skills/plan-efficient` folder into your Claude Code skills folder.

```bash
git clone https://github.com/rudrhkwldus-dot/plan-efficient.git
cp -r plan-efficient/skills/plan-efficient ~/.claude/skills/
```

On Windows, `~/.claude/skills` is `C:\Users\<you>\.claude\skills`. Open a new session and `/plan-efficient` appears in the list. No other plugins are needed.

**Updating:** copy the new folder over the old one. Your settings and calibration log live in `~/.claude/plan-efficient/`, so they're kept. Coming from 1.1, the skill moves your old settings there automatically on the first run.

## Usage

```
/plan-efficient <task description | path/to/*.prd.md> [--used N%] [--time 30m] [--budget low|med|high]
```

- `--used`: how much of the current 5-hour window you've already used. Only needed if the status line connection below isn't installed. If you don't give it and there's no server value, the plan treats your usage as unknown, not 0%.
- `--time`: how much time you have. You can also just say "within 30 minutes".
- `--budget`: budget level for model recommendations. If you leave it out, the skill picks one from what's left.

For each step, the plan lists what to do, when it counts as done, how many retries it gets, the recommended model and effort, and the expected tokens and time.

## Exact usage from the server (optional)

Claude Code passes the status line command the usage that Anthropic's server calculates (5-hour and weekly %, and when each resets). The skill can't see that directly, so it ships a small wrapper that saves those numbers to a file.

On the first run the skill asks once whether to install it. You can also do it yourself:

```bash
bash ~/.claude/skills/plan-efficient/install.sh install    # backs up settings.json, then wraps your status line
bash ~/.claude/skills/plan-efficient/install.sh status
bash ~/.claude/skills/plan-efficient/install.sh uninstall  # unregisters this skill (original status line comes back when no skill uses it)
```

- The connection is installed outside the skill folder, in `~/.claude/usage-bridge/`, and is shared with [smartwork](https://github.com/rudrhkwldus-dot/smartwork). Installing both wraps the status line only once, removing one keeps the other working, and deleting a skill folder doesn't break the status line.

- If you already have a status line, it keeps working exactly as before. The wrapper runs it with the same input.
- If you don't, you get a short line like `5h 29% · 7d 59%`.
- It uses `jq` if available, then Python. With neither, it saves the raw JSON and the skill reads that.
- Only Pro/Max subscribers get these numbers, and only after the first reply in a session. Without them the skill falls back to the estimates below.
- Each status line refresh takes a bit longer: about 0.25 s measured on Windows (Git Bash), usually less on macOS/Linux.

With the connection installed, the plan shows the current 5h and weekly % separately, plus time until each reset. The skill also compares usage before and after a task to calibrate its own estimates.

## About the token estimates

Anthropic doesn't publish the 5-hour limit as a token count, so the limit in `~/.claude/plan-efficient/budget.md` starts as an unverified guess, and the plan says so. It doesn't put a made-up ± range on it. Model weights are borrowed from API prices and are labeled as an assumption. After two calibrated runs with the same model, the estimate is shown as a range. On the first run the skill asks for your plan (Pro / Max 5x / Max 20x) once. With the status line connection, it calibrates automatically from the before/after server values. Without it, tell it the actual usage % after a run.

## Credits

Adapted from the `/plan` and `/model-route` commands in [ECC](https://github.com/affaan-m/ECC) (MIT License, Copyright (c) 2026 Affaan Mustafa). The original license is in [`skills/plan-efficient/LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC).

## License

- **1.1 and 1.2**: free to use, modify, and share, including at work. **Selling it is not allowed**: no resale, paid marketplaces, or paid products. See [LICENSE](LICENSE).
- **1.0**: MIT.
- The ECC-derived portions stay under the MIT License ([`LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC)).
