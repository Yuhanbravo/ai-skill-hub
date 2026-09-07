from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "skills" / "skill-governance" / "scripts" / "commit_convention_check.py"


def assert_equal(actual: object, expected: object, message: str) -> None:
    if actual != expected:
        raise AssertionError(f"{message}: expected={expected!r}, actual={actual!r}")


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_module():
    spec = importlib.util.spec_from_file_location("commit_convention_check", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Failed to load commit_convention_check module.")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def test_message_validation() -> None:
    module = load_module()

    valid_messages = [
        "docs: complete bridge reference audit and confirm mirror-only role\n",
        "feat(sync): add non-git project skill sync script\n",
        "feat(tools): add offline bundle import/export scripts\n",
        "chore(bundle): auto-commit before export (2026-03-26 17:44:09)\n",
        "docs: Phase 3 - bridge - switch compatibility links to active sources\n",
        "feat: add commit convention validator\n\n- wire commit-msg hook\n- validate export auto-commit path\n",
        "docs: refresh governance quick-start guidance\n\nDocument how new clones enable commit-msg validation.\n",
    ]
    invalid_messages = [
        "update docs\n",
        "feat(sync) add non-git project skill sync script\n",
        "Docs: refresh governance quick-start guidance\n",
        "feat(sync_tools): add non-git project skill sync script\n",
        "fix:\n",
        "docs: Phase audit - bridge - check docs\n",
        "feat(sync): Phase 3 - add non-git project skill sync script\n",
        "docs: complete bridge reference audit\nbody without separator\n",
        "feat: add validator\n\nmisc\n",
        "feat: add validator\n\n- ok\n",
    ]

    for message in valid_messages:
        assert_equal(module.validate_message_text(message), [], f"message should pass: {message!r}")

    for message in invalid_messages:
        assert_true(module.validate_message_text(message), f"message should fail: {message!r}")


def test_cli_with_message_file() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        commit_message_path = Path(temp_dir) / "COMMIT_EDITMSG"
        write_file(commit_message_path, "update docs\n")

        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), str(commit_message_path)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert_equal(result.returncode, 1, "CLI must exit with code 1 for invalid commit messages")
        assert_true("Commit message validation failed" in result.stderr, "CLI error header missing")
        assert_true("Subject must match" in result.stderr, "CLI subject guidance missing")


def test_cli_accepts_valid_message_file() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        commit_message_path = Path(temp_dir) / "COMMIT_EDITMSG"
        write_file(
            commit_message_path,
            "feat: add commit convention validator\n\n- wire commit-msg hook\n- validate export auto-commit path\n",
        )

        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), str(commit_message_path)],
            capture_output=True,
            text=True,
            check=False,
        )

        assert_equal(result.returncode, 0, "CLI must exit with code 0 for valid commit messages")
        assert_equal(result.stderr, "", "CLI should not emit stderr for valid commit messages")


def main() -> int:
    test_message_validation()
    test_cli_with_message_file()
    test_cli_accepts_valid_message_file()
    print("commit convention check test passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
