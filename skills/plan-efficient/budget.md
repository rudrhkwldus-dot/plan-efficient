# plan-efficient 예산 설정

plan: unset            # Pro | Max 5x | Max 20x  (첫 실행 때 한 번 묻고 채운다)
5h_budget_tokens: unset  # Sonnet 기준 가중 토큰. 요금제를 정하면 아래 기본값으로 채운다
calibrated: no

## 요금제별 기본값(보정 전 추정)

Anthropic은 5시간 한도를 토큰 수로 공개하지 않는다. 아래는 시작용 어림값이고, 실제 사용 후 보정한다.
Max 5x와 20x는 Pro의 5배, 20배라는 공식 배율만 따른다.

| 요금제 | 5h_budget_tokens |
|---|---|
| Pro | 1,000,000 |
| Max 5x | 5,000,000 |
| Max 20x | 20,000,000 |

## 보정 기록

| 날짜 | 작업 | 예상 % | 실제 % | 조정 후 한도 |
|---|---|---|---|---|
