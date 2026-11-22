# plan-efficient

[English](README.md) | 한국어

Claude Code용 `/plan`. 헛도는 반복은 빼고 필요한 검증은 남긴 계획을 짜고, 5시간 한도를 몇 % 쓸지, 얼마나 걸릴지, 단계마다 어떤 모델과 effort가 맞는지 알려 줍니다. 계획을 보여 준 뒤에는 승인할 때까지 파일을 건드리지 않습니다.

## 버전

두 버전을 모두 받을 수 있습니다. 원하는 쪽을 고르세요. 자세한 변경 내역은 [CHANGELOG.md](CHANGELOG.md#한국어)에 있습니다.

| 버전 | 이럴 때 | 다운로드 |
|---|---|---|
| **1.1** (최신) | 서버가 계산한 정확한 5시간·주간 %, 리셋까지 남은 시간, 자동 보정을 원할 때. 상태줄에 작은 래퍼를 넣을지 한 번 묻습니다(백업하고, 되돌릴 수 있음) | [v1.1.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.1.zip) |
| 1.0 | 추정치만 있으면 되고 설정 파일을 건드리고 싶지 않을 때 | [v1.0.zip](https://github.com/rudrhkwldus-dot/plan-efficient/archive/refs/tags/v1.0.zip) |

특정 버전만 받기: `git clone --branch v1.0 https://github.com/rudrhkwldus-dot/plan-efficient.git`

## 설치

`skills/plan-efficient` 폴더를 Claude Code 스킬 폴더에 복사합니다.

```bash
git clone https://github.com/rudrhkwldus-dot/plan-efficient.git
cp -r plan-efficient/skills/plan-efficient ~/.claude/skills/
```

Windows에서는 `~/.claude/skills`가 `C:\Users\<사용자>\.claude\skills`입니다. 새 세션을 열면 `/plan-efficient`가 목록에 나타납니다. 다른 플러그인은 필요 없습니다.

## 사용법

```
/plan-efficient <작업 설명 | path/to/*.prd.md> [--used N%] [--budget low|med|high]
```

- `--used`: 지금 5시간 창에서 이미 쓴 비율. 아래 상태줄 연결을 설치하지 않았을 때만 필요합니다.
- `--budget`: 모델 추천에 쓰는 예산 등급. 생략하면 남은 비율로 정합니다.

출력에는 단계별 할 일, 완료 기준, 재시도 상한, 추천 모델과 effort, 예상 토큰과 시간이 들어갑니다.

## 서버가 계산한 정확한 사용량 (선택)

Claude Code는 상태줄 명령에 Anthropic 서버가 계산한 사용량(5시간·주간 %와 각 리셋 시각)을 넘겨 줍니다. 스킬은 이 값을 직접 볼 수 없어서, 이 값을 파일로 저장하는 작은 래퍼를 함께 넣었습니다.

첫 실행 때 스킬이 설치할지 한 번 묻습니다. 직접 할 수도 있습니다.

```bash
bash ~/.claude/skills/plan-efficient/install.sh install    # settings.json 백업 후 상태줄을 감쌉니다
bash ~/.claude/skills/plan-efficient/install.sh status
bash ~/.claude/skills/plan-efficient/install.sh uninstall  # 원래 상태줄로 되돌립니다
```

- 이미 상태줄을 쓰고 있으면 화면은 그대로입니다. 래퍼가 같은 입력으로 원래 상태줄을 실행합니다.
- 상태줄이 없으면 `5h 29% · 7d 59%` 같은 짧은 한 줄이 나옵니다.
- `jq`가 있으면 `jq`를, 없으면 Python을 씁니다. 둘 다 없으면 원본 JSON을 그대로 저장하고 스킬이 그것을 읽습니다.
- 이 값은 Pro/Max 구독자에게만, 세션의 첫 응답 이후에만 나옵니다. 값이 없으면 아래의 추정 방식으로 진행합니다.
- 상태줄 갱신이 조금 느려집니다. Windows(Git Bash)에서 한 번에 약 0.25초 늘어났고, macOS/Linux는 보통 더 짧습니다.

연결하면 계획에 지금 5시간·주간 %가 각각, 리셋까지 남은 시간과 함께 나옵니다. 작업 전후 값을 비교해 추정치도 스스로 보정합니다.

## 토큰 추정에 대해

Anthropic은 5시간 한도를 토큰 수로 공개하지 않습니다. 그래서 `budget.md`의 한도 값은 시작용 어림값이고, 처음 몇 번은 ±50% 정도 틀릴 수 있습니다. 첫 실행 때 요금제(Pro / Max 5x / Max 20x)를 한 번 묻습니다. 상태줄 연결이 있으면 작업 전후 서버 값으로 자동 보정하고, 없으면 실행 뒤 실제 사용량 %를 알려 주면 그 기록으로 고쳐 갑니다.

## 출처

[ECC](https://github.com/affaan-m/ECC)의 `/plan`과 `/model-route` 명령(MIT License, Copyright (c) 2026 Affaan Mustafa)을 바탕으로 고쳐 썼습니다. 원본 라이선스는 [`skills/plan-efficient/LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC)에 있습니다.

## 라이선스

저작권자 전용(All rights reserved). 구매자 본인만 쓸 수 있고, 재배포와 재판매는 허용하지 않습니다. 자세한 내용은 [LICENSE](LICENSE)에 있습니다. ECC에서 가져온 부분은 계속 MIT License를 따릅니다([`LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC)).
