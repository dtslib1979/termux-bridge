# Parksy Log — 2026-05-02
## Poly VLegend 50 멀티포인트 완전 개통 + Samsung 볼륨 제한 전부 해제

---

## 배경

- **목적**: 폰(S25 Ultra) + 탭(Tab S9 5G) 동시 착신 수신
- **기기**: Poly VLegend 50 (Poly Voyager Legend 50) — 텔레마케터용 단이어 BT 헤드셋
- **용도**: LLM STT 입력 / 가게 착신 전화 / 멀티디바이스 운용

---

## 문제들 (발견 → 해결 순)

### 1. Samsung 청력 보호 볼륨 제한
- `audio_safe_volume_state`, `ear_safety`, `bluetooth_absolute_volume=0` 조합으로 하드웨어 최대치 대비 50~60% 강제 제한
- **해결**: ADB로 전부 해제

### 2. BT Audio Sharing(Music Share)이 탭 페어링 방해
- `BluetoothAudioCastService`가 백그라운드 실행 중 → 탭에서 Poly 검색 시 발견 안 됨
- **해결**: `bluetooth_cast_mode=0`, `bluetooth_audio_sharing_enabled=0`, `am stopservice` 강제 종료

### 3. Bixby가 헤드셋 통화 버튼 탈취
- 폰 BT ON + Poly 연결 상태에서 통화 버튼 길게 누르면 Bixby 실행됨
- **해결**: `bixby.agent` + `bixby.wakeup` 패키지 disabled-user

### 4. Poly 페어링 모드 진입 방법 오해
- 통화 버튼 길게 누르는 게 아님
- **정답**: 전원 슬라이더를 ON 위치 지나서 2초 홀드 → 페어링 모드

### 5. 통화 볼륨 낮음
- `volume_voice_bt_a2dp`, `volume_bluetooth_sco` 등 개별 스트림이 5~7로 낮게 설정됨
- **해결**: 전 스트림 15로 일괄 설정

---

## 최종 적용 설정 (ADB)

```bash
# 청력 보호 해제
settings put global audio_safe_volume_state 3
settings put global ear_safety 0
settings put system safe_headphone_volume_enabled 0

# BT 절대 볼륨 활성화
settings put global bluetooth_absolute_volume 1

# Music Share 비활성화
settings put secure bluetooth_cast_mode 0
settings put secure bluetooth_audio_sharing_enabled 0
settings put global used_music_share 0

# 통화 볼륨 전 스트림 최대
volume_voice=15, voice_bt_a2dp=15, voice_bt_sco_hs=15,
voice_ble_headset=15, bluetooth_sco=15 ...전부 15

# 폰 전용: Bixby 비활성화
settings put secure bixby_enabled 0
pm disable-user com.samsung.android.bixby.agent
pm disable-user com.samsung.android.bixby.wakeup
```

**재적용 스크립트**: `/home/dtsli/parksy-image/tools/adb_volume_max.sh`

---

## 확정된 멀티포인트 운용법

### 현재 연결 상태
- 폰(S25 Ultra) ↔ Poly VLegend 50 — A2DP + HFP ✅
- 탭(Tab S9 5G) ↔ Poly VLegend 50 — A2DP + HFP ✅

### 실전 통화 전환 플로우
```
폰 통화 중
    ↓
탭에 전화 옴 → 헤드셋에서 "Incoming call" 음성 알림
    ↓
통화 버튼 1번 → 폰 홀드 / 탭 연결
    ↓
탭 통화 종료 후 통화 버튼 1번 → 폰 복귀
```

**실전 버튼은 통화 버튼 하나가 전부.** 텔레마케터 "잠시만요" 워크플로우 그대로.

---

## 기기 선택 평가

| 항목 | Poly VLegend 50 | Galaxy Buds Pro |
|------|----------------|-----------------|
| STT/LLM 입력 | ✅ 붐 마이크, 입 5cm 거리 | ❌ 인이어, 오인식 많음 |
| 가게 착신 전화 | ✅ 단이어, 주변 소리 들림 | ❌ 양쪽 차음 |
| 멀티포인트 | ✅ 설계 목적 | ⚠️ 삼성 생태계만 |
| 장시간 착용 | ✅ 오픈이어 | ❌ 인이어 피로 |
| 음악 | ❌ 모노럴 | ✅ |

**결론: 음악 안 쓰고 말하는 용도 + 가게 운영 + 멀티디바이스면 최적 선택.**

---

## 교훈

- Samsung 볼륨 제한은 전부 소프트웨어 제어 — 하드웨어 한계 아님
- Music Share 서비스가 BT 검색 자체를 방해함 (설정 OFF만으로 부족, 서비스 강제 종료 필요)
- Bixby는 BT 헤드셋 버튼 이벤트까지 탈취함 → 비활성화 필수
- Poly 페어링 = 전원 슬라이더, 통화 버튼 아님
