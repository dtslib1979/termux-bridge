# ParksyLog 2026-04-27 07:50 UTC — Step 1: prompt_encoder CPU 베이스라인 확보

## 1) 무엇을 했나
Parksy Voice prompt_encoder ONNX 모델을 폰 단독 CPU에서 추론, 100회 latency 측정.

- 환경: PRoot Ubuntu 25.10 / Python 3.12.13 / `/root/parksy/.venv`
- 패키지: `onnxruntime 1.25.0`, `numpy 1.26.4` (이미 또는 즉시 설치)
- 측정 스크립트: `/root/parksy/onnx/baseline_cpu.py`
- 결과 JSON: `/root/parksy/onnx/baseline_cpu_result.json`

## 2) 모델 메타 (확인됨)
**INPUTS**
- `ref_audio`: float32, shape `[1, audio_length]` (가변) — 1초 @ 24kHz = 24000 샘플로 고정 측정
- `sv_emb`: float32, shape `[1, 20480]` — speaker verification embedding

**OUTPUTS**
- `ge`: float32, shape `[PReluge_dim_0, 1024, 1]`
- `ge_advanced`: float32, shape `[PReluge_dim_0, 512, 1]`

→ 이 모듈은 reference audio + speaker embedding → global embedding 두 개를 뽑는 **인코더 단**. 전체 합성 파이프라인의 앞단.

## 3) 측정 결과 (CPU EP, N=100, warmup=5)

| 지표 | 값 (ms) |
|---|---|
| **mean** | **3.57** |
| min | 2.45 |
| p50 | 2.93 |
| p90 | 5.14 |
| p99 / max | 10.83 |

**해석:** 폰 CPU 8코어로 prompt_encoder 1초 입력 처리에 **평균 3.57ms**. 매우 빠름 (1초 음성 입력 대비 0.36% 시간만 사용 = 실시간 대비 280x). prompt_encoder 단독으로는 NPU 가속 없어도 폰 CPU로 충분히 양산 가능 수준.

## 4) 첫 시도 실패 + 수정
- 1차: 더미 입력을 (1, 1)로 만들어 `Pad reflect requires axis length >= 2` 에러.
- 수정: `audio_length` 심볼을 24000 (1초@24kHz) 기본값으로 매핑하는 `SYMBOLIC_DEFAULTS` 추가 → 통과.

## 5) 한계 / 미해결
- 이건 **prompt_encoder만**의 베이스라인. 전체 합성 파이프라인 (decoder, vocoder, flow matching 등)은 별도 측정 필요. 그쪽이 진짜 무거운 구간.
- GPU 백엔드(`100.90.83.128:8000`) 같은 모듈만의 latency 비교군은 아직 안 잡음. 대조 의미를 더 강하게 하려면 백엔드 측에서 같은 prompt_encoder만 추출 측정 필요.
- 28개 언어/다양한 입력 길이별 분포는 측정 안 함. 1초 단일 케이스.

## 6) 핵심 드라이버 기여도
**Step 1 = NPU 양산 파이프라인의 첫 블록.** 같은 onnxruntime 위에 Step 2에서 QNN ExecutionProvider만 얹으면 NPU 모드. 코드 거의 안 바뀜. 베이스라인 숫자 확보 → NPU 측정 결과와 직접 비교 가능.

## 7) 다음 단계 후보
- (a) **다른 모듈 ONNX 변환·측정**: vocoder/decoder도 ONNX로 추출해서 폰 CPU 베이스라인 잡기 (전체 파이프라인 어디가 병목인지 식별 → 거기를 NPU로 우선 옮김)
- (b) **Step 2 진입**: QNN SDK 도입 + ONNX Runtime QNN EP 빌드 + W8A16 양자화 → 같은 prompt_encoder NPU 측정
- (c) **다양한 입력 길이별 스윕**: 0.5/1/2/3/5/10초 ref_audio 별 latency 곡선

병목 식별이 우선이면 (a), 양산 검증이 우선이면 (b), 안정성 평가가 우선이면 (c).
