# plan-efficient 예산 설정

plan: unset            # Pro | Max 5x | Max 20x  (첫 실행 때 한 번 묻고 채운다)
5h_budget_tokens: unset  # Sonnet 기준 가중 토큰. 요금제를 정하면 아래 기본값으로 채운다
7d_budget_tokens: unknown  # 기본값 없음. 서버 값으로 보정하면 채워진다
calibrated: no         # 같은 주 모델 표본이 2개 이상일 때만 yes
statusline: unset      # unset | installed | declined  (상태줄 연결 설치를 한 번만 묻는다)

## 요금제별 기본값(보정 전 추정)

Anthropic은 5시간 한도를 토큰 수로 공개하지 않는다. 아래는 근거가 확인되지 않은 시작용 어림값이고, 실제 사용 후 보정한다.
Max 5x와 20x는 Pro의 5배, 20배라는 공식 배율만 따른다.

| 요금제 | 5h_budget_tokens |
|---|---|
| Pro | 1,000,000 |
| Max 5x | 5,000,000 |
| Max 20x | 20,000,000 |

## 보정 기록

| 날짜 | 작업 | 주 모델 | 예상 가중 토큰 | 5h Δ% | 7d Δ% | 비용 Δ$ | 출처 | 조정 후 5h 한도 | 조정 후 7d 한도 |
|---|---|---|---|---|---|---|---|---|---|
