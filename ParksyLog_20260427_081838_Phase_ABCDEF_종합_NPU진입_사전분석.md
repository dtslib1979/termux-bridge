# ParksyLog 2026-04-27 08:18 UTC — Phase A~F 종합: NPU 진입 사전 분석 + 양자화 첫 성공

자율 실행 명령("니가 볼 때 가능한 거 다 해")으로 단번에 처리한 6개 페이즈.

## A. 입력 길이 스윕 (CPU EP, prompt_encoder)
| 길이 | mean ms | RTF (낮을수록 빠름) |
|---|---|---|
| 0.5s | 2.51 | 0.00503 |
| 1.0s | 3.22 | 0.00322 |
| 2.0s | 4.05 | 0.00203 |
| 3.0s | 5.44 | 0.00181 |
| 5.0s | 9.72 | 0.00194 |
| 10.0s | 14.99 | 0.00150 |

→ **선형에 가깝게 증가**. RTF는 길이가 길수록 좋아짐(고정 비용 분산). 10초까지 폰 CPU만으로 음성 1초당 1.5ms 추론 → 실시간 대비 666x.

## B. 다른 모듈 ONNX 폰 보유 여부
- `find /root/parksy/.venv -name "*.onnx"` → onnxruntime/onnx의 **테스트용 모델만**.
- HF cache(`/root/.cache/huggingface/hub`) 비어있음.
- **결론:** 폰에는 `prompt_encoder_fp32.onnx`만 단독. GPT 모델·SoVITS vocoder·Chatterbox 본체는 PC 보유. **본격 양산 전체 파이프라인은 PC에서 추가 ONNX 변환 후 이관 필요**.

## C. ONNX Runtime QNN ExecutionProvider 진입 시도
- `onnxruntime-qnn 2.1.0` PyPI wheel 존재 확인 (72MB).
- 격리 venv `/root/parksy/.venv-qnn`에 설치 성공.
- ❌ **`ort.get_available_providers()` 결과 `[Azure, CPU]`만 — `QNNExecutionProvider` 미등록**.
- **원인 추정:** PyPI wheel은 Windows-on-ARM 또는 특정 빌드 변종 전용. Linux aarch64 PRoot에서는 동작 안 함.
- **결론:** Step 2 본격 진입은 **QNN SDK + ONNX Runtime 소스 빌드** 필요. PyPI 한 줄 진입 경로 닫힘 확정.

## D. INT8 Dynamic 양자화 (성공)
| 지표 | FP32 | **INT8 dynamic** | 효과 |
|---|---|---|---|
| 모델 크기 | 84.47 MB | **23.54 MB** | **-72.1%** |
| mean latency | 3.57 ms | **2.03 ms** | **-43% (1.76x)** |
| p50 / p99 | 2.93 / 10.83 | 1.85 / 6.12 | 모두 개선 |

- 양자화 출력: `/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_int8_dyn.onnx`
- onnxruntime.quantization.quantize_dynamic + QInt8 weights
- 일부 텐서(`/Slice_output_0` int) 양자화 미지원 경고 있었으나 무해 (skip 처리).
- **이건 NPU 적재의 필수 사전 단계**. INT8/W8A16 형태가 Hexagon NPU 표준 입력 — Step 2 진입 시 그대로 재사용.

## E. Parksy Voice GPU 백엔드 메타 수집 (`http://100.90.83.128:8000`)
**시스템 구조 확정:**
- 명칭: `Parksy TTS 1-tool API v2.0`
- 단일 엔드포인트: `POST /synthesize {text, lang, quality, speed_factor}`
- 28개 언어 = **Lane A (학습 5개) + Lane B (zero-shot 23개)** 합산
  - Lane A = **GPT-SoVITS v2Pro** (ko/ja/zh/yue/en) ← `parksy_v2pp_fixed`의 출처
  - Lane B = **Chatterbox** (ar/da/de/el/en/es/fi/fr/he/hi/it/ja/ko/ms/nl/no/pl/pt/ru/sv/sw/tr/zh)
- GPU 백엔드 평균 RTF: **Lane A 8.81 / Lane B 23.07** (학습 모델이 zero-shot보다 2.6x 빠름)
- 24h 합성 카운트 0건 (현재 사용 휴지)

**합성 호출(/synthesize)은 박씨 헌법 "과금/실호출" 조항 → 컨펌 후 진행.** 이번 점검은 무료 메타 엔드포인트만.

## F. termux-bridge/pipeline + runs 시드
- `pipeline/baseline_cpu.py`, `pipeline/sweep_cpu.py`, `pipeline/quantize_int8.py` 3종 시드 (재실행 가능)
- `runs/baseline_cpu_20260427.json`, `runs/sweep_cpu_20260427.json`, `runs/quantize_int8_20260427.json`
- 기존 `runs/` 안에 60+ 날짜 디렉토리 존재 (백엔드 합성 로그 누적). 우리 측정 결과를 같은 디렉토리에 쌓아 시계열 비교 기반 마련.

## 의사결정에 영향 줄 결론
1. **양자화 단독으로도 큰 이득** (1.76x 빠름, 1/3.6 크기) → NPU 진입 전이라도 폰 CPU 양산 즉시 적용 가치 있음.
2. **PyPI 한 줄 NPU 경로 막힘** → Step 2는 QNN SDK 다운(Qualcomm 가입) + 소스 빌드 필수.
3. **본 파이프라인(GPT, SoVITS vocoder, Chatterbox) PC에서 ONNX 추출 → 폰 이관**이 다음 큰 의존 작업. 이거 없으면 prompt_encoder 외 모듈 NPU 측정 불가.
4. Lane A/B 분업 = 우리 NPU 양산 계획 그대로 매핑됨: prompt_encoder=NPU, vocoder=CPU 같은 구조가 자연스러움.

## 다음 단계 후보 (사장님 선택)
- (i) **PC에서 GPT-SoVITS/Chatterbox 본 모듈 ONNX 추출 → 폰 이관** (가장 큰 의존성, 사장님 PC 작업)
- (ii) **GPU 백엔드 `/synthesize` 컨펌 후 1회 호출**해 end-to-end RTF/latency 정확 측정 (소액 과금)
- (iii) Step 2: QNN SDK 다운 + ONNX Runtime 소스 빌드 (며칠 소요, 디스크 압박 가능)
- (iv) **prompt_encoder INT8 모델 정확도 검증** (양자화로 출력 품질 손상 측정)

**제 추천 순서:** (iv) → (i) → (iii) → (ii). 양자화 정확도 검증이 가장 가벼우면서 양산 결정에 직결, 그 다음 PC측 모델 추출이 본 파이프라인의 병목 해소.
