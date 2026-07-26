from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "manage_codex_user_skills.ps1"
RUN_LOCAL_CHECKS = ROOT / "tools" / "run_local_checks.ps1"
DESCRIPTOR = ROOT / "tools" / "codex_user_skills_manifest.json"
MANIFEST_NAME = ".ai-skill-hub-user-skills.json"
LOCK_NAME = ".ai-skill-hub-user-skills.lock"
MANAGED = ("workflow-bootstrap", "chatgpt-handoff-pilot", "_protocol")
POWERSHELL = shutil.which("powershell.exe")
PWSH = shutil.which("pwsh.exe")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=True,
    )


def commit_all(repo: Path, message: str = "test fixture") -> None:
    git(repo, "add", ".")
    git(
        repo,
        "-c",
        "user.name=Codex Test",
        "-c",
        "user.email=codex-test@example.invalid",
        "commit",
        "-m",
        message,
    )


def build_repository(parent: Path, name: str = "fixture-repository") -> Path:
    repo = parent / name
    repo.mkdir(parents=True)
    (repo / "tools").mkdir()
    shutil.copyfile(DESCRIPTOR, repo / "tools" / DESCRIPTOR.name)

    workflow_skill = """---
name: workflow-bootstrap
description: "fixture workflow"
metadata:
  triggers:
    - fixture one
    - fixture two
    - fixture three
  side_effects:
    - read_only
---
# Workflow Bootstrap

- [Local guide](README.md)
- [Shared protocol](../_protocol/skill_assessment_output.md)
"""
    handoff_skill = """---
name: chatgpt-handoff-pilot
description: "fixture handoff"
metadata:
  triggers:
    - fixture one
    - fixture two
    - fixture three
  side_effects:
    - read_only
---
# ChatGPT Handoff Pilot

- [Local guide](README.md)
- [Shared protocol](../_protocol/skill_assessment_output.md)
"""
    write_text(repo / "skills" / "workflow-bootstrap" / "SKILL.md", workflow_skill)
    write_text(repo / "skills" / "workflow-bootstrap" / "README.md", "# Workflow fixture\n")
    write_text(repo / "skills" / "chatgpt-handoff-pilot" / "SKILL.md", handoff_skill)
    write_text(repo / "skills" / "chatgpt-handoff-pilot" / "README.md", "# Handoff fixture\n")
    write_text(
        repo / "skills" / "_protocol" / "skill_assessment_output.md",
        "# Shared fixture protocol\n",
    )

    git(repo, "init")
    git(repo, "config", "core.autocrlf", "false")
    commit_all(repo)
    return repo


def build_real_payload_repository(parent: Path) -> Path:
    repo = parent / "real-canonical-payload-fixture"
    (repo / "tools").mkdir(parents=True)
    shutil.copyfile(DESCRIPTOR, repo / "tools" / DESCRIPTOR.name)
    for skill_name in ("workflow-bootstrap", "chatgpt-handoff-pilot"):
        shutil.copytree(ROOT / "skills" / skill_name, repo / "skills" / skill_name)
    protocol_target = repo / "skills" / "_protocol" / "skill_assessment_output.md"
    protocol_target.parent.mkdir(parents=True)
    shutil.copyfile(ROOT / "skills" / "_protocol" / "skill_assessment_output.md", protocol_target)
    git(repo, "init")
    git(repo, "config", "core.autocrlf", "false")
    commit_all(repo, "real canonical payload fixture")
    return repo


def run_manager(
    repo: Path,
    codex_home: Path | str,
    action: str | None = "Check",
    *,
    output_format: str = "Json",
    executable: str | None = None,
    injection: str | None = None,
) -> tuple[subprocess.CompletedProcess[str], dict]:
    shell = executable or POWERSHELL or PWSH
    if not shell:
        pytest.skip("No PowerShell runtime is available")
    command = [shell, "-NoProfile"]
    if Path(shell).name.lower() == "powershell.exe":
        command.extend(["-ExecutionPolicy", "Bypass"])
    command.extend(["-File", str(SCRIPT)])
    if action is not None:
        command.extend(["-Action", action])
    command.extend(
        [
            "-RepositoryRoot",
            str(repo),
            "-OutputFormat",
            output_format,
        ]
    )
    fake_home = repo.parent / "fake-user-home"
    fake_home.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["CODEX_HOME"] = str(codex_home)
    env["HOME"] = str(fake_home)
    env["USERPROFILE"] = str(fake_home)
    env["AI_SKILL_HUB_TEST_MODE"] = "1"
    if injection:
        env["AI_SKILL_HUB_TEST_INJECT"] = injection
    else:
        env.pop("AI_SKILL_HUB_TEST_INJECT", None)
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=env,
    )
    payload: dict = {}
    if output_format == "Json":
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise AssertionError(
                f"invalid JSON output\nexit={result.returncode}\nstdout={result.stdout}\nstderr={result.stderr}"
            ) from exc
    else:
        payload = {
            line.split("=", 1)[0]: line.split("=", 1)[1]
            for line in result.stdout.splitlines()
            if "=" in line
        }
    return result, payload


def assert_run(
    result: subprocess.CompletedProcess[str],
    payload: dict,
    decision: str,
    exit_code: int,
) -> None:
    assert result.returncode == exit_code, (result.stdout, result.stderr)
    assert payload["Decision"] == decision
    assert payload["System_Skill_Protection"] == "ENFORCED"
    assert payload["External_Verification_Required"] == "YES"
    assert str(Path.home()) not in result.stdout
    assert "$CODEX_HOME" in result.stdout


def safe_snapshot(root: Path) -> tuple[str, ...]:
    if not root.exists() and not root.is_symlink():
        return ()
    records: list[str] = []
    pending = [root]
    while pending:
        current = pending.pop()
        try:
            children = list(os.scandir(current))
        except (NotADirectoryError, FileNotFoundError, PermissionError):
            continue
        for child in sorted(children, key=lambda item: item.name):
            child_path = Path(child.path)
            relative = child_path.relative_to(root).as_posix()
            if child.is_symlink():
                records.append(f"{relative}|link|{os.readlink(child.path)}")
            elif child.is_dir(follow_symlinks=False):
                records.append(f"{relative}|directory")
                pending.append(child_path)
            elif child.is_file(follow_symlinks=False):
                digest = hashlib.sha256(child_path.read_bytes()).hexdigest()
                records.append(f"{relative}|file|{digest}")
            else:
                records.append(f"{relative}|other")
    return tuple(sorted(records))


def is_link_or_junction(path: Path) -> bool:
    is_junction = getattr(os.path, "isjunction", lambda _: False)
    return path.is_symlink() or is_junction(path)


def user_skill_scope_snapshot(root: Path) -> tuple[str, ...]:
    if is_link_or_junction(root):
        try:
            target_digest = hashlib.sha256(os.fsencode(os.readlink(root))).hexdigest()
        except OSError:
            target_digest = "unreadable"
        return (f".|link|{target_digest}",)
    if not root.exists():
        return (".|missing",)
    if root.is_file():
        try:
            digest = hashlib.sha256(root.read_bytes()).hexdigest()
        except OSError:
            digest = "unreadable"
        return (f".|file|{digest}",)
    if not root.is_dir():
        return (".|other",)

    records = [".|directory"]
    pending = [root]
    while pending:
        current = pending.pop()
        try:
            children = list(os.scandir(current))
        except (FileNotFoundError, NotADirectoryError, PermissionError):
            relative = current.relative_to(root).as_posix() or "."
            records.append(f"{relative}|inaccessible")
            continue

        for child in sorted(children, key=lambda item: item.name):
            child_path = Path(child.path)
            relative = child_path.relative_to(root).as_posix()
            if is_link_or_junction(child_path):
                try:
                    target_digest = hashlib.sha256(
                        os.fsencode(os.readlink(child_path))
                    ).hexdigest()
                except OSError:
                    target_digest = "unreadable"
                records.append(f"{relative}|link|{target_digest}")
            elif child.is_dir(follow_symlinks=False):
                records.append(f"{relative}|directory")
                pending.append(child_path)
            elif child.is_file(follow_symlinks=False):
                try:
                    digest = hashlib.sha256(child_path.read_bytes()).hexdigest()
                except OSError:
                    digest = "unreadable"
                records.append(f"{relative}|file|{digest}")
            else:
                records.append(f"{relative}|other")
    return tuple(sorted(records))


def sentinel_snapshot(paths: tuple[Path, ...]) -> tuple[tuple[str, bool, int, int], ...]:
    values: list[tuple[str, bool, int, int]] = []
    for path in paths:
        try:
            stat = path.stat()
            values.append((str(path), True, stat.st_mtime_ns, stat.st_size))
        except OSError:
            values.append((str(path), False, 0, 0))
    return tuple(values)


@pytest.fixture(scope="session", autouse=True)
def protect_real_user_and_business_roots():
    user_home = Path.home()
    user_skill_roots = (
        user_home / ".codex" / "skills",
        user_home / ".agents" / "skills",
    )
    business_roots = (
        Path(r"D:\dev\Derivative_Data"),
        Path(r"D:\dev\AMS_Data"),
        Path(r"D:\dev\Workstation_Ops"),
    )
    before_user_skills = tuple(
        user_skill_scope_snapshot(path) for path in user_skill_roots
    )
    before_business_roots = sentinel_snapshot(business_roots)
    yield
    assert tuple(user_skill_scope_snapshot(path) for path in user_skill_roots) == (
        before_user_skills
    )
    assert sentinel_snapshot(business_roots) == before_business_roots


def test_user_skill_snapshot_ignores_codex_parent_mtime(tmp_path: Path) -> None:
    codex_parent = tmp_path / ".codex"
    skills = codex_parent / "skills"
    write_text(skills / "fixture-skill" / "SKILL.md", "fixture\n")
    before = user_skill_scope_snapshot(skills)
    parent_stat = codex_parent.stat()

    os.utime(
        codex_parent,
        ns=(parent_stat.st_atime_ns, parent_stat.st_mtime_ns + 1_000_000_000),
    )

    assert user_skill_scope_snapshot(skills) == before


def test_user_skill_snapshot_detects_codex_file_content_change(tmp_path: Path) -> None:
    skills = tmp_path / ".codex" / "skills"
    skill_file = skills / "fixture-skill" / "SKILL.md"
    write_text(skill_file, "first\n")
    before = user_skill_scope_snapshot(skills)

    write_text(skill_file, "other\n")

    assert user_skill_scope_snapshot(skills) != before


def test_user_skill_snapshot_detects_agents_file_addition(tmp_path: Path) -> None:
    skills = tmp_path / ".agents" / "skills"
    skills.mkdir(parents=True)
    before = user_skill_scope_snapshot(skills)

    write_text(skills / "fixture-skill" / "SKILL.md", "fixture\n")

    assert user_skill_scope_snapshot(skills) != before


def test_user_skill_snapshot_detects_manifest_creation(tmp_path: Path) -> None:
    skills = tmp_path / ".codex" / "skills"
    skills.mkdir(parents=True)
    before = user_skill_scope_snapshot(skills)

    write_text(skills / MANIFEST_NAME, "{}\n")

    assert user_skill_scope_snapshot(skills) != before


def test_user_skill_snapshot_handles_missing_root_stably(tmp_path: Path) -> None:
    skills = tmp_path / ".codex" / "skills"

    assert user_skill_scope_snapshot(skills) == (".|missing",)
    assert user_skill_scope_snapshot(skills) == user_skill_scope_snapshot(skills)


def test_user_skill_snapshot_detects_deletion_and_type_change(tmp_path: Path) -> None:
    skills = tmp_path / ".codex" / "skills"
    entry = skills / "fixture-entry"
    write_text(entry, "fixture\n")
    file_snapshot = user_skill_scope_snapshot(skills)

    entry.unlink()
    missing_entry_snapshot = user_skill_scope_snapshot(skills)
    entry.mkdir()
    directory_snapshot = user_skill_scope_snapshot(skills)

    assert missing_entry_snapshot != file_snapshot
    assert directory_snapshot != missing_entry_snapshot
    assert directory_snapshot != file_snapshot


def run_local_check_runner(
    tmp_path: Path,
    path_entries: tuple[Path, ...],
    *,
    conda_env_name: str | None = None,
    extra_env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    shell = POWERSHELL or PWSH
    if not shell:
        pytest.skip("No PowerShell runtime is available")

    fake_home = tmp_path / "fake-user-home"
    fake_codex_home = tmp_path / "fake-codex-home"
    fake_home.mkdir(parents=True)
    env = os.environ.copy()
    env["PATH"] = os.pathsep.join(str(path) for path in path_entries)
    env["PATHEXT"] = ".COM;.EXE;.BAT;.CMD"
    env["HOME"] = str(fake_home)
    env["USERPROFILE"] = str(fake_home)
    env["CODEX_HOME"] = str(fake_codex_home)
    env.pop("CONDA_DEFAULT_ENV", None)
    if extra_env:
        env.update(extra_env)

    command = [shell, "-NoProfile"]
    if Path(shell).name.lower() == "powershell.exe":
        command.extend(["-ExecutionPolicy", "Bypass"])
    command.extend(["-File", str(RUN_LOCAL_CHECKS), "-Checks", "router"])
    if conda_env_name:
        command.extend(["-CondaEnvName", conda_env_name])

    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=env,
    )


def write_failing_python_stub(
    directory: Path, invocation_log: Path | None = None
) -> Path:
    stub = directory / "python.cmd"
    log_command = (
        f'echo %*>>"{invocation_log}"\n' if invocation_log is not None else ""
    )
    write_text(
        stub,
        "@echo off\n"
        + log_command
        + "echo SIMULATED_WINDOWS_APPS_STUB 1>&2\n"
        "exit /b 9009\n",
    )
    return stub


def system32_path() -> Path:
    return Path(os.environ["SystemRoot"]) / "System32"


def test_runner_skips_9009_python_stub_for_later_valid_python(tmp_path: Path) -> None:
    stub_directory = tmp_path / "windowsapps-stub"
    stub_invocations = tmp_path / "python-stub-invocations.log"
    write_failing_python_stub(stub_directory, stub_invocations)

    result = run_local_check_runner(
        tmp_path,
        (stub_directory, Path(sys.executable).parent, system32_path()),
    )

    combined_output = result.stdout + result.stderr
    assert result.returncode == 0, combined_output
    assert f"Executor: {sys.executable}".casefold() in combined_output.casefold()
    assert "--version" in stub_invocations.read_text(encoding="utf-8")
    assert "SIMULATED_WINDOWS_APPS_STUB" not in combined_output
    assert "[PASS] All selected checks passed." in combined_output


def test_runner_explicit_conda_env_precedes_unusable_python(tmp_path: Path) -> None:
    stub_directory = tmp_path / "executor-stubs"
    write_failing_python_stub(stub_directory)
    invocation_log = tmp_path / "conda-invocations.log"
    write_text(
        stub_directory / "conda.cmd",
        "@echo off\n"
        'echo %*>>"%EXECUTOR_INVOCATION_LOG%"\n'
        'if /I not "%~1"=="run" exit /b 91\n'
        'if /I not "%~2"=="-n" exit /b 92\n'
        'if /I not "%~3"=="selected-env" exit /b 93\n'
        'if /I not "%~4"=="python" exit /b 94\n'
        "shift\n"
        "shift\n"
        "shift\n"
        "shift\n"
        f'"{sys.executable}" "%~1"\n'
        "exit /b %ERRORLEVEL%\n",
    )

    result = run_local_check_runner(
        tmp_path,
        (stub_directory, system32_path()),
        conda_env_name="selected-env",
        extra_env={"EXECUTOR_INVOCATION_LOG": str(invocation_log)},
    )

    combined_output = result.stdout + result.stderr
    assert result.returncode == 0, combined_output
    assert "run -n selected-env python" in combined_output
    invocations = invocation_log.read_text(encoding="utf-8")
    assert "run -n selected-env python --version" in invocations
    assert r"run -n selected-env python tests\test_skill_router.py" in invocations
    assert "SIMULATED_WINDOWS_APPS_STUB" not in combined_output


def test_runner_fails_before_checks_when_all_candidates_are_unusable(
    tmp_path: Path,
) -> None:
    stub_directory = tmp_path / "only-invalid-python"
    stub_invocations = tmp_path / "python-stub-invocations.log"
    write_failing_python_stub(stub_directory, stub_invocations)

    result = run_local_check_runner(
        tmp_path,
        (stub_directory, system32_path()),
    )

    combined_output = result.stdout + result.stderr
    assert result.returncode == 2, combined_output
    assert "no Python executor candidate successfully returned version information" in (
        combined_output
    )
    assert "Running skill-router:" not in combined_output
    assert "--version" in stub_invocations.read_text(encoding="utf-8")
    assert "SIMULATED_WINDOWS_APPS_STUB" not in combined_output


def test_runner_uses_normal_valid_python_unchanged(tmp_path: Path) -> None:
    result = run_local_check_runner(
        tmp_path,
        (Path(sys.executable).parent, system32_path()),
    )

    combined_output = result.stdout + result.stderr
    assert result.returncode == 0, combined_output
    assert f"Executor: {sys.executable}".casefold() in combined_output.casefold()
    assert "[PASS] All selected checks passed." in combined_output


@pytest.fixture()
def isolated(tmp_path: Path) -> tuple[Path, Path]:
    repo = build_repository(tmp_path)
    return repo, tmp_path / "temporary-codex-home"


def install(repo: Path, codex_home: Path) -> dict:
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_APPLY", 0)
    return payload


def read_manifest(codex_home: Path) -> dict:
    return json.loads((codex_home / "skills" / MANIFEST_NAME).read_text(encoding="utf-8"))


def write_manifest(codex_home: Path, value: dict | str) -> None:
    path = codex_home / "skills" / MANIFEST_NAME
    if isinstance(value, str):
        path.write_text(value, encoding="utf-8", newline="\n")
    else:
        path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def test_fresh_target_and_manifest_contract(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_APPLY", 0)
    assert payload["Changed_Count"] == 3
    skills = codex_home / "skills"
    assert (skills / "workflow-bootstrap" / "SKILL.md").is_file()
    assert (skills / "chatgpt-handoff-pilot" / "SKILL.md").is_file()
    assert (skills / "_protocol" / "skill_assessment_output.md").is_file()
    assert sorted(path.name for path in (skills / "_protocol").iterdir()) == ["skill_assessment_output.md"]
    manifest = read_manifest(codex_home)
    assert manifest["manager"] == "ai-skill-hub.codex-user-skills/v1"
    assert manifest["target_root"].lower() == str(skills).lower()
    assert len(manifest["managed_entries"]) == 3
    assert {entry["relative_target_path"] for entry in manifest["managed_entries"]} == set(MANAGED)


def test_repeated_apply_is_zero_write(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT", 0)
    assert payload["Changed_Count"] == 0
    assert safe_snapshot(codex_home) == before


def test_current_owned_install_check(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Check")
    assert_run(result, payload, "NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT", 0)
    assert payload["Current_Status"] == "CURRENT"
    assert safe_snapshot(codex_home) == before


def test_stale_owned_install_updates_only_changed_entry(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    skills = codex_home / "skills"
    unchanged_before = {
        "chatgpt": safe_snapshot(skills / "chatgpt-handoff-pilot"),
        "protocol": safe_snapshot(skills / "_protocol"),
    }
    write_text(repo / "skills" / "workflow-bootstrap" / "README.md", "# Workflow fixture v2\n")
    commit_all(repo, "update workflow fixture")
    check_result, check_payload = run_manager(repo, codex_home, "Check")
    assert_run(check_result, check_payload, "PASS_CODEX_USER_SKILLS_CHECK", 0)
    assert check_payload["Current_Status"] == "SOURCE_UPDATE_AVAILABLE"
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_APPLY", 0)
    assert payload["Changed_Count"] == 1
    assert safe_snapshot(skills / "chatgpt-handoff-pilot") == unchanged_before["chatgpt"]
    assert safe_snapshot(skills / "_protocol") == unchanged_before["protocol"]
    assert (skills / "workflow-bootstrap" / "README.md").read_text(encoding="utf-8") == "# Workflow fixture v2\n"


@pytest.mark.parametrize("kind", ["directory", "file"])
def test_unknown_target_conflict_is_preserved(tmp_path: Path, kind: str) -> None:
    repo = build_repository(tmp_path)
    codex_home = tmp_path / "codex-home"
    target = codex_home / "skills" / "workflow-bootstrap"
    if kind == "directory":
        write_text(target / "unknown.txt", "do not replace\n")
    else:
        write_text(target, "do not replace\n")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Apply")
    expected = "BLOCKED_MANIFEST_MISSING" if kind == "directory" else "BLOCKED_TARGET_CONFLICT"
    assert_run(result, payload, expected, 2)
    assert safe_snapshot(codex_home) == before


def create_junction(link: Path, target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    link.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        ["cmd.exe", "/d", "/c", "mklink", "/J", str(link), str(target)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if result.returncode != 0:
        pytest.skip(f"junction creation unavailable: {result.stdout} {result.stderr}")


def test_existing_junction_is_blocked_without_following(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    codex_home = tmp_path / "codex-home"
    outside = tmp_path / "junction-source"
    write_text(outside / "sentinel.txt", "outside\n")
    link = codex_home / "skills" / "workflow-bootstrap"
    create_junction(link, outside)
    before = safe_snapshot(outside)
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "BLOCKED_UNKNOWN_PROVENANCE", 2)
    assert safe_snapshot(outside) == before


def test_broken_junction_is_blocked(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    codex_home = tmp_path / "codex-home"
    outside = tmp_path / "junction-source"
    link = codex_home / "skills" / "workflow-bootstrap"
    create_junction(link, outside)
    shutil.rmtree(outside)
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "BLOCKED_BROKEN_LINK", 2)
    assert not outside.exists()


def test_missing_skill_md_blocks_canonical_source(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    (repo / "skills" / "workflow-bootstrap" / "SKILL.md").unlink()
    commit_all(repo, "remove skill definition")
    result, payload = run_manager(repo, tmp_path / "codex-home")
    assert_run(result, payload, "BLOCKED_CANONICAL_SOURCE_INVALID", 2)


def test_missing_dependency_blocks_closure(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    (repo / "skills" / "_protocol" / "skill_assessment_output.md").unlink()
    commit_all(repo, "remove dependency")
    result, payload = run_manager(repo, tmp_path / "codex-home")
    assert_run(result, payload, "BLOCKED_DEPENDENCY_CLOSURE_INVALID", 2)


def test_repository_and_codex_home_paths_with_spaces(tmp_path: Path) -> None:
    repo = build_repository(tmp_path, "hub fixture with spaces")
    codex_home = tmp_path / "codex home with spaces"
    for action, decision in (
        ("Check", "PASS_CODEX_USER_SKILLS_CHECK"),
        ("Plan", "PASS_CODEX_USER_SKILLS_PLAN"),
        ("Apply", "PASS_CODEX_USER_SKILLS_APPLY"),
        ("Uninstall", "PASS_CODEX_USER_SKILLS_UNINSTALL"),
    ):
        result, payload = run_manager(repo, codex_home, action)
        assert_run(result, payload, decision, 0)


def test_real_canonical_payload_dependency_closure_and_lifecycle(tmp_path: Path) -> None:
    repo = build_real_payload_repository(tmp_path)
    codex_home = tmp_path / "real-payload-codex-home"
    for action, decision in (
        ("Check", "PASS_CODEX_USER_SKILLS_CHECK"),
        ("Plan", "PASS_CODEX_USER_SKILLS_PLAN"),
        ("Apply", "PASS_CODEX_USER_SKILLS_APPLY"),
        ("Apply", "NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT"),
        ("Uninstall", "PASS_CODEX_USER_SKILLS_UNINSTALL"),
    ):
        result, payload = run_manager(repo, codex_home, action)
        assert_run(result, payload, decision, 0)
    assert not (codex_home / "skills" / MANIFEST_NAME).exists()


@pytest.mark.parametrize(
    ("raw_home", "decision"),
    [
        ("relative-codex-home", "BLOCKED_PATH_SAFETY_VIOLATION"),
        (r"\\server\share\codex", "BLOCKED_PATH_SAFETY_VIOLATION"),
        ("C:\\", "BLOCKED_PATH_SAFETY_VIOLATION"),
        (" ", "BLOCKED_CODEX_HOME_UNRESOLVED"),
        ("C:\\bad*path", "BLOCKED_PATH_SAFETY_VIOLATION"),
    ],
)
def test_unsafe_codex_home_values_are_blocked(tmp_path: Path, raw_home: str, decision: str) -> None:
    repo = build_repository(tmp_path)
    result, payload = run_manager(repo, raw_home)
    assert_run(result, payload, decision, 2)


def test_trailing_separator_is_normalized(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    result, payload = run_manager(repo, str(codex_home) + "\\\\", "Apply")
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_APPLY", 0)
    manifest = read_manifest(codex_home)
    assert not manifest["target_root"].endswith(("\\", "/"))


def test_repository_overlap_is_blocked(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    result, payload = run_manager(repo, repo / "nested-codex-home")
    assert_run(result, payload, "BLOCKED_PATH_SAFETY_VIOLATION", 2)


def test_file_codex_home_is_blocked(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    codex_home = tmp_path / "codex-home-file"
    write_text(codex_home, "file\n")
    result, payload = run_manager(repo, codex_home)
    assert_run(result, payload, "BLOCKED_PATH_SAFETY_VIOLATION", 2)


def test_reparse_codex_home_is_blocked(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    outside = tmp_path / "outside-home"
    codex_home = tmp_path / "codex-home-link"
    create_junction(codex_home, outside)
    result, payload = run_manager(repo, codex_home)
    assert_run(result, payload, "BLOCKED_PATH_SAFETY_VIOLATION", 2)


def test_broken_reparse_codex_home_is_blocked(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    outside = tmp_path / "outside-home"
    codex_home = tmp_path / "broken-codex-home-link"
    create_junction(codex_home, outside)
    shutil.rmtree(outside)
    result, payload = run_manager(repo, codex_home)
    assert_run(result, payload, "BLOCKED_PATH_SAFETY_VIOLATION", 2)


def test_system_and_unrelated_entries_are_preserved(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    write_text(codex_home / "skills" / ".system" / "system.txt", "system-owned\n")
    write_text(codex_home / "skills" / "unrelated-skill" / "SKILL.md", "unrelated\n")
    protected_before = {
        "system": safe_snapshot(codex_home / "skills" / ".system"),
        "unrelated": safe_snapshot(codex_home / "skills" / "unrelated-skill"),
    }
    install(repo, codex_home)
    result, payload = run_manager(repo, codex_home, "Uninstall")
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_UNINSTALL", 0)
    assert safe_snapshot(codex_home / "skills" / ".system") == protected_before["system"]
    assert safe_snapshot(codex_home / "skills" / "unrelated-skill") == protected_before["unrelated"]


def test_apply_partial_failure_rolls_back(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    write_text(codex_home / "skills" / ".system" / "sentinel.txt", "system\n")
    write_text(codex_home / "skills" / "other" / "sentinel.txt", "other\n")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Apply", injection="ApplyAfterFirstMove")
    assert_run(result, payload, "BLOCKED_UNEXPECTED_ERROR", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    assert safe_snapshot(codex_home) == before


def test_uninstall_partial_failure_rolls_back(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    write_text(codex_home / "skills" / ".system" / "sentinel.txt", "system\n")
    write_text(codex_home / "skills" / "other" / "sentinel.txt", "other\n")
    install(repo, codex_home)
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Uninstall", injection="UninstallAfterFirstMove")
    assert_run(result, payload, "BLOCKED_UNEXPECTED_ERROR", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    assert safe_snapshot(codex_home) == before


def test_manifest_write_failure_rolls_back(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Apply", injection="ManifestWrite")
    assert_run(result, payload, "BLOCKED_UNEXPECTED_ERROR", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    assert safe_snapshot(codex_home) == before


def test_upgrade_failure_after_backup_restores_owned_target(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    write_text(repo / "skills" / "workflow-bootstrap" / "README.md", "source update\n")
    commit_all(repo, "source update")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Apply", injection="ApplyAfterBackup")
    assert_run(result, payload, "BLOCKED_UNEXPECTED_ERROR", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    assert safe_snapshot(codex_home) == before


@pytest.mark.parametrize(
    "mutation",
    ["missing", "extra", "corrupt", "schema", "missing_top", "wrong_type", "timestamp"],
)
def test_invalid_manifest_is_never_repaired(isolated: tuple[Path, Path], mutation: str) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    manifest = read_manifest(codex_home)
    if mutation == "missing":
        manifest["managed_entries"].pop()
        write_manifest(codex_home, manifest)
    elif mutation == "extra":
        manifest["managed_entries"].append(dict(manifest["managed_entries"][0], relative_target_path="extra"))
        write_manifest(codex_home, manifest)
    elif mutation == "schema":
        manifest["schema_version"] = 999
        write_manifest(codex_home, manifest)
    elif mutation == "missing_top":
        del manifest["manager"]
        write_manifest(codex_home, manifest)
    elif mutation == "wrong_type":
        manifest["schema_version"] = "1"
        write_manifest(codex_home, manifest)
    elif mutation == "timestamp":
        manifest["updated_at"] = "not-a-timestamp"
        write_manifest(codex_home, manifest)
    else:
        write_manifest(codex_home, "{not-json")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "BLOCKED_MANIFEST_INVALID", 2)
    assert safe_snapshot(codex_home) == before


def test_manifest_target_mismatch_is_blocked(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    manifest = read_manifest(codex_home)
    manifest["target_root"] = str(codex_home.parent / "other" / "skills")
    write_manifest(codex_home, manifest)
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Uninstall")
    assert_run(result, payload, "BLOCKED_MANIFEST_TARGET_MISMATCH", 2)
    assert safe_snapshot(codex_home) == before


@pytest.mark.parametrize("action", ["Apply", "Uninstall"])
def test_local_modification_blocks_mutation(isolated: tuple[Path, Path], action: str) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    local_file = codex_home / "skills" / "workflow-bootstrap" / "README.md"
    local_file.write_text("local modification\n", encoding="utf-8", newline="\n")
    if action == "Apply":
        write_text(repo / "skills" / "workflow-bootstrap" / "README.md", "source update\n")
        commit_all(repo, "source update")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, action)
    assert_run(result, payload, "BLOCKED_LOCAL_MODIFICATION", 2)
    assert payload["Local_Modification_Count"] == 1
    assert safe_snapshot(codex_home) == before


def test_unexpected_protocol_file_is_local_modification(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    write_text(codex_home / "skills" / "_protocol" / "unexpected.md", "unexpected\n")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Uninstall")
    assert_run(result, payload, "BLOCKED_LOCAL_MODIFICATION", 2)
    assert safe_snapshot(codex_home) == before


def test_clean_and_repeated_uninstall(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    result, payload = run_manager(repo, codex_home, "Uninstall")
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_UNINSTALL", 0)
    for entry in MANAGED:
        assert not (codex_home / "skills" / entry).exists()
    assert not (codex_home / "skills" / MANIFEST_NAME).exists()
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Uninstall")
    assert_run(result, payload, "NO_CHANGE_CODEX_USER_SKILLS_NOT_INSTALLED", 0)
    assert safe_snapshot(codex_home) == before


@pytest.mark.parametrize(
    ("action", "decision"),
    [("Check", "PASS_CODEX_USER_SKILLS_CHECK"), ("Plan", "PASS_CODEX_USER_SKILLS_PLAN")],
)
def test_read_only_actions_have_zero_side_effects(
    isolated: tuple[Path, Path], action: str, decision: str
) -> None:
    repo, codex_home = isolated
    assert not codex_home.exists()
    before_repo = safe_snapshot(repo)
    result, payload = run_manager(repo, codex_home, action)
    assert_run(result, payload, decision, 0)
    assert not codex_home.exists()
    assert safe_snapshot(repo) == before_repo
    assert payload["Rollback_Status"] == "NOT_REQUIRED"


def test_no_argument_action_defaults_to_zero_write_check(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    before_repo = safe_snapshot(repo)
    result, payload = run_manager(repo, codex_home, None)
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_CHECK", 0)
    assert payload["Action"] == "Check"
    assert payload["Target_Writability"] == "NOT_TESTED_NO_WRITE"
    assert not codex_home.exists()
    assert safe_snapshot(repo) == before_repo


@pytest.mark.parametrize("action", ["Apply", "Uninstall"])
def test_manager_lock_blocks_mutual_exclusion(isolated: tuple[Path, Path], action: str) -> None:
    repo, codex_home = isolated
    if action == "Uninstall":
        install(repo, codex_home)
    lock = codex_home / "skills" / LOCK_NAME
    write_text(lock, "held\n")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, action)
    assert_run(result, payload, "BLOCKED_CONCURRENT_OPERATION", 2)
    assert safe_snapshot(codex_home) == before


def test_stale_transaction_artifact_blocks_write(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    stale = codex_home / "skills" / ".ai-skill-hub-transaction-stale"
    write_text(stale / "journal.json", "{}\n")
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, "Apply")
    assert_run(result, payload, "BLOCKED_STALE_TRANSACTION_ARTIFACT", 2)
    assert safe_snapshot(codex_home) == before


def test_descriptor_path_traversal_is_blocked(tmp_path: Path) -> None:
    repo = build_repository(tmp_path)
    descriptor_path = repo / "tools" / DESCRIPTOR.name
    descriptor = json.loads(descriptor_path.read_text(encoding="utf-8"))
    descriptor["managed_entries"][0]["relative_source_path"] = "../outside"
    descriptor_path.write_text(json.dumps(descriptor, indent=2) + "\n", encoding="utf-8", newline="\n")
    commit_all(repo, "unsafe descriptor")
    result, payload = run_manager(repo, tmp_path / "codex-home", "Apply")
    assert_run(result, payload, "BLOCKED_CANONICAL_SOURCE_INVALID", 2)


@pytest.mark.parametrize("action", ["Apply", "Uninstall"])
def test_post_lock_state_change_blocks_before_mutation(isolated: tuple[Path, Path], action: str) -> None:
    repo, codex_home = isolated
    if action == "Uninstall":
        install(repo, codex_home)
    before = safe_snapshot(codex_home)
    result, payload = run_manager(repo, codex_home, action, injection="PostLockStateChange")
    assert_run(result, payload, "BLOCKED_POST_LOCK_STATE_CHANGED", 2)
    assert safe_snapshot(codex_home) == before


def test_json_and_text_decisions_match_and_arrays_remain_arrays(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    json_result, json_payload = run_manager(repo, codex_home, "Plan", output_format="Json")
    text_result, text_payload = run_manager(repo, codex_home, "Plan", output_format="Text")
    assert_run(json_result, json_payload, "PASS_CODEX_USER_SKILLS_PLAN", 0)
    assert_run(text_result, text_payload, "PASS_CODEX_USER_SKILLS_PLAN", 0)
    assert json_payload["Decision"] == text_payload["Decision"]
    assert isinstance(json_payload["Requested_Skills"], list)
    assert isinstance(json_payload["Planned_Actions"], list)


def test_utf8_without_bom_outputs(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    install(repo, codex_home)
    manifest_bytes = (codex_home / "skills" / MANIFEST_NAME).read_bytes()
    assert not manifest_bytes.startswith(b"\xef\xbb\xbf")
    manifest_bytes.decode("utf-8")
    for source_file in (SCRIPT, DESCRIPTOR):
        data = source_file.read_bytes()
        assert not data.startswith(b"\xef\xbb\xbf")
        data.decode("utf-8")


def test_rollback_failure_retains_same_root_evidence(isolated: tuple[Path, Path]) -> None:
    repo, codex_home = isolated
    result, payload = run_manager(
        repo,
        codex_home,
        "Apply",
        injection="ApplyAfterFirstMove,RollbackRestore",
    )
    assert_run(result, payload, "BLOCKED_ROLLBACK_FAILURE", 3)
    assert payload["Rollback_Status"] == "FAILED_EVIDENCE_RETAINED"
    artifacts = [
        path
        for path in (codex_home / "skills").iterdir()
        if path.name.startswith((".ai-skill-hub-backup-", ".ai-skill-hub-transaction-"))
    ]
    assert artifacts
    assert all(path.parent == codex_home / "skills" for path in artifacts)
    assert not (codex_home / "skills" / LOCK_NAME).exists()


@pytest.mark.parametrize("executable", [POWERSHELL, PWSH])
def test_supported_powershell_runtime_full_lifecycle(
    tmp_path: Path, executable: str | None
) -> None:
    if not executable:
        pytest.skip("Requested PowerShell runtime is unavailable")
    repo = build_repository(tmp_path)
    codex_home = tmp_path / "runtime-codex-home"
    for action, decision in (
        ("Check", "PASS_CODEX_USER_SKILLS_CHECK"),
        ("Plan", "PASS_CODEX_USER_SKILLS_PLAN"),
        ("Apply", "PASS_CODEX_USER_SKILLS_APPLY"),
        ("Apply", "NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT"),
        ("Uninstall", "PASS_CODEX_USER_SKILLS_UNINSTALL"),
    ):
        result, payload = run_manager(repo, codex_home, action, executable=executable)
        assert_run(result, payload, decision, 0)
    assert not (codex_home / "skills" / MANIFEST_NAME).exists()
    assert all(not (codex_home / "skills" / entry).exists() for entry in MANAGED)


def test_powershell_runtimes_share_manifest_and_upgrade_contract(tmp_path: Path) -> None:
    if not POWERSHELL or not PWSH:
        pytest.skip("Both Windows PowerShell and PowerShell 7 are required")
    repo = build_repository(tmp_path)
    codex_home = tmp_path / "cross-runtime-codex-home"

    result, payload = run_manager(repo, codex_home, "Apply", executable=POWERSHELL)
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_APPLY", 0)
    installed_at = read_manifest(codex_home)["installed_at"]

    result, payload = run_manager(repo, codex_home, "Check", executable=PWSH)
    assert_run(result, payload, "NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT", 0)

    write_text(repo / "skills" / "workflow-bootstrap" / "README.md", "cross-runtime update\n")
    commit_all(repo, "cross-runtime source update")
    result, payload = run_manager(repo, codex_home, "Apply", executable=PWSH)
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_APPLY", 0)
    assert read_manifest(codex_home)["installed_at"] == installed_at

    result, payload = run_manager(repo, codex_home, "Check", executable=POWERSHELL)
    assert_run(result, payload, "NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT", 0)
    result, payload = run_manager(repo, codex_home, "Uninstall", executable=POWERSHELL)
    assert_run(result, payload, "PASS_CODEX_USER_SKILLS_UNINSTALL", 0)
