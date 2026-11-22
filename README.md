# plan-efficient

English | [한국어](README.ko.md)

A `/plan` for Claude Code that skips pointless retry loops but keeps the checks that matter. It tells you how much of your 5-hour limit the plan will use, how long it'll take, and which model and effort fit each step. It shows the plan and waits for your approval before touching any files.

The skill's instructions are written in Korean, so the plans it produces are in Korean.

## Versions

Both versions stay available. Pick the one you want. Full details are in [CHANGELOG.md](CHANGELOG.md).

| Version | Choose it if | Download |
|---|---|---|
| **1.1** (latest) | You want the exact 5-hour and weekly % from the server, time until reset, and automatic calibration. It asks once to add a small wrapper to your status line (backed up, reversible). | [v1.1.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.1.zip) |
| 1.0 | You only want estimates and don't want any settings touched. | [v1.0.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.0.zip) |

To clone a specific version: `git clone --branch v1.0 https://github.com/rudrhkwldus-dot/plan-efficient.git`

## Install

Copy the `skills/plan-efficient` folder into your Claude Code skills folder.

```bash
git clone https://github.com/rudrhkwldus-dot/plan-efficient.git
cp -r plan-efficient/skills/plan-efficient ~/.claude/skills/
```

On Windows, `~/.claude/skills` is `C:\Users\<you>\.claude\skills`. Open a new session and `/plan-efficient` appears in the list. No other plugins are needed.

## Usage

```
/plan-efficient <task description | path/to/*.prd.md> [--used N%] [--budget low|med|high]
```

- `--used`: how much of the current 5-hour window you've already used. Only needed if the status line connection below isn't installed.
- `--budget`: budget level for model recommendations. If you leave it out, the skill picks one from what's left.

For each step, the plan lists what to do, when it counts as done, how many retries it gets, the recommended model and effort, and the expected tokens and time.

## Exact usage from the server (optional)

Claude Code passes the status line command the usage that Anthropic's server calculates (5-hour and weekly %, and when each resets). The skill can't see that directly, so it ships a small wrapper that saves those numbers to a file.

On the first run the skill asks once whether to install it. You can also do it yourself:

```bash
bash ~/.claude/skills/plan-efficient/install.sh install    # backs up settings.json, then wraps your status line
bash ~/.claude/skills/plan-efficient/install.sh status
bash ~/.claude/skills/plan-efficient/install.sh uninstall  # puts your original status line back
```

- If you already have a status line, it keeps working exactly as before. The wrapper runs it with the same input.
- If you don't, you get a short line like `5h 29% · 7d 59%`.
- It uses `jq` if available, then Python. With neither, it saves the raw JSON and the skill reads that.
- Only Pro/Max subscribers get these numbers, and only after the first reply in a session. Without them the skill falls back to the estimates below.
- Each status line refresh takes a bit longer: about 0.25 s measured on Windows (Git Bash), usually less on macOS/Linux.

With the connection installed, the plan shows the current 5h and weekly % separately, plus time until each reset. The skill also compares usage before and after a task to calibrate its own estimates.

## About the token estimates

Anthropic doesn't publish the 5-hour limit as a token count, so the limit in `budget.md` is a rough starting value. Expect the first few estimates to be off by about ±50%. On the first run the skill asks for your plan (Pro / Max 5x / Max 20x) once. With the status line connection, it calibrates automatically from the before/after server values. Without it, tell it the actual usage % after a run.

## Credits

Adapted from the `/plan` and `/model-route` commands in [ECC](https://github.com/affaan-m/ECC) (MIT License, Copyright (c) 2026 Affaan Mustafa). The original license is in [`skills/plan-efficient/LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC).

## License

[MIT](LICENSE)
