# ADB Mesh 자동 복구 솔루션

> **2026-05-03 확정** — WSL/폰/탭 3노드 mesh ADB 페어링 + 8초 자동 복구 스크립트.
> 박씨 손길 0, 보안 타임아웃 우회.

## 문제 정의

기기 간 원격 제어(ADB) 설계 흐름:

```
[옛날]
WSL ─→ 폰  (USB 페어링 1회)
WSL ─→ 탭  (USB 페어링 1회)
폰 ─×─ 탭  (모르는 사이)
```

**병목 4가지** (왜 박씨 자력으로 어려웠나):

| # | 항목 | 영향 |
|---|------|------|
| 1 | 페어링 코드 60초 타임아웃 | STT 환경에서 6자리 코드 + 5자리 포트 정확히 부르기 거의 불가 |
| 2 | 무선디버깅 포트가 부팅마다 랜덤 변경 | 영구 5555 같은 고정 포트 없음 (Android 보안 설계) |
| 3 | mDNS 자동 발견이 Tailscale 위에선 불가 | 멀티캐스트 라우팅 안 됨 → LAN 같은 서브넷 아니면 자동 발견 안 됨 |
| 4 | WSL은 USB 직접 못 봄 | Windows adb.exe(`C:\platform-tools\adb.exe`) 우회 필수 |

**결과적 시나리오**: 가게에서 폰 재부팅 → 폰 ADB 끊김 → 탭에서 살리려 함 → "탭은 폰 친구가 아니라" 거부 → 박씨가 USB 케이블 들고 집에 와야 함.

## 솔루션 — 3노드 mesh + nmap 자동 복구

### Step 1. mesh 페어링 (1회만 영구)

```
[지금]
WSL ←→ 폰  (USB 페어링 1회)
WSL ←→ 탭  (자동 페어링)
폰  ←→ 탭  (양방향 페어링) ★ 핵심
```

페어링은 영구 저장. 디바이스의 무선 디버깅 화면 "페어링된 기기" 목록에서 확인 가능.

**검증된 페어링 흐름** (60초 타임아웃 우회):

1. 한쪽 디바이스에서 ADB로 페어링 다이얼로그 자동 띄우기
   - 인텐트 안 됨 (Activity not found) → **UI 덤프 + 좌표 tap** 우회
2. 페어링 다이얼로그 화면을 ADB 스크린캡쳐 → 이미지로 직접 읽음 (페어링 코드/포트 자동 추출)
3. 추출 즉시 SSH로 반대편 디바이스에 `adb pair IP:포트 코드` 명령 발사
4. **사람이 STT로 부를 필요 없음. 60초 안에 1초만에 처리.**

핵심 트릭:
```bash
# 페어링 화면 자동 진입
adb shell uiautomator dump /sdcard/ui.xml
# bounds="[178,849][593,908]" 에서 "페어링 코드로 기기 페어링" 좌표 추출
adb shell input tap 385 878
# 다이얼로그 스크린캡쳐 → 이미지 읽기로 코드/포트 확보
adb shell screencap -p /sdcard/p.png
```

### Step 2. 자동 복구 스크립트

`~/.local/bin/adb_revive.sh`:

```bash
#!/bin/bash
# adb_revive.sh — ADB mesh 자동 복구 (박씨 손길 0)
# Usage: adb_revive.sh phone|tab|all

PHONE_IP="100.103.250.45"
TAB_IP="100.74.21.77"

revive() {
  local TARGET=$1 NAME=$2

  if adb devices 2>/dev/null | grep -E "^$TARGET:.*device$" -q; then
    PORT=$(adb devices | grep -E "^$TARGET:.*device$" | head -1 | grep -oE ':[0-9]+' | tr -d ':')
    echo "▶ $NAME ($TARGET): ✅ 이미 살아있음 ($PORT)"
    return 0
  fi

  echo "▶ $NAME ($TARGET) 복구 중..."

  PORTS=$(nmap -p 30000-65535 --open -T4 -oG - $TARGET 2>/dev/null \
    | grep -oE '[0-9]+/open' | grep -oE '[0-9]+')

  for port in $PORTS; do
    r=$(timeout 3 adb connect $TARGET:$port 2>&1)
    if echo "$r" | grep -q "connected to"; then
      sleep 1
      if adb devices | grep -E "^$TARGET:$port\s.*device$" -q; then
        echo "  ✅ WSL→$TARGET:$port"
        return 0
      fi
      adb disconnect $TARGET:$port >/dev/null 2>&1
    fi
  done

  if [ "$NAME" = "폰" ]; then
    PEER=$TAB_IP; PEER_NAME="탭"
  else
    PEER=$PHONE_IP; PEER_NAME="폰"
  fi

  if ssh -p 8022 -o ConnectTimeout=3 -o StrictHostKeyChecking=no $PEER "echo OK" 2>/dev/null | grep -q OK; then
    for port in $PORTS; do
      r=$(ssh -p 8022 $PEER "adb connect $TARGET:$port" 2>&1)
      if echo "$r" | grep -q "connected to"; then
        sleep 1
        if ssh -p 8022 $PEER "adb devices" 2>/dev/null | grep -E "^$TARGET:$port\s.*device$" -q; then
          echo "  ✅ $PEER_NAME→$TARGET:$port (mesh)"
          adb connect $TARGET:$port >/dev/null 2>&1
          return 0
        fi
      fi
    done
  fi

  echo "  ❌ 실패. SSH/무선디버깅 토글 확인 필요."
  return 1
}

case "$1" in
  phone) revive "$PHONE_IP" "폰" ;;
  tab)   revive "$TAB_IP" "탭" ;;
  all|"") revive "$PHONE_IP" "폰"; revive "$TAB_IP" "탭" ;;
  *) echo "Usage: $0 phone|tab|all"; exit 1 ;;
esac

echo
echo "=== adb devices ==="
adb devices
```

선행 조건:
```bash
sudo apt install -y nmap
```

## 사용법

```bash
adb_revive.sh phone   # 폰 끊겼을 때
adb_revive.sh tab     # 탭 끊겼을 때
adb_revive.sh         # 둘 다 (또는 all)
```

### 동작 흐름

```
1. 이미 device로 등록돼 있나? → 끝
2. nmap으로 30000-65535 포트 스캔 (~5초)
3. 후보 포트 4-5개 추출
4. 각 포트로 adb connect 시도
5. 진짜 device로 등록되는 포트 = 무선디버깅 포트 → 등록 완료
6. 1번 경로 실패하면 → 살아있는 다른 디바이스 SSH 통해 mesh 우회
```

## 검증 결과

| 시나리오 | 시간 | 박씨 손길 |
|---------|------|----------|
| 폰만 복구 | 8초 | 0 |
| 폰+탭 둘 다 복구 | 14초 | 0 |
| WSL↔폰 직접 실패 → 탭 경유 mesh | 8~10초 | 0 |

## 박씨 시나리오 적용

**가게에서 폰 재부팅됨 → 작업 막힘:**
- 옛날: 집까지 가서 USB 꽂기 (수십 분)
- 지금: WSL 터미널에 `adb_revive.sh phone` → 8초 후 작업 재개 ✅

**WSL 자체가 죽었을 때:**
- 폰 SSH 또는 탭 SSH 들어가서 같은 스크립트 실행 → 폰↔탭 자기들끼리 ADB 통제 가능

## 핵심 통찰

- **페어링은 영구, 포트만 휘발성** — 한 번 페어링하면 평생, 포트는 매번 새로 찾기만 하면 됨
- **포트 식별 = nmap 스캔으로 5초** — Android는 무선디버깅 포트를 시스템 프로퍼티에 노출 안 함. /proc/net/tcp도 Termux 사용자 권한으로 못 읽음. 외부 포트 스캔이 가장 견고
- **mesh의 진짜 가치는 WSL 죽었을 때** — 평소엔 WSL 직통이 빠름. mesh는 WSL 장애 시 폰↔탭만으로 작업 이어갈 수 있는 안전망

## 관련 파일

- 메모리: `~/.claude/projects/-home-dtsli/memory/project_ssh_stability.md` (Termux:Boot SSH 자동 시작)
- 메모리: `~/.claude/projects/-home-dtsli/memory/project_tablet_adb_setup.md`
- 스크립트: `~/.local/bin/adb_revive.sh`

## 변경 이력

- 2026-05-03: mesh 페어링 + adb_revive.sh 스크립트 확정
