#!/usr/bin/env bash
# plan-efficient 상태줄 연결 설치/제거
#
#   bash install.sh status     # installed | not-installed | no-settings
#   bash install.sh install    # settings.json 백업 후 statusLine 을 래퍼로 감싼다
#   bash install.sh uninstall  # 원래 statusLine 으로 되돌린다
#
# 원래 statusLine.command 는 statusline-original.txt 에 옮겨 두고,
# usage-snapshot.sh 가 같은 입력으로 그 명령을 그대로 실행한다.
# settings.json 편집 도구 순서: jq → Python. 둘 다 없으면 수동 안내를 출력한다.

set -u
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
settings="$cfg/settings.json"
orig_file="$dir/statusline-original.txt"
# 홈 폴더 아래이고 경로에 공백이 없으면 ~ 형태로 쓴다(기기 이름에 덜 묶임)
case "$dir" in
  "$HOME"/*) rel="~${dir#"$HOME"}" ;;
  *) rel="" ;;
esac
if [ -n "$rel" ] && [ "${rel#* }" = "$rel" ]; then
  wrapper_cmd="bash $rel/usage-snapshot.sh"
else
  wrapper_cmd="bash \"$dir/usage-snapshot.sh\""
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
    jq -r '.statusLine.command // empty' "$settings"
  elif py=$(find_python); then
    "$py" -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); print((d.get("statusLine") or {}).get("command",""))' "$settings"
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

manual() {
  cat <<EOF
jq 와 Python 이 모두 없어 settings.json 을 자동으로 고칠 수 없습니다.
$settings 에서 statusLine 을 아래처럼 직접 바꿔 주세요.

  "statusLine": { "type": "command", "command": "$(printf '%s' "$wrapper_cmd" | sed 's/"/\\"/g')" }

원래 쓰던 상태줄 명령이 있었다면 그 명령을 한 줄로
$orig_file 에 저장하면 화면이 예전처럼 유지됩니다.
EOF
}

case "${1:-status}" in
  usage)
    # 스킬이 읽는 요약. key=value 한 줄씩. 값이 없으면 그 줄을 비운다.
    usage_file="$dir/usage.json"
    st=$("$0" status)
    echo "status=$st"
    [ -f "$usage_file" ] || { echo "snapshot=none"; exit 0; }
    now=$(date +%s)
    if have_jq && jq -e . "$usage_file" >/dev/null 2>&1; then
      jq -r --argjson now "$now" '
        (if .via == "raw" then .raw else . end) as $d
        | ($d.rate_limits // {}) as $rl
        | "snapshot=ok", "via=\(.via)", "age_sec=\($now - .ts)",
          "session_id=\($d.session_id // "")",
          "five_hour_pct=\($rl.five_hour.used_percentage // "")",
          "five_hour_resets_in_sec=\(if $rl.five_hour.resets_at then $rl.five_hour.resets_at - $now else "" end)",
          "seven_day_pct=\($rl.seven_day.used_percentage // "")",
          "seven_day_resets_in_sec=\(if $rl.seven_day.resets_at then $rl.seven_day.resets_at - $now else "" end)",
          "cost_usd=\($d.cost.total_cost_usd // "")"' "$usage_file" | tr -d '\r'
    elif py=$(find_python); then
      "$py" -c '
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
print("seven_day_pct=%s" % nz(g("seven_day", "used_percentage")))
print("seven_day_resets_in_sec=%s" % left("seven_day"))
print("cost_usd=%s" % nz((d.get("cost") or {}).get("total_cost_usd")))
' "$usage_file" "$now" | tr -d '\r'
    else
      echo "snapshot=unparsed"; echo "now=$now"; echo "file=$usage_file"
    fi
    ;;
  status)
    [ -f "$settings" ] || { echo "no-settings"; exit 0; }
    cur=$(get_cmd) || { echo "unknown (jq/python 없음)"; exit 0; }
    case "$cur" in *usage-snapshot.sh*) echo "installed" ;; *) echo "not-installed" ;; esac
    ;;
  install)
    cur=$(get_cmd) || { manual; exit 2; }
    case "$cur" in *usage-snapshot.sh*) echo "이미 설치되어 있습니다."; exit 0 ;; esac
    if [ -f "$settings" ]; then
      bak="$settings.plan-efficient.bak"
      [ -e "$bak" ] && bak="$settings.plan-efficient.$(date +%Y%m%d%H%M%S).bak"
      cp "$settings" "$bak" && echo "백업: $bak"
    fi
    printf '%s' "$cur" > "$orig_file"
    if set_cmd "$wrapper_cmd"; then
      echo "설치 완료. 원래 상태줄: ${cur:-(없음)}"
      echo "다음 응답부터 $dir/usage.json 에 사용량이 저장됩니다."
    else
      echo "settings.json 을 고치지 못했습니다. 백업은 그대로 있습니다."; exit 1
    fi
    ;;
  uninstall)
    cur=$(get_cmd) || { echo "jq/python 이 없어 자동 제거를 못 합니다. 백업 파일로 되돌려 주세요."; exit 2; }
    case "$cur" in *usage-snapshot.sh*) ;; *) echo "설치되어 있지 않습니다."; exit 0 ;; esac
    orig=""; [ -f "$orig_file" ] && orig=$(cat "$orig_file")
    set_cmd "$orig" || { echo "settings.json 을 고치지 못했습니다."; exit 1; }
    rm -f "$orig_file" "$dir/usage.json"
    echo "제거 완료. 상태줄: ${orig:-(없음)}"
    ;;
  *)
    echo "사용법: bash install.sh [status|install|uninstall]"; exit 1 ;;
esac
