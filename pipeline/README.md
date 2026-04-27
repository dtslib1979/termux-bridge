# pipeline/ — Parksy Voice 폰 단독 양산 파이프라인 (NPU 드라이버)

S25 Ultra > Termux > PRoot Ubuntu 25.10 > onnxruntime 환경에서 Parksy TTS를 GPU 호출 없이 폰 단독 양산하는 파이프라인 시드.

## 현재 자산
- `prompt_encoder_fp32.onnx` (84MB FP32) — Lane A GPT-SoVITS v2Pro의 인코더 단
- `prompt_encoder_int8_dyn.onnx` (23.5MB INT8) — 동적 양자화, **NPU 진입 사전 모델**

## 측정 스크립트 (재실행 가능)
- `baseline_cpu.py` — 단일 길이(1초) 100회 latency
- `sweep_cpu.py` — 0.5~10초 입력 길이 latency 곡선
- `quantize_int8.py` — FP32 → INT8 dynamic 양자화 + 측정

## 실행 방법
```bash
cd /root/parksy && source .venv/bin/activate
python /root/termux-bridge/pipeline/baseline_cpu.py
python /root/termux-bridge/pipeline/sweep_cpu.py
python /root/termux-bridge/pipeline/quantize_int8.py
```

결과는 `/root/parksy/onnx/*_result.json` 으로 저장 후 `runs/`에 날짜 스탬프로 백업.

## 로드맵
- **Step 1 (완료):** CPU 베이스라인 + 입력길이 스윕 + INT8 양자화
- **Step 2 (보류):** QNN SDK + ONNX Runtime 소스 빌드 → Hexagon NPU 측정. PyPI wheel 경로는 닫힘 확정.
- **Step 3 (의존):** PC에서 GPT 모델/SoVITS vocoder/Chatterbox ONNX 추출 → 폰 이관 → 분업 양산.

## GPU 백엔드 비교군
- `http://100.90.83.128:8000/synthesize` (Tailscale)
- Lane A (GPT-SoVITS v2Pro): 5개 언어 학습형, RTF 8.81
- Lane B (Chatterbox): 23개 언어 zero-shot, RTF 23.07
- end-to-end 호출은 과금/실호출이라 컨펌 후만.
