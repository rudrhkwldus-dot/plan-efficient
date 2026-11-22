#!/usr/bin/env bash
# plan-efficient 상태줄 래퍼
#
# Claude Code가 상태줄 명령에 stdin으로 넘기는 세션 JSON에서
# 서버가 계산한 사용량(5h / 7d %)과 리셋 시각을 usage.json 에 저장한다.
# 그다음 원래 쓰던 상태줄 명령(statusline-original.txt)에 같은 입력을 넘겨
# 화면은 예전과 똑같이 둔다. 원래 명령이 없으면 짧은 사용량 한 줄을 보여 준다.
#
# 파싱 도구 순서: jq → Python → (둘 다 없으면) 원본 JSON 그대로 저장
# install.sh 가 settings.json 의 statusLine.command 를 이 스크립트로 바꾼다.

input=$(cat)
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
out="$dir/usage.json"
orig_file="$dir/statusline-original.txt"
now=$(date +%s)
orig=""
[ -f "$orig_file" ] && orig=$(cat "$orig_file")

# 실제로 실행되는 Python을 찾는다 (Windows의 python3 스토어 바로가기는 건너뛴다)
find_python() {
  local p
  for p in python3 python; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import json' >/dev/null 2>&1; then
      echo "$p"; return 0
    fi
  done
  return 1
}

# ── 1) 사용량 스냅숏 저장 (실패해도 상태줄 표시는 계속) ──────
tmp="$out.tmp.$$"
saved=0
h5=""; d7=""
if command -v jq >/dev/null 2>&1; then
  if printf '%s' "$input" | jq -c --argjson ts "$now" \
      'select(.rate_limits != null) | {ts: $ts, via: "jq", session_id, rate_limits, cost}' > "$tmp" 2>/dev/null; then
    [ -s "$tmp" ] && saved=1
    # 한 줄 표시용 값은 원래 상태줄이 없을 때만 뽑는다(jq 호출 절약)
    [ "$saved" -eq 1 ] && [ -z "$orig" ] && read -r h5 d7 < <(jq -r '[.rate_limits.five_hour.used_percentage, .rate_limits.seven_day.used_percentage] | map(if . == null then "" else (floor | tostring) end) | join(" ")' "$tmp" 2>/dev/null)
  fi
fi
# jq가 설치돼 있어도 실행에 실패했으면(손상 등) Python으로 넘어간다. 값이 없어서 건너뛴 경우는 제외.
skip=0
[ "$saved" -eq 0 ] && command -v jq >/dev/null 2>&1 && printf '%s' "$input" | jq -e '.rate_limits == null' >/dev/null 2>&1 && skip=1
if [ "$saved" -eq 0 ] && [ "$skip" -eq 0 ] && py=$(find_python); then
  if printf '%s' "$input" | "$py" -c '
import json, sys
ts = int(sys.argv[1]); d = json.load(sys.stdin)
if not d.get("rate_limits"): sys.exit(3)
snap = {"ts": ts, "via": "python", "session_id": d.get("session_id"),
        "rate_limits": d.get("rate_limits"), "cost": d.get("cost")}
json.dump(snap, open(sys.argv[2], "w", encoding="utf-8"))
rl = d.get("rate_limits") or {}
def pct(k):
    v = (rl.get(k) or {}).get("used_percentage")
    return "" if v is None else str(int(v))
print(pct("five_hour") + " " + pct("seven_day"))
' "$now" "$tmp" > "$tmp.pct" 2>/dev/null; then
    [ -s "$tmp" ] && saved=1
    read -r h5 d7 < "$tmp.pct"
  fi
  rm -f "$tmp.pct"
fi
if [ "$saved" -eq 0 ] && [ "$skip" -eq 0 ] && [ -z "${py:-}" ] && printf '%s' "$input" | grep -q '"rate_limits"[[:space:]]*:[[:space:]]*{'; then
  # 파싱 도구가 없으면 원본을 그대로 넣는다. 스킬이 raw.rate_limits 를 읽는다.
  # (rate_limits 가 없는 갱신은 저장하지 않아 이전 스냅숏을 지킨다)
  printf '{"ts":%s,"via":"raw","raw":%s}\n' "$now" "$input" > "$tmp" && saved=1
  h5=$(printf '%s' "$input" | tr -d '\n' | sed -n 's/.*"five_hour"[^}]*"used_percentage":[ ]*\([0-9]*\).*/\1/p')
  d7=$(printf '%s' "$input" | tr -d '\n' | sed -n 's/.*"seven_day"[^}]*"used_percentage":[ ]*\([0-9]*\).*/\1/p')
fi
if [ "$saved" -eq 1 ]; then mv -f "$tmp" "$out" 2>/dev/null || rm -f "$tmp"; else rm -f "$tmp"; fi

# ── 2) 원래 상태줄 실행, 없으면 사용량 한 줄 ─────────────────
if [ -n "$orig" ]; then
  printf '%s' "$input" | bash -c "$orig"
else
  h5=${h5//$'\r'/}; d7=${d7//$'\r'/}   # Windows의 jq/Python 출력에 붙는 CR 제거
  line=""
  [ -n "$h5" ] && line="5h ${h5}%"
  if [ -n "$d7" ]; then
    [ -n "$line" ] && line="$line · "
    line="${line}7d ${d7}%"
  fi
  [ -n "$line" ] && echo "$line"
fi
exit 0
