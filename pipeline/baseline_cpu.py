"""Parksy Voice prompt_encoder CPU 베이스라인 latency 측정"""
import json
import time
import numpy as np
import onnxruntime as ort

MODEL = "/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_fp32.onnx"
N = 100
WARMUP = 5

so = ort.SessionOptions()
so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
sess = ort.InferenceSession(MODEL, sess_options=so, providers=["CPUExecutionProvider"])

inputs_meta = [{"name": i.name, "shape": i.shape, "type": i.type} for i in sess.get_inputs()]
outputs_meta = [{"name": o.name, "shape": o.shape, "type": o.type} for o in sess.get_outputs()]
print("PROVIDERS:", sess.get_providers())
print("INPUTS:", json.dumps(inputs_meta, indent=2, ensure_ascii=False))
print("OUTPUTS:", json.dumps(outputs_meta, indent=2, ensure_ascii=False))

SYMBOLIC_DEFAULTS = {
    "audio_length": 24000,
}

def make_dummy(shape, dtype):
    s = tuple(
        SYMBOLIC_DEFAULTS.get(d, 1) if isinstance(d, str)
        else (1 if (d is None or d == 0) else d)
        for d in shape
    )
    if "float16" in dtype:
        return np.random.randn(*s).astype(np.float16)
    if "float" in dtype:
        return np.random.randn(*s).astype(np.float32)
    if "int64" in dtype:
        return np.random.randint(0, 100, size=s).astype(np.int64)
    if "int32" in dtype:
        return np.random.randint(0, 100, size=s).astype(np.int32)
    return np.zeros(s, dtype=np.float32)

feed = {i.name: make_dummy(i.shape, i.type) for i in sess.get_inputs()}
for k, v in feed.items():
    print(f"  feed {k}: shape={v.shape} dtype={v.dtype}")

for _ in range(WARMUP):
    sess.run(None, feed)

times = []
for _ in range(N):
    t = time.perf_counter()
    sess.run(None, feed)
    times.append((time.perf_counter() - t) * 1000.0)

times.sort()
result = {
    "model": MODEL,
    "provider": sess.get_providers()[0],
    "n_runs": N,
    "warmup": WARMUP,
    "latency_ms": {
        "min": round(times[0], 2),
        "p50": round(times[N // 2], 2),
        "p90": round(times[int(N * 0.9)], 2),
        "p99": round(times[int(N * 0.99)], 2),
        "max": round(times[-1], 2),
        "mean": round(sum(times) / N, 2),
    },
}
print("\nRESULT:", json.dumps(result, indent=2, ensure_ascii=False))
with open("/root/parksy/onnx/baseline_cpu_result.json", "w") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
