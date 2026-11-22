#!/usr/bin/env bash
# plan-efficient 입구 스크립트
#
#   bash install.sh status     # installed | legacy | not-installed | no-settings | unknown
#   bash install.sh install    # 공용 상태줄 연결을 깔거나 이 스킬을 등록한다(settings.json 백업)
#   bash install.sh uninstall  # 이 스킬 등록을 지운다. 다른 스킬이 안 쓰면 원래 상태줄로 되돌린다
#   bash install.sh usage      # 스킬이 읽는 요약(key=value). 개인 파일 이전·생성도 함께 한다
#   bash install.sh migrate    # 1.1의 개인 파일을 스킬 폴더 밖으로 옮긴다
#
# 상태줄 연결과 사용량은 smartwork와 같이 쓰는 공용 연결(bridge/ → ~/.claude/usage-bridge/)이 맡는다.
# 이 스킬의 개인 파일(budget.md)은 ~/.claude/plan-efficient/ 에 둔다. 스킬을 덮어써도 남는다.

set -u
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
state="${PLAN_EFFICIENT_HOME:-$cfg/plan-efficient}"
template="$dir/references/budget-template.md"
bridge_sh="$dir/bridge/install.sh"

# 1.1은 budget.md 를 스킬 폴더 안에 두었다. 새 위치에 없을 때만 옮긴다(덮어쓰지 않음).
# statusline-original.txt 는 옮기지 않는다. 공용 연결이 1.1 연결을 옮길 때 스킬 폴더에서 읽는다.
migrate() {
  local moved=""
  mkdir -p "$state" || return 1
  if [ -f "$dir/budget.md" ] && [ ! -e "$state/budget.md" ]; then
    mv "$dir/budget.md" "$state/budget.md" && moved="budget.md"
  fi
  # 1.2 개발판이 원래 상태줄 명령을 개인 폴더로 옮겨 둔 경우, 공용 연결이 찾을 수 있게 되돌려 둔다
  if [ -f "$state/statusline-original.txt" ] && [ ! -e "$dir/statusline-original.txt" ]; then
    cp "$state/statusline-original.txt" "$dir/statusline-original.txt"
  fi
  echo "$moved"
}

case "${1:-status}" in
  usage)
    bash "$bridge_sh" usage plan-efficient
    echo "state_dir=$state"
    m=$(migrate); [ -n "$m" ] && echo "migrated=$m"
    if [ -f "$state/budget.md" ]; then echo "settings=present"
    elif [ -f "$template" ] && cp "$template" "$state/budget.md"; then echo "settings=created"
    else echo "settings=missing"; fi
    ;;
  migrate)
    m=$(migrate); echo "state_dir=$state"; echo "migrated=${m:-(없음)}"
    ;;
  install)
    migrate >/dev/null
    exec bash "$bridge_sh" install plan-efficient
    ;;
  uninstall)
    exec bash "$bridge_sh" uninstall plan-efficient   # budget.md(보정 기록)는 남긴다
    ;;
  status)
    exec bash "$bridge_sh" status
    ;;
  *)
    echo "사용법: bash install.sh [status|install|uninstall|usage|migrate]"; exit 1 ;;
esac
