# ParksyLog 2026-04-27 06:47 UTC — 핵심 드라이버 확정: NPU + Parksy Voice 폰 단독 양산

## 1) 무엇을 결정했나
사장님이 명시:
> **"Parksy Voice 추론을 S25 Ultra Hexagon NPU에 박아서 GPU 호출 없이 폰 단독으로 양산"**
이걸 모든 폰 로컬 작업의 **최상위 핵심 드라이버**로 박음.

## 2) 왜
- 박씨 헌법 일치: "박씨 음성 합성 + 로컬 작업", "PC 연결 불필요. 폰 단독 환경"과 정확히 맞물림.
- 커뮤니티 검증: Local Dream(SD on Hexagon), mllm(소형 LLM on QNN) 사례가 이미 양산형 검증함.
- 비용 구조: 외부 GPU(RunPod 등) 호출 의존 → 폰 NPU 자급으로 전환 시 운영비/지연/네트워크 의존도 모두 감소.

## 3) 우리 자산 매핑
- ✅ ONNX 시드 모델: `/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_fp32.onnx` (47K) + `.bin` (84.4MB)
- ✅ 하드웨어: S25 Ultra (Snapdragon 8 Elite for Galaxy, Hexagon NPU 최신)
- ✅ 빌드 환경: PRoot Ubuntu 25.10 / clang 21 / cmake / Python 3.13 / uv / Termux NDK clang 1125개 도구
- ✅ 비교 베이스라인: GPU 백엔드 `http://100.90.83.128:8000` 가동 중 (Tailscale 19ms)
- ✅ 푸시 인프라: termux-bridge 레포 + ParksyLog 룰 + GH 인증

## 4) 커뮤니티에서 가져올 패턴
- **W8A16 정적 양자화** (Local Dream 표준)
- **prefill=NPU / decode=CPU 하이브리드** (mllm 패턴) → 우리는 prompt_encoder=NPU / vocoder=CPU로 매핑
- **QNN SDK + ONNX Runtime QNN ExecutionProvider** 경로
- 필요 시 **Android 네이티브 앱 슬롯** 추가 (Termux 단독 한계 시)

## 5) 3단계 로드맵
- **Step 1 (오늘 시작 가능):** onnxruntime CPU EP로 `prompt_encoder_fp32.onnx` 폰에서 추론 → CPU 베이스라인 latency 측정. NPU 옮길 때 비교 기준.
- **Step 2 (단기):** QNN SDK 도입 + ONNX Runtime QNN EP 빌드 + W8A16 양자화 → Hexagon 태우기. 첫 NPU 추론 성공 = 1차 마일스톤.
- **Step 3 (중기):** prompt_encoder=NPU / 나머지 파이프라인=CPU 분업 → 28언어 양산 라인 → `termux-bridge/pipeline/`에 자동화 스크립트.

## 6) 측정 지표 (성공 정의)
- CPU 대비 NPU 추론 latency 배수
- 1회 합성당 전력 소모
- 토큰/문자당 비용 (GPU 백엔드 호출 비용 vs 폰 NPU 자가추론)
- GPU 호출 감소율 (목표: 95%+)

## 7) 결과 (이번 세션)
- 메모리에 핵심 드라이버 영구 등록 (`project_core_driver_npu_parksy_voice.md`)
- MEMORY.md 인덱스 최상단에 ⭐ 마크로 박음
- 이 일지로 termux-bridge에 방향성 기록

## 8) 다음 행동 (사장님 컨펌 대기)
**Step 1 시작:**
- `uv pip install onnxruntime` (또는 `pip install onnxruntime`)
- 간단 측정 스크립트로 prompt_encoder_fp32.onnx 100회 추론 latency 평균 측정
- 결과 다음 ParksyLog로 기록

비파괴적·비과금·5분 내. **"고" 말씀하시면 바로 진행.**
