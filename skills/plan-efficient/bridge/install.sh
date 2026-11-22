#!/usr/bin/env bash
# usage-bridge: plan-efficient · smart-work 공용 상태줄 연결
#
#   bash install.sh status                 # installed | legacy | not-installed | no-settings
#   bash install.sh install <스킬이름>      # 공용 연결을 깔거나(없으면), 이 스킬을 사용자로 등록
#   bash install.sh uninstall <스킬이름>    # 등록만 지운다. 아무 스킬도 안 쓰면 원래 상태줄로 되돌린다
#   bash install.sh uninstall --all        # 등록과 상관없이 연결을 없앤다
#   bash install.sh usage [스킬이름]        # 스킬이 읽는 사용량 요약(key=value). 연결돼 있으면 이 스킬도 등록
#
# 공용 연결은 ~/.claude/usage-bridge/ 에 둔다(스킬 폴더 밖).
#   usage-snapshot.sh  상태줄이 가리키는 유일한 스크립트
#   install.sh         이 파일의 사본(스킬 폴더를 지운 뒤에도 제거할 수 있게)
#   usage.json         사용량 스냅숏(두 스킬이 같이 읽는다)
#   original.txt       원래 쓰던 statusLine.command
#   users.txt          이 연결을 쓰는 스킬 이름, 한 줄에 하나
#   config             멈춤 기준 등 공용 설정(key=value)
#   VERSION            정수. 스킬에 든 사본이 더 높으면 파일만 바꾼다(settings.json은 그대로)
#
# plan-efficient 1.1 이 스킬 폴더 안에 깐 연결(legacy)은 install 때 자동으로 옮긴다.
# settings.json 편집 도구 순서: jq → Python. 둘 다 없으면 수동 안내를 출력한다.

set -u
src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
settings="$cfg/settings.json"
bridge="$cfg/usage-bridge"

# 홈 폴더 아래이고 경로에 공백이 없으면 ~ 형태로 쓴다(기기 이름에 덜 묶임)
case "$bridge" in
  "$HOME"/*) rel="~${bridge#"$HOME"}" ;;
  *) rel="" ;;
esac
if [ -n "$rel" ] && [ "${rel#* }" = "$rel" ]; then
  wrapper_cmd="bash $rel/usage-snapshot.sh"
else
  wrapper_cmd="bash \"$bridge/usage-snapshot.sh\""
fi

find_python() {
  local p
  for p in python3 python; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import json' >/dev/null 2>&1; then
      echo "$p"; return 0
    fi
  done
  return 1
}

# jq가 있고 실제로 실행되는지
have_jq() { command -v jq >/dev/null 2>&1 && jq -n 1 >/dev/null 2>&1; }

# 현재 statusLine.command 읽기 (없으면 빈 문자열)
get_cmd() {
  [ -f "$settings" ] || { echo ""; return 0; }
  if have_jq; then
    jq -r '.statusLine.command // empty' "$settings" | tr -d '\r'
  elif py=$(find_python); then
    "$py" -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); print((d.get("statusLine") or {}).get("command",""))' "$settings" | tr -d '\r'
  else
    return 2
  fi
}

# statusLine 설정. 인자가 빈 문자열이면 statusLine 키를 지운다.
set_cmd() {
  local cmd="$1" tmp="$settings.tmp.$$"
  [ -f "$settings" ] || echo '{}' > "$settings"
  if have_jq; then
    if [ -n "$cmd" ]; then
      jq --arg c "$cmd" '.statusLine = ((.statusLine // {}) + {type: "command", command: $c})' "$settings" > "$tmp"
    else
      jq 'del(.statusLine)' "$settings" > "$tmp"
    fi
  elif py=$(find_python); then
    "$py" -c '
import json, sys
path, cmd, out = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(path, encoding="utf-8"))
if cmd:
    sl = d.get("statusLine") or {}
    sl.update({"type": "command", "command": cmd})
    d["statusLine"] = sl
else:
    d.pop("statusLine", None)
json.dump(d, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
' "$settings" "$cmd" "$tmp"
  else
    return 2
  fi && [ -s "$tmp" ] && mv -f "$tmp" "$settings" || { rm -f "$tmp"; return 1; }
}

backup_settings() {
  [ -f "$settings" ] || return 0
  local bak="$settings.usage-bridge.bak"
  [ -e "$bak" ] && bak="$settings.usage-bridge.$(date +%Y%m%d%H%M%S).bak"
  cp "$settings" "$bak" && echo "백업: $bak"
}

ver_of() { local v=""; [ -f "$1" ] && v=$(tr -dc '0-9' < "$1"); echo "${v:-0}"; }

# 이 스크립트 옆의 파일을 공용 폴더로 복사한다. 공용 쪽 버전이 같거나 높으면 그대로 둔다.
sync_files() {
  mkdir -p "$bridge" || return 1
  [ -f "$bridge/config" ] || printf 'five_hour_stop=85\nseven_day_stop=90\n' > "$bridge/config"
  [ "$src" = "$bridge" ] && return 0
  local mine theirs f
  mine=$(ver_of "$src/VERSION"); theirs=$(ver_of "$bridge/VERSION")
  if [ "$mine" -gt "$theirs" ] || [ ! -f "$bridge/usage-snapshot.sh" ]; then
    for f in usage-snapshot.sh install.sh VERSION; do
      cp "$src/$f" "$bridge/$f.tmp.$$" && mv -f "$bridge/$f.tmp.$$" "$bridge/$f" || return 1
    done
    [ "$theirs" -gt 0 ] && echo "공용 연결 업데이트: v$theirs → v$mine"
  fi
  return 0
}

add_user() {
  [ -n "${1:-}" ] || return 0
  touch "$bridge/users.txt"
  grep -qxF "$1" "$bridge/users.txt" || echo "$1" >> "$bridge/users.txt"
}

users_list() { [ -f "$bridge/users.txt" ] && grep -v '^[[:space:]]*$' "$bridge/users.txt" | tr '\n' ' ' | sed 's/ $//'; }

# legacy 명령에서 usage-snapshot.sh 가 있는 폴더를 뽑는다
legacy_dir() {
  local p
  p=$(printf '%s' "$1" | grep -o '[^" ]*usage-snapshot\.sh' | head -1)
  p="${p/#\~/$HOME}"
  [ -n "$p" ] && dirname "$p"
}

classify() {
  case "$1" in
    *usage-bridge/usage-snapshot.sh*) echo "installed" ;;
    *usage-snapshot.sh*) echo "legacy" ;;
    *) echo "not-installed" ;;
  esac
}

manual() {
  cat <<EOF
jq 와 Python 이 모두 없어 settings.json 을 자동으로 고칠 수 없습니다.
$settings 에서 statusLine 을 아래처럼 직접 바꿔 주세요.

  "statusLine": { "type": "command", "command": "$(printf '%s' "$wrapper_cmd" | sed 's/"/\\"/g')" }

원래 쓰던 상태줄 명령이 있었다면 그 명령을 한 줄로
$bridge/original.txt 에 저장하면 화면이 예전처럼 유지됩니다.
EOF
}

do_status() {
  [ -f "$settings" ] || { echo "no-settings"; return 0; }
  local cur
  cur=$(get_cmd) || { echo "unknown"; return 0; }
  classify "$cur"
}

do_install() {
  local name="${1:-}" cur kind ldir
  cur=$(get_cmd) || { manual; return 2; }
  sync_files || { echo "공용 폴더($bridge)를 만들지 못했습니다."; return 1; }
  kind=$(classify "$cur")
  case "$kind" in
    installed)
      add_user "$name"
      echo "이미 연결되어 있습니다. 사용 중인 스킬: $(users_list)"
      return 0 ;;
    legacy)
      # plan-efficient 1.1: 원래 명령은 그 폴더의 statusline-original.txt 에 있다
      ldir=$(legacy_dir "$cur")
      if [ -n "$ldir" ] && [ -f "$ldir/statusline-original.txt" ]; then
        cp "$ldir/statusline-original.txt" "$bridge/original.txt"
      else
        : > "$bridge/original.txt"
      fi
      [ -n "$ldir" ] && [ -f "$ldir/usage.json" ] && [ ! -f "$bridge/usage.json" ] && cp "$ldir/usage.json" "$bridge/usage.json"
      case "$ldir" in *plan-efficient*) add_user "plan-efficient" ;; esac
      backup_settings
      set_cmd "$wrapper_cmd" || { echo "settings.json 을 고치지 못했습니다. 백업은 그대로 있습니다."; return 1; }
      add_user "$name"
      echo "이전 연결(plan-efficient 1.1)을 공용 연결로 옮겼습니다. 원래 상태줄: $(cat "$bridge/original.txt" 2>/dev/null)"
      echo "사용 중인 스킬: $(users_list)"
      return 0 ;;
    *)
      backup_settings
      printf '%s' "$cur" > "$bridge/original.txt"
      set_cmd "$wrapper_cmd" || { echo "settings.json 을 고치지 못했습니다. 백업은 그대로 있습니다."; return 1; }
      add_user "$name"
      echo "설치 완료. 원래 상태줄: ${cur:-(없음)}"
      echo "다음 응답부터 $bridge/usage.json 에 사용량이 저장됩니다."
      return 0 ;;
  esac
}

do_uninstall() {
  local name="${1:-}" cur orig left
  if [ -z "$name" ]; then echo "사용법: bash install.sh uninstall <스킬이름|--all>"; return 1; fi
  if [ "$name" != "--all" ] && [ -f "$bridge/users.txt" ]; then
    grep -vxF "$name" "$bridge/users.txt" > "$bridge/users.txt.tmp.$$"
    mv -f "$bridge/users.txt.tmp.$$" "$bridge/users.txt"
    left=$(users_list)
    if [ -n "$left" ]; then
      echo "$name 등록만 지웠습니다. 다른 스킬($left)이 쓰고 있어 연결은 남겨 둡니다."
      return 0
    fi
  fi
  cur=$(get_cmd) || { echo "jq/python 이 없어 자동 제거를 못 합니다. settings.json 백업 파일로 되돌려 주세요."; return 2; }
  if [ "$(classify "$cur")" = "installed" ]; then
    orig=""; [ -f "$bridge/original.txt" ] && orig=$(cat "$bridge/original.txt")
    set_cmd "$orig" || { echo "settings.json 을 고치지 못했습니다."; return 1; }
    echo "제거 완료. 상태줄: ${orig:-(없음)}"
  else
    echo "상태줄이 공용 연결을 가리키지 않아 settings.json 은 그대로 둡니다."
  fi
  rm -f "$bridge/usage-snapshot.sh" "$bridge/usage.json" "$bridge/original.txt" \
        "$bridge/users.txt" "$bridge/config" "$bridge/VERSION" "$bridge/install.sh"
  rmdir "$bridge" 2>/dev/null
  return 0
}

conf_get() {
  local v=""
  [ -f "$bridge/config" ] && v=$(grep -E "^$1=" "$bridge/config" | tail -1 | cut -d= -f2 | tr -dc '0-9')
  echo "${v:-$2}"
}

do_usage() {
  local name="${1:-}" st usage_file now body p5 p7 r5 r7 s5 s7 over
  st=$(do_status)
  echo "status=$st"
  if [ "$st" = "installed" ]; then
    sync_files >/dev/null 2>&1
    add_user "$name"
  fi
  s5=$(conf_get five_hour_stop 85); s7=$(conf_get seven_day_stop 90)
  echo "five_hour_stop=$s5"; echo "seven_day_stop=$s7"
  usage_file="$bridge/usage.json"
  [ "$st" = "legacy" ] && { local ld; ld=$(legacy_dir "$(get_cmd)"); [ -n "$ld" ] && usage_file="$ld/usage.json"; }
  [ -f "$usage_file" ] || { echo "snapshot=none"; return 0; }
  now=$(date +%s)
  if have_jq && jq -e . "$usage_file" >/dev/null 2>&1; then
    body=$(jq -r --argjson now "$now" '
      (if .via == "raw" then .raw else . end) as $d
      | ($d.rate_limits // {}) as $rl
      | "snapshot=ok", "via=\(.via)", "age_sec=\($now - .ts)",
        "session_id=\($d.session_id // "")",
        "five_hour_pct=\($rl.five_hour.used_percentage // "")",
        "five_hour_resets_in_sec=\(if $rl.five_hour.resets_at then $rl.five_hour.resets_at - $now else "" end)",
        "five_hour_resets_at=\($rl.five_hour.resets_at // "")",
        "seven_day_pct=\($rl.seven_day.used_percentage // "")",
        "seven_day_resets_in_sec=\(if $rl.seven_day.resets_at then $rl.seven_day.resets_at - $now else "" end)",
        "seven_day_resets_at=\($rl.seven_day.resets_at // "")",
        "cost_usd=\($d.cost.total_cost_usd // "")"' "$usage_file" | tr -d '\r')
  elif py=$(find_python); then
    body=$("$py" -c '
import json, sys
now = int(sys.argv[2]); s = json.load(open(sys.argv[1], encoding="utf-8"))
d = s.get("raw") if s.get("via") == "raw" else s
rl = d.get("rate_limits") or {}
def g(k, f):
    return (rl.get(k) or {}).get(f)
def left(k):
    r = g(k, "resets_at"); return "" if r is None else r - now
def nz(v): return "" if v is None else v
print("snapshot=ok"); print("via=%s" % s.get("via")); print("age_sec=%s" % (now - s["ts"]))
print("session_id=%s" % nz(d.get("session_id")))
print("five_hour_pct=%s" % nz(g("five_hour", "used_percentage")))
print("five_hour_resets_in_sec=%s" % left("five_hour"))
print("five_hour_resets_at=%s" % nz(g("five_hour", "resets_at")))
print("seven_day_pct=%s" % nz(g("seven_day", "used_percentage")))
print("seven_day_resets_in_sec=%s" % left("seven_day"))
print("seven_day_resets_at=%s" % nz(g("seven_day", "resets_at")))
print("cost_usd=%s" % nz((d.get("cost") or {}).get("total_cost_usd")))
' "$usage_file" "$now" | tr -d '\r')
  else
    echo "snapshot=unparsed"; echo "now=$now"; echo "file=$usage_file"
    return 0
  fi
  echo "$body"
  # 멈춤 판정. 리셋 시각이 지난 창은 0%로 본다.
  kv() { printf '%s\n' "$body" | grep -E "^$1=" | head -1 | cut -d= -f2; }
  p5=$(kv five_hour_pct); p5=${p5%%.*}; r5=$(kv five_hour_resets_in_sec)
  p7=$(kv seven_day_pct); p7=${p7%%.*}; r7=$(kv seven_day_resets_in_sec)
  [ -n "$r5" ] && [ "${r5%%.*}" -le 0 ] 2>/dev/null && p5=0
  [ -n "$r7" ] && [ "${r7%%.*}" -le 0 ] 2>/dev/null && p7=0
  over=""
  [ -n "$p5" ] && [ "$p5" -ge "$s5" ] 2>/dev/null && over="five_hour"
  [ -n "$p7" ] && [ "$p7" -ge "$s7" ] 2>/dev/null && over="${over:+$over,}seven_day"
  echo "over=${over:-none}"
}

main() {
  case "${1:-status}" in
    status)    do_status ;;
    install)   do_install "${2:-}" ;;
    uninstall) do_uninstall "${2:-}" ;;
    usage)     do_usage "${2:-}" ;;
    *) echo "사용법: bash install.sh [status|install <스킬>|uninstall <스킬|--all>|usage [스킬]]"; return 1 ;;
  esac
}
# 함수 안에서 끝까지 실행한 뒤 종료한다(uninstall 이 공용 폴더의 이 파일을 지워도 안전)
main "$@"; exit $?
