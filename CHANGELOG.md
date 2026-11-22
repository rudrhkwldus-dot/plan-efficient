# Changelog

English | [한국어](#한국어)

## 1.1 (2026-11-23)

### Added
- **Exact current usage from the server.** An optional status line wrapper (`usage-snapshot.sh`) saves the usage numbers Claude Code receives from Anthropic (5-hour %, weekly %, and when each resets). The skill reads them through `install.sh usage`, so you no longer need `--used`.
- **5-hour and weekly limits shown separately**, each with time until reset. The weekly limit was not tracked in 1.0.
- **Automatic calibration.** The skill compares server values before and after a task and adjusts its 5-hour (and weekly) limit estimate. It skips calibration when a reset happened in between or the change is too small to trust.
- `install.sh` with `install` / `uninstall` / `status` / `usage`. The first run asks once whether to install; it backs up `settings.json` and wraps your existing status line, so your status line looks the same.
- Fallbacks: `jq`, then Python, then saving the raw JSON for the skill to read. Works without either tool.
- `budget.md`: new `7d_budget_tokens` and `statusline` fields, and Δ% columns in the calibration log.

### Changed
- Budget level drops one step when weekly usage is 80% or more.
- `--used` is now only a fallback for when server values aren't available.

### License
- 1.1 is free to use, modify, and share, but **may not be sold**. See `LICENSE`. 1.0 stays MIT.

### Notes
- Server values exist only for Pro/Max subscribers, after the first reply in a session. Otherwise 1.1 behaves like 1.0.
- The status line refresh takes about 0.25 s longer on Windows (Git Bash).

## 1.0 (2026-11-22)

- First release. Plans with token estimates against the 5-hour limit, time estimates, and per-step model and effort. The current usage is entered by hand with `--used`. Doesn't touch any settings.

---

## 한국어

### 1.1 (2026-11-23)

**추가**
- **서버가 계산한 현재 사용량.** 선택 설치하는 상태줄 래퍼(`usage-snapshot.sh`)가 Claude Code가 받은 사용량(5시간 %, 주간 %, 각 리셋 시각)을 저장합니다. 스킬은 `install.sh usage`로 이 값을 읽으므로 `--used`를 넣을 필요가 없습니다.
- **5시간 한도와 주간 한도를 따로 표시**하고, 각각 리셋까지 남은 시간도 보여 줍니다. 1.0은 주간 한도를 보지 않았습니다.
- **자동 보정.** 작업 전후 서버 값을 비교해 5시간(과 주간) 한도 추정치를 고칩니다. 그 사이에 리셋이 있었거나 변화가 너무 작으면 보정하지 않습니다.
- `install.sh`(`install` / `uninstall` / `status` / `usage`). 첫 실행 때 설치할지 한 번 묻고, `settings.json`을 백업한 뒤 기존 상태줄을 감싸므로 화면은 그대로입니다.
- 대체 방법: `jq` → Python → 원본 JSON 저장(스킬이 직접 읽음). 두 도구가 없어도 동작합니다.
- `budget.md`: `7d_budget_tokens`, `statusline` 항목과 보정 기록의 Δ% 칸 추가.

**변경**
- 주간 사용량이 80% 이상이면 예산 등급을 한 단계 낮춥니다.
- `--used`는 서버 값이 없을 때만 쓰는 대체 입력이 됐습니다.

**라이선스**
- 1.1은 무료로 쓰고, 고치고, 나눠 줄 수 있지만 **판매는 금지**입니다. `LICENSE`를 보세요. 1.0은 MIT 그대로입니다.

**참고**
- 서버 값은 Pro/Max 구독자에게만, 세션의 첫 응답 이후에만 있습니다. 값이 없으면 1.0과 같이 동작합니다.
- Windows(Git Bash)에서 상태줄 갱신이 약 0.25초 늘어납니다.

### 1.0 (2026-11-22)

- 첫 공개. 5시간 한도 대비 예상 토큰, 예상 시간, 단계별 모델과 effort를 담은 계획을 짭니다. 현재 사용량은 `--used`로 직접 입력합니다. 설정 파일은 건드리지 않습니다.
