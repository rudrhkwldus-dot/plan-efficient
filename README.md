# plan-efficient

English | [한국어](README.ko.md)

A `/plan` for Claude Code that skips pointless retry loops but keeps the checks that matter. It tells you how much of your 5-hour limit the plan will use, how long it'll take, and which model and effort fit each step. It shows the plan and waits for your approval before touching any files.

The skill's instructions are written in Korean, so the plans it produces are in Korean.

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

- `--used`: how much of the current 5-hour window you've already used. With it, the plan also shows where you'll be when it finishes.
- `--budget`: budget level for model recommendations. If you leave it out, the skill picks one from what's left.

For each step, the plan lists what to do, when it counts as done, how many retries it gets, the recommended model and effort, and the expected tokens and time.

## About the token estimates

Anthropic doesn't publish the 5-hour limit as a token count, so the limit in `budget.md` is a rough starting value. Expect the first few estimates to be off by about ±50%. On the first run the skill asks for your plan (Pro / Max 5x / Max 20x) once. After a run, tell it the actual usage % and it adjusts the limit from that record.

## Credits

Adapted from the `/plan` and `/model-route` commands in [ECC](https://github.com/affaan-m/ECC) (MIT License, Copyright (c) 2026 Affaan Mustafa). The original license is in [`skills/plan-efficient/LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC).

## License

[MIT](LICENSE)
