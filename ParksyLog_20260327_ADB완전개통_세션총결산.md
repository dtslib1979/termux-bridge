# ADB 무선 완전 개통 + 세션 총결산 (2026-03-27)

## 오늘 한 것 전체

---

### 1. 듀얼 레인 아키텍처 확인 (phoneparis 52b95f9)

phoneparis CLAUDE.md 특별법 제0-A조 확인:

| 디바이스 | 역할 |
|----------|------|
| 폰 (S25 Ultra) | 입력 창구 — STT, 이동 중 제어 |
| 태블릿 (Tab S9) | 출력 창구 — 화면 녹화, S펜 |
| 집 PC (WSL2) | 본사 — 모든 연산 여기서 |

평가: 신박하다. "몸이 처한 상황이 기기를 고른다" — 기술이 사람한테 맞추는 설계.

---

### 2. ADB 무선 연결 삽질 (2~3시간)

**시도 전부 실패한 것들:**

| 시도 | 실패 원인 |
|------|-----------|
| WSL adb 34.0.4 pair | 버전 버그 — Unable to start pairing client |
| Windows adb 36.0.2 pair | SPAKE2 protocol fault over WireGuard |
| Linux adb 36.0.2 설치 후 pair | 동일 — WireGuard 위에서 TLS 핸드셰이크 깨짐 |
| SSH 리버스 터널 경유 pair | 폰→PC SSH 22 막힘 |
| SSH 로컬 포워드 경유 pair | 타이밍 만료 반복 |
| Termux adb localhost pair | Android 15 pairing 프로토콜 미지원 |

**핵심 원인**: Android 15가 SPAKE2+ pairing을 WireGuard/NAT 환경에서 차단.
개발자들도 똑같이 막히는 벽. 박씨 잘못 아님.

---

### 3. 부산물: PC→폰 SSH 키 등록

```bash
ssh-copy-id -p 8022 -i ~/.ssh/id_ed25519.pub 100.103.250.45
# 이후 비밀번호 없이 바로 접속
ssh -p 8022 100.103.250.45
```

---

### 4. USB 케이블로 최종 해결

```bash
# USB 연결 후 폰에서 디버깅 허용
cmd.exe /c "C:\platform-tools\adb.exe devices"
# → R3CY609RRAR device ✅

cmd.exe /c "C:\platform-tools\adb.exe tcpip 5555"
# → restarting in TCP mode port: 5555

# USB 뽑고 무선 연결
adb connect 100.103.250.45:5555
# → connected ✅
```

---

### 5. 기능 검증

| 기능 | 결과 |
|------|------|
| 화면 터치 (`adb shell input tap`) | ✅ |
| 파일 PC→폰 (`adb push`) | ✅ |
| 파일 폰→PC (`adb pull`) | ✅ |
| 앱 실행 (`adb shell am start`) | ✅ |
| UIAutomator dump | ✅ |

**폰 사진 현황**: 3,912개 / 12GB / 전송 속도 ~15MB/s (약 13분)

---

### 6. 보안 스택 확정

```
레이어 1: Tailscale (WireGuard) — 네트워크 암호화
레이어 2: SSH (키 인증) — 프로토콜 암호화
레이어 3: ADB (USB 물리 인증) — 물리 접근 필수
```

오늘 삽질이 보안 검증이었다. Defense in Depth 자연스럽게 완성.

---

### 7. 다음 작업

- [ ] Voyager Legend 50 도착 → 헤드셋 버튼 → 삼성 키보드 STT 연결
- [ ] MacroDroid + ADB → 버튼 → `adb shell input keyevent` 자동화
- [ ] 필요 시 폰 사진 PC 백업 (`adb pull /sdcard/DCIM`)

---

## 오늘의 한 줄

> **말 한마디 → STT → Claude → PC 제어 + 폰 제어.**
> 3년 전 Termux + 음성입력으로 시작한 Reverse Orality가 인프라 레벨에서 실현됐다.
