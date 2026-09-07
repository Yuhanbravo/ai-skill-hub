from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

RUNTIME_SURFACES = (
    "tools/run_local_checks.ps1",
    "tools/export_bundle.ps1",
    ".githooks/commit-msg",
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "tools/README.zh-CN.md",
    "tests/README.md",
    "docs/human/REPOSITORY_CONSUMPTION_GUIDE.md",
)


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def test_repo_python_is_the_runtime_authority() -> None:
    for relative_path in RUNTIME_SURFACES:
        assert "repo-python" in read(relative_path), f"missing repo-python authority: {relative_path}"


def test_runner_has_no_parallel_runtime_selector() -> None:
    runner = read("tools/run_local_checks.ps1")
    forbidden = (
        r"Get-Command\s+['\"]?(?:python|py|conda)['\"]?",
        r"CONDA_DEFAULT_ENV",
        r"conda\s+info\s+--envs",
        r"Join-Path[^\n]+python\.exe",
        r"Get-CondaEnvironmentExecutor",
        r"Get-ApplicationCandidates",
    )
    for pattern in forbidden:
        assert not re.search(pattern, runner, flags=re.IGNORECASE), pattern

    assert "-BrokerResolveOnly" in runner
    assert "-CondaEnvName is no longer supported" in runner
    assert "-UsePyLauncher is no longer supported" in runner


def test_bundle_and_hook_invoke_only_repo_python() -> None:
    bundle = read("tools/export_bundle.ps1")
    hook = read(".githooks/commit-msg")

    assert "& repo-python -PythonArgs @($validatorPath, '--message', $Message)" in bundle
    assert not re.search(r"(?m)^\s*&\s+(?:python|py|conda)\b", bundle, flags=re.IGNORECASE)
    assert "command -v repo-python.ps1" in hook
    assert ".local/bin/repo-python.ps1" in hook
    assert "& $env:ASH_REPO_PYTHON_PATH -PythonArgs" in hook
    assert '"skills/skill-governance/scripts/commit_convention_check.py"' in hook
    assert "$env:ASH_COMMIT_MESSAGE_PATH" in hook
    assert not re.search(r"(?m)^\s*(?:python|py|conda)\b", hook, flags=re.IGNORECASE)


def test_runtime_authority_surfaces_contain_no_machine_specific_python_ssot() -> None:
    machine_specific = (
        r"[A-Za-z]:\\[^\r\n`]*python\.exe",
        r"C:\\Users\\[^\r\n`]+",
        r"\\envs\\[^\r\n`]+\\python\.exe",
    )
    for relative_path in RUNTIME_SURFACES:
        content = read(relative_path)
        for pattern in machine_specific:
            assert not re.search(pattern, content, flags=re.IGNORECASE), (
                relative_path,
                pattern,
            )


def main() -> int:
    test_repo_python_is_the_runtime_authority()
    test_runner_has_no_parallel_runtime_selector()
    test_bundle_and_hook_invoke_only_repo_python()
    test_runtime_authority_surfaces_contain_no_machine_specific_python_ssot()
    print("runtime authority test passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
