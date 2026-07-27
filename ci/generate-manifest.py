#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def git(cmd: list[str]) -> str:
    return subprocess.check_output(["git"] + cmd, text=True).strip()


def is_remote(url: str) -> bool:
    return isinstance(url, str) and (url.startswith(("http://", "https://", "//")))


def find_export_base(export_dir: Path) -> str:
    candidates = [
        f
        for f in export_dir.glob("*.wasm")
        if not f.stem.endswith(("side", "audio", "worklet"))
        and not f.name.startswith("lib")
    ]
    if len(candidates) != 1:
        raise SystemExit(
            f"expected exactly one main .wasm in {export_dir}, found: "
            f"{[f.name for f in candidates]}"
        )
    return candidates[0].stem


def compute_load_estimates(file_sizes: dict) -> dict:
    total_bytes = sum(
        v for k, v in file_sizes.items() if k.endswith((".wasm", ".pck", ".js"))
    )
    total_mb = total_bytes / (1024 * 1024)
    tiers = {
        "slow-2g": 0.015,
        "2g": 0.05,
        "3g": 0.35,
        "4g": 1.5,
        "wifi": 4.0,
    }
    estimates = {}
    for tier, speed in tiers.items():
        download = total_mb / speed
        wasm_mb = file_sizes.get("index.wasm", 0) / (1024 * 1024)
        compile = 0.4 + (wasm_mb * 0.25)
        estimates[tier] = max(3, int(round(download + compile)))
    return estimates


def web_manifest(export_dir: Path, base: str, asset_base: str, config: dict) -> dict:
    assets = {}
    file_sizes = {}

    def add_file(key: str, path: Path):
        if path.exists():
            assets[key] = f"{asset_base}/{path.name}"
            file_sizes[path.name] = path.stat().st_size

    add_file("wasm", export_dir / f"{base}.wasm")
    add_file("sideWasm", export_dir / f"{base}.side.wasm")
    add_file("pck", export_dir / f"{base}.pck")
    add_file("js", export_dir / f"{base}.js")
    add_file("splash", export_dir / f"{base}.png")
    add_file("icon", export_dir / f"{base}.icon.png")
    add_file("appleTouchIcon", export_dir / f"{base}.apple-touch-icon.png")
    add_file("audioWorklet", export_dir / f"{base}.audio.worklet.js")
    add_file("audioPositionWorklet", export_dir / f"{base}.audio.position.worklet.js")
    add_file("pwaManifest", export_dir / f"{base}.manifest.json")

    threads_enabled = (export_dir / f"{base}.side.wasm").exists()
    gdexts = []
    for f in sorted(export_dir.glob("*.wasm")):
        stem = f.stem
        if stem in (base, f"{base}.side"):
            continue
        if stem.endswith(("audio", "worklet")):
            continue
        is_nothreads = ".nothreads." in f.name
        if threads_enabled and is_nothreads:
            continue
        if not threads_enabled and not is_nothreads:
            continue
        gdexts.append(f"{asset_base}/{f.name}")

    if file_sizes:
        assets["fileSizes"] = file_sizes

    return {
        "assets": assets,
        "features": {
            "threads": threads_enabled,
            "gdextensions": gdexts,
            **config.get("features", {}),
        },
        "loadEstimates": compute_load_estimates(file_sizes),
    }


def desktop_manifest(
    export_dir: Path, platform: str, exe_name: str, asset_base: str
) -> dict:
    assets = {}
    file_sizes = {}

    if platform == "linux":
        exe = export_dir / f"{exe_name}.x86_64"
    elif platform == "windows":
        exe = export_dir / f"{exe_name}.exe"
    else:
        exe = export_dir / exe_name

    if not exe.exists():
        candidates = [
            f
            for f in export_dir.iterdir()
            if f.is_file() and f.suffix not in (".pck", ".so", ".dll", ".json", ".txt")
        ]
        if candidates:
            exe = max(candidates, key=lambda f: f.stat().st_size)

    if exe and exe.exists():
        assets["executable"] = f"{asset_base}/{exe.name}"
        file_sizes[exe.name] = exe.stat().st_size

    pck = export_dir / f"{exe_name}.pck"
    if not pck.exists():
        pcks = list(export_dir.glob("*.pck"))
        if pcks:
            pck = pcks[0]
    if pck and pck.exists():
        assets["pck"] = f"{asset_base}/{pck.name}"
        file_sizes[pck.name] = pck.stat().st_size

    libs = []
    if platform == "linux":
        for f in sorted(export_dir.glob("*.so*")):
            libs.append(f"{asset_base}/{f.name}")
            file_sizes[f.name] = f.stat().st_size
    elif platform == "windows":
        for f in sorted(export_dir.glob("*.dll")):
            libs.append(f"{asset_base}/{f.name}")
            file_sizes[f.name] = f.stat().st_size

    if libs:
        assets["libraries"] = libs
    if file_sizes:
        assets["fileSizes"] = file_sizes

    return {"assets": assets}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--project", default=os.path.basename(os.getcwd()))
    p.add_argument("--export-dir", required=True)
    p.add_argument("--shell-config", default="./shell.json")
    p.add_argument("--date", default=git(["log", "-1", "--format=%cd", "--date=short"]))
    p.add_argument("--rev", default=git(["rev-parse", "--short", "HEAD"]))
    p.add_argument("--epoch", type=int, default=int(git(["log", "-1", "--format=%ct"])))
    p.add_argument("--r2-base")
    p.add_argument("--out-dir")
    p.add_argument("--telemetry-key", default=os.environ.get("POSTHOG_KEY", ""))
    args = p.parse_args()

    export_root = Path(args.export_dir)
    config = json.loads(Path(args.shell_config).read_text())

    if config.get("schemaVersion") != 1:
        print("warning: unexpected shell.json schema version", file=sys.stderr)

    project = args.project
    date = args.date
    rev = args.rev
    epoch = args.epoch

    r2_base = (
        args.r2_base or f"https://games-media.noetic.work/builds/{project}/{date}/{rev}"
    )
    out_dir = Path(args.out_dir) if args.out_dir else Path("manifests") / date / rev
    out_dir.mkdir(parents=True, exist_ok=True)

    exe_name = config.get("executableName", project)
    platforms = {}

    web_dir = export_root / "web"
    if web_dir.exists():
        base = find_export_base(web_dir)
        platforms["web"] = web_manifest(web_dir, base, f"{r2_base}/web", config)

    linux_dir = export_root / "linux"
    if linux_dir.exists():
        platforms["linux"] = desktop_manifest(
            linux_dir, "linux", exe_name, f"{r2_base}/linux"
        )

    win_dir = export_root / "windows"
    if win_dir.exists():
        platforms["windows"] = desktop_manifest(
            win_dir, "windows", exe_name, f"{r2_base}/windows"
        )

    summary = {
        "schemaVersion": 1,
        "project": project,
        "title": config["title"],
        "build": date,
        "revision": rev,
        "build_epoch": epoch,
        "platforms": platforms,
        "theme": config.get("theme", {}),
        "template": config.get("template", {}),
    }

    if args.telemetry_key:
        summary["telemetry"] = {
            "provider": "posthog",
            "apiKey": args.telemetry_key,
            "host": "https://eu.posthog.com",
            "enabled": True,
            "sampleRate": 1.0,
        }

    summary_path = out_dir / "summary.json"
    summary_path.write_text(json.dumps(summary, indent=2))
    print(f"wrote summary: {summary_path}")

    for plat, data in platforms.items():
        plat_manifest = {**summary, "platform": plat, **data}
        del plat_manifest["platforms"]
        (out_dir / f"{plat}.json").write_text(json.dumps(plat_manifest, indent=2))


if __name__ == "__main__":
    main()
