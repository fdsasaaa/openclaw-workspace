import argparse, json, os, re, time, uuid
from pathlib import Path

def load_rules(config_path: Path):
    cfg = json.loads(config_path.read_text(encoding="utf-8"))
    return cfg.get("rules", cfg.get("routes", []))

def pick_route(prompt: str, routes: list):
    for r in routes:
        # 支持 "patterns": ["回测", "EA", ...] 或 "pattern": "..."
        pats = r.get("patterns") or ([r["pattern"]] if "pattern" in r else [])
        for p in pats:
            if re.search(p, prompt, flags=re.IGNORECASE):
                return {
                    "routed": True,
                    "target": r.get("target", "main"),
                    "rule": r.get("name") or r.get("id") or "matched_rule"
                }
    return {"routed": False, "target": "main", "rule": "fallback"}

def main():
    ap = argparse.ArgumentParser(description="Queue Router: prompt -> queue/<taskId>.json")
    ap.add_argument("--config", required=True, help="Path to routing-config.json")
    ap.add_argument("--prompt", required=True, help="User prompt to route")
    ap.add_argument("--outdir", required=True, help="Queue directory to write task json")
    ap.add_argument("--taskId", default="", help="Optional task id")
    args = ap.parse_args()

    config_path = Path(args.config).resolve()
    outdir = Path(args.outdir).resolve()
    outdir.mkdir(parents=True, exist_ok=True)

    routes = load_rules(config_path)
    decision = pick_route(args.prompt, routes)

    task_id = args.taskId.strip() or uuid.uuid4().hex[:8]
    payload = {
        "taskId": task_id,
        "prompt": args.prompt,
        "target": decision["target"],
        "routed": decision["routed"],
        "rule": decision["rule"],
        "status": "queued",
        "createdAt": time.strftime("%Y-%m-%d %H:%M:%S"),
    }

    task_path = outdir / f"{task_id}.json"
    task_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    print("Queued:", str(task_path))
    print("Route :", decision)

if __name__ == "__main__":
    main()

