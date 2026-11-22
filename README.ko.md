# plan-efficient

[English](README.md) | 한국어

Claude Code용 `/plan`. 헛도는 반복은 빼고 필요한 검증은 남긴 계획을 짜고, 5시간·주간 한도를 몇 % 쓸지, 얼마나 걸릴지, 단계마다 어떤 모델과 effort가 맞는지 알려 줍니다. 계획을 보여 준 뒤에는 승인할 때까지 파일을 건드리지 않습니다. 계획은 사용자가 쓰는 언어로 나옵니다.

## 버전

모든 버전을 받을 수 있습니다. 원하는 쪽을 고르세요. 자세한 변경 내역은 [CHANGELOG.md](CHANGELOG.md#한국어)에 있습니다.

| 버전 | 이럴 때 | 라이선스 | 다운로드 |
|---|---|---|---|
| **1.2** (최신) | 추천. 1.1의 기능에 더해 지침이 가벼워졌고(실행할 때마다 토큰 약 45% 감소), 시간 제한 옵션이 생겼으며, 추정을 더 정직하게 보여 줍니다. 개인 설정을 스킬 폴더 밖에 두어 업데이트해도 지워지지 않습니다. 상태줄에 작은 래퍼를 넣을지 한 번 묻습니다(백업하고, 되돌릴 수 있음) | 무료 사용, 판매 금지 | [v1.2.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.2.zip) |
| 1.1 | 서버가 계산한 정확한 5시간·주간 %, 리셋까지 남은 시간, 자동 보정이 처음 들어간 버전 | 무료 사용, 판매 금지 | [v1.1.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.1.zip) |
| 1.0 | 추정치만 있으면 되고 설정 파일을 건드리고 싶지 않을 때 | MIT | [v1.0.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.0.zip) |

특정 버전만 받기: `git clone --branch v1.0 https://github.com/rudrhkwldus-dot/plan-efficient.git`

## 설치

`skills/plan-efficient` 폴더를 Claude Code 스킬 폴더에 복사합니다.

```bash
git clone https://github.com/rudrhkwldus-dot/plan-efficient.git
cp -r plan-efficient/skills/plan-efficient ~/.claude/skills/
```

Windows에서는 `~/.claude/skills`가 `C:\Users\<사용자>\.claude\skills`입니다. 새 세션을 열면 `/plan-efficient`가 목록에 나타납니다. 다른 플러그인은 필요 없습니다.

**업데이트:** 새 폴더를 기존 폴더 위에 복사하면 됩니다. 개인 설정과 보정 기록은 `~/.claude/plan-efficient/`에 있어서 그대로 남습니다. 1.1에서 올라오면 첫 실행 때 예전 설정을 그곳으로 자동으로 옮깁니다.

## 사용법

```
/plan-efficient <작업 설명 | path/to/*.prd.md> [--used N%] [--time 30m] [--budget low|med|high]
```

- `--used`: 지금 5시간 창에서 이미 쓴 비율. 아래 상태줄 연결을 설치하지 않았을 때만 필요합니다. 이 값도 서버 값도 없으면 사용량을 0%가 아니라 "모름"으로 봅니다.
- `--time`: 쓸 수 있는 시간. "30분 안에"처럼 말로 해도 됩니다.
- `--budget`: 모델 추천에 쓰는 예산 등급. 생략하면 남은 비율로 정합니다.

출력에는 단계별 할 일, 완료 기준, 재시도 상한, 추천 모델과 effort, 예상 토큰과 시간이 들어갑니다.

## 서버가 계산한 정확한 사용량 (선택)

Claude Code는 상태줄 명령에 Anthropic 서버가 계산한 사용량(5시간·주간 %와 각 리셋 시각)을 넘겨 줍니다. 스킬은 이 값을 직접 볼 수 없어서, 이 값을 파일로 저장하는 작은 래퍼를 함께 넣었습니다.

첫 실행 때 스킬이 설치할지 한 번 묻습니다. 직접 할 수도 있습니다.

```bash
bash ~/.claude/skills/plan-efficient/install.sh install    # settings.json 백업 후 상태줄을 감쌉니다
bash ~/.claude/skills/plan-efficient/install.sh status
bash ~/.claude/skills/plan-efficient/install.sh uninstall  # 이 스킬 등록을 지웁니다(아무 스킬도 안 쓰면 원래 상태줄로)
```

- 연결은 스킬 폴더 밖의 `~/.claude/usage-bridge/`에 깔리고, [smartwork](https://github.com/rudrhkwldus-dot/smartwork)와 같이 씁니다. 둘 다 설치해도 상태줄은 한 번만 감싸고, 한쪽을 지워도 다른 쪽은 그대로 동작합니다. 스킬 폴더를 그냥 지워도 상태줄은 깨지지 않습니다.

- 이미 상태줄을 쓰고 있으면 화면은 그대로입니다. 래퍼가 같은 입력으로 원래 상태줄을 실행합니다.
- 상태줄이 없으면 `5h 29% · 7d 59%` 같은 짧은 한 줄이 나옵니다.
- `jq`가 있으면 `jq`를, 없으면 Python을 씁니다. 둘 다 없으면 원본 JSON을 그대로 저장하고 스킬이 그것을 읽습니다.
- 이 값은 Pro/Max 구독자에게만, 세션의 첫 응답 이후에만 나옵니다. 값이 없으면 아래의 추정 방식으로 진행합니다.
- 상태줄 갱신이 조금 느려집니다. Windows(Git Bash)에서 한 번에 약 0.25초 늘어났고, macOS/Linux는 보통 더 짧습니다.

연결하면 계획에 지금 5시간·주간 %가 각각, 리셋까지 남은 시간과 함께 나옵니다. 작업 전후 값을 비교해 추정치도 스스로 보정합니다.

## 토큰 추정에 대해

Anthropic은 5시간 한도를 토큰 수로 공개하지 않습니다. 그래서 `~/.claude/plan-efficient/budget.md`의 한도 값은 근거가 확인되지 않은 시작용 어림값이고, 계획에도 그렇게 표시합니다. 근거 없는 ± 범위는 붙이지 않습니다. 모델 가중치는 API 가격에서 빌린 것이라 "가정"으로 표시합니다. 같은 모델로 두 번 이상 보정되면 예상치를 범위로 보여 줍니다. 첫 실행 때 요금제(Pro / Max 5x / Max 20x)를 한 번 묻습니다. 상태줄 연결이 있으면 작업 전후 서버 값으로 자동 보정하고, 없으면 실행 뒤 실제 사용량 %를 알려 주면 그 기록으로 고쳐 갑니다.

## 출처

[ECC](https://github.com/affaan-m/ECC)의 `/plan`과 `/model-route` 명령(MIT License, Copyright (c) 2026 Affaan Mustafa)을 바탕으로 고쳐 썼습니다. 원본 라이선스는 [`skills/plan-efficient/LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC)에 있습니다.

## 라이선스

- **1.1, 1.2**: 업무 용도까지 포함해 무료로 쓰고, 고치고, 나눠 줄 수 있습니다. **판매는 할 수 없습니다.** 재판매, 유료 마켓 등록, 유료 상품에 넣는 것이 모두 금지입니다. 자세한 내용은 [LICENSE](LICENSE)에 있습니다.
- **1.0**: MIT.
- ECC에서 가져온 부분은 계속 MIT License를 따릅니다([`LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC)).
