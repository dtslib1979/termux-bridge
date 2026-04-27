"""prompt_encoder 입력 길이 스윕 (0.5s~10s @ 24kHz)"""
import json
import time
import numpy as np
import onnxruntime as ort

MODEL = "/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_fp32.onnx"
LENGTHS_SEC = [0.5, 1.0, 2.0, 3.0, 5.0, 10.0]
SR = 24000
N = 50
WARMUP = 3

so = ort.SessionOptions()
so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
sess = ort.InferenceSession(MODEL, sess_options=so, providers=["CPUExecutionProvider"])

results = {}
for sec in LENGTHS_SEC:
    n_samples = int(sec * SR)
    feed = {
        "ref_audio": np.random.randn(1, n_samples).astype(np.float32),
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
    rtf = (sum(times) / N) / (sec * 1000.0)
    results[f"{sec}s"] = {
        "n_samples": n_samples,
        "min": round(times[0], 2),
        "p50": round(times[N // 2], 2),
        "p90": round(times[int(N * 0.9)], 2),
        "max": round(times[-1], 2),
        "mean_ms": round(sum(times) / N, 2),
        "rtf": round(rtf, 5),
    }
    print(f"{sec:>5}s ({n_samples:>6} samples): mean {results[f'{sec}s']['mean_ms']:>7} ms | p90 {results[f'{sec}s']['p90']:>7} | RTF {rtf:.5f}")

print()
print(json.dumps(results, indent=2, ensure_ascii=False))
with open("/root/parksy/onnx/sweep_cpu_result.json", "w") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
