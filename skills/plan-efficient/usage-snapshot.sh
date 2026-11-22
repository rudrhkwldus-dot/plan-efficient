#!/usr/bin/env bash
# plan-efficient 1.1 호환용 상태줄 입구.
# 1.1 에서 설치한 사용자의 settings.json 은 아직 이 파일을 가리킬 수 있다.
# 공용 연결(~/.claude/usage-bridge)이 있으면 그쪽으로 넘기고, 없으면 원래 상태줄만 보여 준다.
# 스킬을 한 번 실행하면 install.sh 가 settings.json 을 공용 연결로 옮긴다.
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
[ -f "$cfg/usage-bridge/usage-snapshot.sh" ] && exec bash "$cfg/usage-bridge/usage-snapshot.sh"
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
for f in "$dir/statusline-original.txt" "${PLAN_EFFICIENT_HOME:-$cfg/plan-efficient}/statusline-original.txt"; do
  [ -s "$f" ] && exec bash -c "$(cat "$f")"
done
cat >/dev/null
exit 0
