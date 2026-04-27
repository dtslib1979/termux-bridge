"""prompt_encoder dynamic INT8 양자화 + 측정"""
import json
import time
import numpy as np
import onnxruntime as ort
from onnxruntime.quantization import quantize_dynamic, QuantType

SRC = "/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_fp32.onnx"
DST = "/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_int8_dyn.onnx"

print(f"양자화: {SRC} -> {DST}")
quantize_dynamic(
    model_input=SRC,
    model_output=DST,
    weight_type=QuantType.QInt8,
)

import os
src_size = os.path.getsize(SRC) + os.path.getsize(SRC.replace(".onnx", ".bin"))
dst_size = os.path.getsize(DST)
print(f"원본 크기: {src_size/1024/1024:.2f} MB (.onnx + .bin)")
print(f"INT8 크기: {dst_size/1024/1024:.2f} MB")
print(f"압축률: {dst_size/src_size*100:.1f}%")

# 측정
SR = 24000
N = 100
WARMUP = 5

so = ort.SessionOptions()
so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
sess = ort.InferenceSession(DST, sess_options=so, providers=["CPUExecutionProvider"])

feed = {
    "ref_audio": np.random.randn(1, SR).astype(np.float32),
    "sv_emb": np.random.randn(1, 20480).astype(np.float32),
}
for _ in range(WARMUP):
    sess.run(None, feed)

times = []
for _ in range(N):
    t = time.perf_counter()
    sess.run(None, feed)
    times.append((time.perf_counter() - t) * 1000.0)
times.sort()

result = {
    "model": DST,
    "size_mb": round(dst_size / 1024 / 1024, 2),
    "size_reduction_pct": round((1 - dst_size / src_size) * 100, 1),
    "n_runs": N,
    "latency_ms": {
        "min": round(times[0], 2),
        "p50": round(times[N // 2], 2),
        "p90": round(times[int(N * 0.9)], 2),
        "p99": round(times[int(N * 0.99)], 2),
        "max": round(times[-1], 2),
        "mean": round(sum(times) / N, 2),
    },
}
print(json.dumps(result, indent=2, ensure_ascii=False))
with open("/root/parksy/onnx/quantize_int8_result.json", "w") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
