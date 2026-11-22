# plan-efficient

Claude Code용 `/plan`. 헛도는 반복은 빼고 필요한 검증은 남긴 계획을 짜고, 5시간 한도를 몇 % 쓸지, 얼마나 걸릴지, 단계마다 어떤 모델과 effort가 맞는지 알려 줍니다. 계획을 보여 준 뒤에는 승인할 때까지 파일을 건드리지 않습니다.

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

- `--used`: 지금 5시간 창에서 이미 쓴 비율. 주면 끝났을 때의 누적 %까지 계산합니다.
- `--budget`: 모델 추천에 쓰는 예산 등급. 생략하면 남은 비율로 정합니다.

출력에는 단계별 할 일, 완료 기준, 재시도 상한, 추천 모델과 effort, 예상 토큰과 시간이 들어갑니다.

## 토큰 추정에 대해

Anthropic은 5시간 한도를 토큰 수로 공개하지 않습니다. 그래서 `budget.md`의 한도 값은 시작용 어림값이고, 처음 몇 번은 ±50% 정도 틀릴 수 있습니다. 첫 실행 때 요금제(Pro / Max 5x / Max 20x)를 한 번 묻고, 실행 뒤 실제 사용량 %를 알려 주면 그 기록으로 한도 값을 고쳐 갑니다.

## 출처

[ECC](https://github.com/affaan-m/ECC)의 `/plan`과 `/model-route` 명령(MIT License, Copyright (c) 2026 Affaan Mustafa)을 바탕으로 고쳐 썼습니다. 원본 라이선스는 [`skills/plan-efficient/LICENSE-ECC`](skills/plan-efficient/LICENSE-ECC)에 있습니다.

## 라이선스

[MIT](LICENSE)
