"""prompt_encoder INT8 양자화 정확도 검증 — FP32 vs INT8 출력 비교"""
import json
import numpy as np
import onnxruntime as ort

FP32 = "/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_fp32.onnx"
INT8 = "/root/parksy/onnx/onnx/parksy_v2pp_fixed/prompt_encoder_int8_dyn.onnx"
SR = 24000
N_TRIALS = 20  # 20개 다른 입력 케이스
RNG = np.random.default_rng(seed=42)

so = ort.SessionOptions()
so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
sess_fp = ort.InferenceSession(FP32, sess_options=so, providers=["CPUExecutionProvider"])
sess_q = ort.InferenceSession(INT8, sess_options=so, providers=["CPUExecutionProvider"])

def cos_sim(a, b):
    a, b = a.flatten().astype(np.float64), b.flatten().astype(np.float64)
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12))

def max_rel_err(a, b):
    a, b = a.flatten().astype(np.float64), b.flatten().astype(np.float64)
    denom = np.maximum(np.abs(a), 1e-6)
    return float(np.max(np.abs(a - b) / denom))

stats = {"ge": {"cos": [], "max_abs": [], "max_rel": []},
         "ge_advanced": {"cos": [], "max_abs": [], "max_rel": []}}

for i in range(N_TRIALS):
    feed = {
        "ref_audio": RNG.standard_normal((1, SR), dtype=np.float32),
        "sv_emb": RNG.standard_normal((1, 20480), dtype=np.float32),
    }
    out_fp = sess_fp.run(None, feed)
    out_q = sess_q.run(None, feed)
    for idx, name in enumerate(["ge", "ge_advanced"]):
        stats[name]["cos"].append(cos_sim(out_fp[idx], out_q[idx]))
        stats[name]["max_abs"].append(float(np.max(np.abs(out_fp[idx] - out_q[idx]))))
        stats[name]["max_rel"].append(max_rel_err(out_fp[idx], out_q[idx]))

result = {
    "n_trials": N_TRIALS,
    "outputs": {},
}
for name in ["ge", "ge_advanced"]:
    s = stats[name]
    result["outputs"][name] = {
        "cosine_similarity_mean": round(float(np.mean(s["cos"])), 6),
        "cosine_similarity_min": round(float(np.min(s["cos"])), 6),
        "max_absolute_error_mean": round(float(np.mean(s["max_abs"])), 6),
        "max_absolute_error_max": round(float(np.max(s["max_abs"])), 6),
        "max_relative_error_mean": round(float(np.mean(s["max_rel"])), 4),
    }

# 양산 적용 가능성 판정
ge_cos = result["outputs"]["ge"]["cosine_similarity_mean"]
gea_cos = result["outputs"]["ge_advanced"]["cosine_similarity_mean"]
verdict = (
    "✅ 양산 적용 가능 (cos≥0.999)" if min(ge_cos, gea_cos) >= 0.999 else
    "⚠ 검토 필요 (0.99~0.999)" if min(ge_cos, gea_cos) >= 0.99 else
    "❌ 손상 큼 (<0.99) — 정적 양자화 또는 부분 양자화 권장"
)
result["verdict"] = verdict
print(json.dumps(result, indent=2, ensure_ascii=False))
print(f"\n=> {verdict}")

with open("/root/parksy/onnx/verify_int8_accuracy_result.json", "w") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
