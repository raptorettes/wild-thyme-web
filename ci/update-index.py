#!/usr/bin/env python3
"""
update-index.py — Merge a build summary into the remote index.json on R2.
Run after generate-manifest.py in CI.
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def rclone_cat(remote_path: str) -> dict:
    """Fetch JSON from R2, return empty dict if not found."""
    try:
        result = subprocess.run(
            ["rclone", "cat", remote_path],
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError:
        return {"schemaVersion": 1, "projects": {}}


def rclone_copyto(local_path: Path, remote_path: str) -> None:
    print(remote_path)
    subprocess.run(
        ["rclone", "copyto", str(local_path), remote_path],
        check=True,
    )


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--summary", required=True)
    p.add_argument("--r2-remote", required=True, help="e.g. r2:game-assets")
    p.add_argument("--project", required=True)
    args = p.parse_args()

    summary = json.loads(Path(args.summary).read_text())
    project = args.project

    remote_index = f"{args.r2_remote}/index.json"
    data = rclone_cat(remote_index)

    if "projects" not in data:
        data["projects"] = {}

    if project not in data["projects"]:
        data["projects"][project] = {
            "title": summary["title"],
            "theme": summary.get("theme", {}),
            "history": [],
        }

    entry = {
        "build": summary["build"],
        "revision": summary["revision"],
        "build_epoch": summary["build_epoch"],
        "summaryUrl": f"builds/{project}/{summary['build']}/{summary['revision']}/summary.json",
    }

    hist = [
        h
        for h in data["projects"][project]["history"]
        if h["revision"] != summary["revision"]
    ]
    hist.append(entry)
    hist.sort(key=lambda h: h["build_epoch"])
    data["projects"][project]["history"] = hist
    data["projects"][project]["latest"] = entry
    data["updated"] = summary["build"]

    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        json.dump(data, f, indent=2)
        tmp_path = f.name

    try:
        rclone_copyto(Path(tmp_path), remote_index)
        print(f"updated index: {remote_index}")
    finally:
        os.unlink(tmp_path)


if __name__ == "__main__":
    main()
