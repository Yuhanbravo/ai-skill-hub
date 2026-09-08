from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "tools" / "run_local_checks.ps1"
LAUNCHER = ROOT / "tools" / "run_governed_python_workload.py"
EXPORT_BUNDLE = ROOT / "tools" / "export_bundle.ps1"
VALIDATOR = ROOT / "skills" / "skill-governance" / "scripts" / "commit_convention_check.py"
POWERSHELL = shutil.which("powershell.exe")
PWSH = shutil.which("pwsh.exe")


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def git(repo: Path, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *arguments],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=check,
    )


def powershell_command(executable: str, script: Path, *arguments: str) -> list[str]:
    command = [executable, "-NoProfile"]
    if Path(executable).name.lower() == "powershell.exe":
        command.extend(["-ExecutionPolicy", "Bypass"])
    command.extend(["-File", str(script), *arguments])
    return command


def available_powershell_runtimes() -> list[str]:
    return [runtime for runtime in (POWERSHELL, PWSH) if runtime]


def initialize_matching_repository(path: Path) -> Path:
    path.mkdir(parents=True)
    git(path, "init")
    origin = git(ROOT, "config", "--get", "remote.origin.url").stdout.strip()
    assert origin
    git(path, "remote", "add", "origin", origin)
    git(path, "config", "user.name", "Codex Test")
    git(path, "config", "user.email", "codex-test@example.invalid")
    return path


def build_runner_fixture(tmp_path: Path, workload_exit: int, diagnostic: str = "") -> Path:
    repo = initialize_matching_repository(tmp_path / "runner-repository")
    (repo / "tools").mkdir()
    shutil.copyfile(RUNNER, repo / "tools" / RUNNER.name)
    shutil.copyfile(LAUNCHER, repo / "tools" / LAUNCHER.name)
    workload = "import sys\n"
    if diagnostic:
        workload += f"print({diagnostic!r}, file=sys.stderr)\n"
    workload += f"raise SystemExit({workload_exit})\n"
    write_text(repo / "tests" / "test_skill_router.py", workload)
    return repo


def run_real_runner(
    repo: Path,
    executable: str,
    *,
    extra_env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)
    return subprocess.run(
        powershell_command(executable, repo / "tools" / RUNNER.name, "-Checks", "router"),
        cwd=repo.parent,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=env,
    )


@pytest.mark.parametrize("executable", available_powershell_runtimes())
@pytest.mark.parametrize(
    ("workload_exit", "diagnostic", "expected_exit", "expected_failure"),
    [
        (0, "", 0, ""),
        (73, "repo-python: ERROR: expected negative-case diagnostic", 1, "skill-router (workload"),
        (64, "", 1, "skill-router (workload"),
    ],
)
def test_real_broker_started_workload_classification_and_temp_cleanup(
    tmp_path: Path,
    executable: str,
    workload_exit: int,
    diagnostic: str,
    expected_exit: int,
    expected_failure: str,
) -> None:
    repo = build_runner_fixture(tmp_path, workload_exit, diagnostic)
    sibling = repo / ".tmp" / "keep-me"
    write_text(sibling / "evidence.txt", "preserve\n")

    result = run_real_runner(repo, executable)

    combined_output = result.stdout + result.stderr
    assert result.returncode == expected_exit, combined_output
    assert "Temp cleanup: PASS" in combined_output
    assert sibling.is_dir()
    assert sorted(path.name for path in sibling.parent.iterdir()) == ["keep-me"]
    if diagnostic:
        assert diagnostic in combined_output
    if expected_failure:
        assert expected_failure in combined_output
    else:
        assert "[PASS] All selected checks passed." in combined_output


@pytest.mark.parametrize("executable", available_powershell_runtimes())
def test_real_broker_resolution_failure_is_environment_failure_and_cleans_temp(
    tmp_path: Path, executable: str
) -> None:
    repo = build_runner_fixture(tmp_path, 0)
    sibling = repo / ".tmp" / "keep-me"
    write_text(sibling / "evidence.txt", "preserve\n")

    result = run_real_runner(
        repo,
        executable,
        extra_env={"AGENT_RUNTIME_CONFIG": str(tmp_path / "missing-runtime-config.json")},
    )

    combined_output = result.stdout + result.stderr
    assert result.returncode == 2, combined_output
    assert "repo-python broker resolution failed" in combined_output
    assert "Executor setup: environment" in combined_output
    assert "Temp cleanup: PASS" in combined_output
    assert sorted(path.name for path in sibling.parent.iterdir()) == ["keep-me"]


def build_export_fixture(tmp_path: Path, name: str) -> Path:
    repo = initialize_matching_repository(tmp_path / name)
    (repo / "tools").mkdir()
    shutil.copyfile(EXPORT_BUNDLE, repo / "tools" / EXPORT_BUNDLE.name)
    validator_target = repo / "skills" / "skill-governance" / "scripts" / VALIDATOR.name
    validator_target.parent.mkdir(parents=True)
    shutil.copyfile(VALIDATOR, validator_target)
    write_text(repo / "fixture.txt", "initial\n")
    git(repo, "add", ".")
    git(repo, "commit", "-m", "test: initial fixture")
    write_text(repo / "fixture.txt", "changed\n")
    return repo


def run_export(
    repo: Path,
    caller_cwd: Path,
    message: str,
    temp_root: Path,
    *,
    extra_env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    executable = POWERSHELL or PWSH
    if not executable:
        pytest.skip("No PowerShell runtime is available")
    output_dir = repo.parent / f"{repo.name}-bundles"
    temp_root.mkdir(parents=True)
    env = os.environ.copy()
    env["TEMP"] = str(temp_root)
    env["TMP"] = str(temp_root)
    if extra_env:
        env.update(extra_env)
    return subprocess.run(
        powershell_command(
            executable,
            repo / "tools" / EXPORT_BUNDLE.name,
            "-RepoPath",
            str(repo),
            "-OutputDir",
            str(output_dir),
            "-CommitMessage",
            message,
        ),
        cwd=caller_cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=env,
    )


@pytest.mark.parametrize(
    ("caller_location", "message", "expected_exit"),
    [
        ("repo", "fix(repo): align runtime entry", 0),
        ("outside", "fix(repo): align runtime entry", 0),
        ("outside", "fix(repo): align runtime entry\n\n- preserve governed execution", 0),
        ("outside", "invalid multiline subject\n\n- rejected by validator", 1),
        ("outside", "fix(repo): align runtime entry\n\n- 保留受治理的执行路径", 0),
    ],
)
def test_export_validator_binds_target_repo_and_uses_message_file(
    tmp_path: Path,
    caller_location: str,
    message: str,
    expected_exit: int,
) -> None:
    repo = build_export_fixture(tmp_path, f"export-{caller_location}-{expected_exit}")
    caller_cwd = repo if caller_location == "repo" else tmp_path
    message_temp = tmp_path / f"message-temp-{caller_location}-{expected_exit}"

    result = run_export(repo, caller_cwd, message, message_temp)

    combined_output = result.stdout + result.stderr
    assert result.returncode == expected_exit, combined_output
    assert not list(message_temp.glob(".ash-commit-message-*.txt"))
    latest_message = git(repo, "log", "-1", "--pretty=%B").stdout.rstrip("\r\n")
    if expected_exit == 0:
        assert latest_message == message.rstrip("\r\n")
        assert "Bundle export completed" in combined_output
    else:
        assert latest_message == "test: initial fixture"
        assert "Commit message does not satisfy" in combined_output


def test_export_cleans_message_file_after_real_broker_failure(tmp_path: Path) -> None:
    repo = build_export_fixture(tmp_path, "export-broker-failure")
    message_temp = tmp_path / "message-temp-broker-failure"

    result = run_export(
        repo,
        tmp_path,
        "fix(repo): align runtime entry",
        message_temp,
        extra_env={"AGENT_RUNTIME_CONFIG": str(tmp_path / "missing-runtime-config.json")},
    )

    assert result.returncode == 1, result.stdout + result.stderr
    assert not list(message_temp.glob(".ash-commit-message-*.txt"))
    assert git(repo, "log", "-1", "--pretty=%s").stdout.strip() == "test: initial fixture"
