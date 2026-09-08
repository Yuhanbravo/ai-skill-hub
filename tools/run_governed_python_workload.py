from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def parse_args() -> tuple[Path, list[str]]:
    parser = argparse.ArgumentParser(
        description="Mark governed Python startup and run a workload with the inherited interpreter."
    )
    parser.add_argument("--started-marker", required=True, type=Path)
    parser.add_argument("workload", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    workload = list(args.workload)
    if workload[:1] == ["--"]:
        workload = workload[1:]
    if not workload:
        parser.error("a workload is required after --")
    return args.started_marker, workload


def main() -> int:
    started_marker, workload = parse_args()
    started_marker.parent.mkdir(parents=True, exist_ok=True)
    with started_marker.open("x", encoding="utf-8"):
        pass
    return subprocess.run([sys.executable, *workload], check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
