# Windows 자동 로그인 설정 (PIN 우회)

## 문제
Windows 11 + Microsoft 계정 + Windows Hello PIN 조합에서
레지스트리 수동 편집(`netplwiz`, `AutoAdminLogon`)으로는 자동 로그인이 안 됨.
재부팅 시 PIN 입력 화면에서 막혀서 원격 접속 불가.

## 해결: Sysinternals Autologon

Microsoft 공식 도구. 비밀번호를 LSA 암호화로 저장해서 PIN 있어도 작동.

### 설치 & 설정 (1회)

PC에서 PowerShell 실행 후:

```powershell
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/AutoLogon.zip" -OutFile "$env:TEMP\AutoLogon.zip"
Expand-Archive "$env:TEMP\AutoLogon.zip" -DestinationPath "$env:TEMP\AutoLogon" -Force
Start-Process "$env:TEMP\AutoLogon\Autologon64.exe"
```

창 뜨면:
1. Username: 자동 입력됨
2. Domain: 자동 입력됨
3. Password: **MS 계정 비밀번호** 입력 (PIN 아님)
4. **Enable** 클릭

### 비활성화

같은 도구 실행 → **Disable** 클릭

### 원격 설치 (Claude Code에서)

```bash
ssh -p 2222 dtsli@100.90.83.128 "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command \"
Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/AutoLogon.zip' -OutFile \\\"\\\$env:TEMP\AutoLogon.zip\\\"
Expand-Archive \\\"\\\$env:TEMP\AutoLogon.zip\\\" -DestinationPath \\\"\\\$env:TEMP\AutoLogon\\\" -Force
Start-Process \\\"\\\$env:TEMP\AutoLogon\Autologon64.exe\\\"
\""
```
→ PC 화면에서 비밀번호 입력 + Enable 필요 (GUI 필수)

## 안 되는 방법들 (삽질 기록)

| 방법 | 결과 |
|------|------|
| `netplwiz` 체크박스 해제 | Windows 11에서 체크박스 숨겨져 있음 |
| `DevicePasswordLessBuildVersion = 0` + netplwiz | PIN이 override해서 무시됨 |
| 레지스트리 `AutoAdminLogon=1` + `DefaultPassword` | Microsoft 계정 + PIN 조합에서 안 먹힘 |
| PIN 제거 후 레지스트리 | 여전히 안 됨 |
| **Sysinternals Autologon** | **성공** — LSA 암호화 저장으로 우회 |

## 전체 원격 재부팅 체인

```
정전/윈도우 업데이트 → PC 전원 복구
  → BIOS AC Power Recovery = On (자동 켜짐) [설정 필요]
  → Sysinternals Autologon (자동 로그인) [완료]
  → WSL 자동 시작 + SSH [설정 필요]
  → Tailscale 접속 → Claude Code 원격 작업 가능
```

## 참고
- https://learn.microsoft.com/en-us/sysinternals/downloads/autologon
- https://www.ionos.com/digitalguide/server/configuration/windows-11-automatic-login/
- 설정일: 2026-03-23
