#!/usr/bin/env bash
# plan-efficient 1.1 호환용 입구. 실제 일은 공용 연결(bridge/install.sh)이 한다.
#   bash install.sh status | install | uninstall | usage
# install / uninstall / usage 는 스킬 이름(plan-efficient)을 붙여 넘긴다.
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
case "${1:-status}" in
  install|uninstall|usage) exec bash "$dir/bridge/install.sh" "$1" plan-efficient ;;
  *) exec bash "$dir/bridge/install.sh" "$@" ;;
esac
