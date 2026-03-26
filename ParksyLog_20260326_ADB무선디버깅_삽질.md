# ADB 무선 디버깅 삽질 기록 (2026-03-26)

## 목표

PC WSL2에서 폰 ADB 무선 연결 → UIAutomator 좌표 탐지 → MacroDroid 자동화

## 시도한 것들 (전부 실패)

### 1. WSL adb (34.0.4-debian) pair
```
adb pair 100.103.250.45:PORT CODE
→ Unable to start pairing client
```
**원인**: Debian 패키지 adb 34.0.4, 무선 디버깅 SPAKE2 pairing 버그 있는 버전.

### 2. Windows adb (36.0.2) pair
```
C:\platform-tools\adb.exe pair 100.103.250.45:PORT CODE
→ error: protocol fault (couldn't read status message): No error
```
**원인**: pairing port에 연결은 되는데 SPAKE2 핸드셰이크 직후 서버가 연결 끊음.
connect는 Windows 10060 timeout — Windows에서 Tailscale 100.x.x.x로 TCP 못 가는 문제.

### 3. Linux 최신 adb (36.0.2) 설치 후 pair
```bash
curl -L platform-tools-latest-linux.zip → sudo cp adb /usr/local/bin/
adb pair 100.103.250.45:PORT CODE
→ protocol fault (couldn't read status message): Success
```
**원인**: 버전 문제 아님. WireGuard(Tailscale) 위에서 SPAKE2 TLS 핸드셰이크가 깨짐.
폰이 연결 직후 응답 없이 소켓 닫음.

### 4. SSH 리버스 터널 경유 pair
- 폰 Termux에서 `ssh -R PORT:localhost:PORT PC_IP` → PC ssh 22 포트 막힘
- PC에서 `ssh -L PORT:localhost:PORT PHONE_IP` → tunnel 연결됐지만 phone localhost:PORT connection refused (타이밍 만료)

### 5. Termux adb localhost pair (폰에서 직접)
- Termux adb 버전이 Android 15 wireless debugging pairing 프로토콜 미지원

## 결론

**Android 15 + Tailscale(WireGuard) 환경에서 네트워크 ADB 페어링 불가.**

SPAKE2+ pairing 프로토콜이 WireGuard NAT 환경에서 일관되게 실패.
네트워크 경로(직접/터널/localhost) 무관하게 동일 증상.

## 확정 해결 방법

**USB 케이블 1회 연결 (C-to-C)**

```bash
# PC에서
adb devices                     # 폰 인식 확인
adb tcpip 5555                  # TCP 모드 전환
adb connect 100.103.250.45:5555 # 이후 무선 영구 연결
```

- 포트 5555: 페어링 없이 connect 직접 가능
- Android 15도 tcpip 5555 방식은 차단 안 함
- 집에서 USB 한 번만 하면 이후 Tailscale로 영구 무선

## 부산물: SSH 키 등록 완료

PC → 폰 Termux SSH 키 등록 완료 (`~/.ssh/id_ed25519.pub`).
이제 `ssh -p 8022 100.103.250.45` 비밀번호 없이 바로 붙음.

## 다음 세션

- USB 케이블 연결 → `adb tcpip 5555`
- `adb connect 100.103.250.45:5555` 확인
- UIAutomator dump → 입력창 좌표 추출
- MacroDroid Intent 방식 자동화 연결
