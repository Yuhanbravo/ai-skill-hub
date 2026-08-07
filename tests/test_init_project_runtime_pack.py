from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
from copy import deepcopy
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "init_project_runtime_pack.ps1"
SCHEMA_PATH = ROOT / "tools" / "project_runtime_pack_schema_v1.json"
PWSH = shutil.which("pwsh") or shutil.which("pwsh.exe")
GIT = shutil.which("git")

pytestmark = pytest.mark.skipif(
    PWSH is None or GIT is None,
    reason="project runtime pack tests require pwsh and git",
)

EXPECTED_KEYS = [
    "Decision",
    "Project_Root",
    "Hub_Mode",
    "Hub_Path",
    "Hub_Url",
    "Requested_Ref",
    "Resolved_Commit",
    "Planned_Actions",
    "Changed_Count",
    "Index_Change",
    "Working_Tree_Change",
    "Rollback_Status",
    "Manifest_Status",
    "Message",
]

ADAPTER_PATHS = [
    "AGENTS.md",
    "CLAUDE.md",
    ".claude/skills/ai-skill-hub-router/SKILL.md",
    ".github/copilot-instructions.md",
    ".agents/skills/ai-skill-hub-router/SKILL.md",
]

ROUTER_ERROR_CODES = [
    "ROUTER_MANIFEST_INVALID",
    "ROUTER_HUB_NOT_MATERIALIZED",
    "ROUTER_HUB_VERSION_MISMATCH",
    "ROUTER_INDEX_MISSING",
    "ROUTER_NO_MATCH",
    "ROUTER_AMBIGUOUS_MATCH",
    "ROUTER_CANONICAL_PATH_INVALID",
    "ROUTER_SKILL_NOT_FOUND",
    "ROUTER_SUPPORTING_RESOURCE_MISSING",
]


def isolated_env(home: Path) -> dict[str, str]:
    home.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["HOME"] = str(home)
    env["USERPROFILE"] = str(home)
    env["GIT_CONFIG_NOSYSTEM"] = "1"
    env["GIT_TERMINAL_PROMPT"] = "0"
    env.pop("AI_SKILL_HUB_RUNTIME_PACK_TEST_FAIL_AT", None)
    env.pop("AI_SKILL_HUB_RUNTIME_PACK_TEST_TOUCH_REAL_INDEX", None)
    env.pop("AI_SKILL_HUB_RUNTIME_PACK_TEST_ROLLBACK_SKIP", None)
    return env


def git(repo: Path, *args: str, env: dict[str, str], check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [GIT, "-C", str(repo), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=env,
    )
    if check and result.returncode != 0:
        raise AssertionError(f"git {' '.join(args)} failed: {result.stdout} {result.stderr}")
    return result


def git_init(repo: Path, env: dict[str, str]) -> None:
    repo.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [GIT, "init", "-q", "-b", "main", str(repo)],
        capture_output=True,
        text=True,
        check=False,
        env=env,
    )
    if result.returncode != 0:
        raise AssertionError(f"git init failed: {result.stderr}")


def commit_all(repo: Path, message: str, env: dict[str, str]) -> str:
    git(repo, "add", ".", env=env)
    git(
        repo,
        "-c", "user.name=Runtime Pack Test",
        "-c", "user.email=runtime-pack-test@example.invalid",
        "commit", "-qm", message,
        env=env,
    )
    return git(repo, "rev-parse", "HEAD", env=env).stdout.strip()


def write_text(path: Path, text: str, newline: str = "\n") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline=newline)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def read_manifest(project: Path) -> dict:
    return json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))


def write_manifest(project: Path, manifest: dict) -> None:
    (project / ".ai" / "runtime-pack.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def legacy_manifest(project: Path) -> dict:
    manifest = read_manifest(project)
    for adapter in manifest["adapters"]:
        adapter.pop("hash_algorithm")
        adapter.pop("hash_normalization")
    write_manifest(project, manifest)
    return manifest


def without_adapter_hash_metadata(manifest: dict) -> dict:
    comparable = deepcopy(manifest)
    for adapter in comparable["adapters"]:
        adapter.pop("content_sha256", None)
        adapter.pop("hash_algorithm", None)
        adapter.pop("hash_normalization", None)
    return comparable


def snapshot_state(repo: Path, include_mtimes: bool = False) -> dict:
    worktree: list[tuple[str, str]] = []
    mtimes: dict[str, int] = {}
    for path in sorted(repo.rglob("*")):
        relative = path.relative_to(repo).as_posix()
        if relative == ".git" or relative.startswith(".git/"):
            continue
        if path.is_file():
            worktree.append((relative, sha256_file(path)))
            if include_mtimes:
                mtimes[relative] = path.stat().st_mtime_ns
        elif path.is_dir():
            worktree.append((relative, "<dir>"))
    index = repo / ".git" / "index"
    gitmodules = repo / ".gitmodules"
    config = repo / ".git" / "config"
    modules_root = repo / ".git" / "modules"
    modules: list[tuple[str, str]] = []
    if modules_root.is_dir():
        for path in sorted(modules_root.rglob("*")):
            relative = path.relative_to(modules_root).as_posix()
            if path.is_file():
                modules.append((relative, sha256_file(path)))
            elif path.is_dir():
                modules.append((relative, "<dir>"))
    status_env = isolated_env(repo.parent / (repo.name + "-snapshot-home"))
    status = subprocess.run(
        [GIT, "-C", str(repo), "status", "--porcelain=v2", "--untracked-files=all"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=status_env,
    ).stdout
    index_entries = subprocess.run(
        [GIT, "-C", str(repo), "ls-files", "-s"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=status_env,
    ).stdout
    state = {
        "worktree": tuple(worktree),
        "index": sha256_file(index) if index.is_file() else None,
        "index_entries": index_entries,
        "gitmodules": sha256_file(gitmodules) if gitmodules.is_file() else None,
        "config": sha256_file(config) if config.is_file() else None,
        "modules": tuple(modules),
        "status": status,
    }
    if include_mtimes:
        state["mtimes"] = mtimes
    return state


def parse_payload(result: subprocess.CompletedProcess[str]) -> tuple[list[str], dict[str, str]]:
    keys: list[str] = []
    payload: dict[str, str] = {}
    for line in result.stdout.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        keys.append(key)
        payload[key] = value
    return keys, payload


def run_init(
    project: Path,
    *args: str,
    home: Path | None = None,
    fail_at: str | None = None,
    touch_real_index: bool = False,
    rollback_skip: str | None = None,
    ceiling: Path | None = None,
) -> tuple[subprocess.CompletedProcess[str], list[str], dict[str, str]]:
    env = isolated_env(home or (project.parent / "fake-home"))
    # run_local_checks.ps1 redirects TEMP into the repository's own .tmp tree;
    # without a ceiling, fixture directories would resolve the hub repository as
    # their containing Git worktree.
    env["GIT_CEILING_DIRECTORIES"] = str(ceiling or project.parent)
    if fail_at:
        env["AI_SKILL_HUB_RUNTIME_PACK_TEST_FAIL_AT"] = fail_at
    if touch_real_index:
        env["AI_SKILL_HUB_RUNTIME_PACK_TEST_TOUCH_REAL_INDEX"] = "1"
    if rollback_skip:
        env["AI_SKILL_HUB_RUNTIME_PACK_TEST_ROLLBACK_SKIP"] = rollback_skip
    command = [
        PWSH,
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(SCRIPT),
        "-ProjectPath",
        str(project),
        *args,
    ]
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=env,
    )
    keys, payload = parse_payload(result)
    return result, keys, payload


def assert_decision(
    result: subprocess.CompletedProcess[str],
    keys: list[str],
    payload: dict[str, str],
    decision: str,
    exit_code: int,
) -> None:
    assert result.returncode == exit_code, (result.stdout, result.stderr)
    assert keys == EXPECTED_KEYS, (keys, result.stdout)
    assert payload["Decision"] == decision, (result.stdout, result.stderr)


@pytest.fixture(scope="session")
def session_env(tmp_path_factory: pytest.TempPathFactory) -> dict[str, str]:
    base = tmp_path_factory.mktemp("runtime-pack-session")
    return isolated_env(base / "home")


@pytest.fixture(scope="session")
def hub_remote(
    tmp_path_factory: pytest.TempPathFactory, session_env: dict[str, str]
) -> dict[str, object]:
    base = tmp_path_factory.mktemp("hub-remote")
    work = base / "hub-work"
    git_init(work, session_env)
    write_text(
        work / "SKILLS_INDEX.md",
        "# Skills Index\n\n"
        "| Skill | Category | Use scenario | Canonical path | Overview |\n"
        "| --- | --- | --- | --- | --- |\n"
        "| alpha-skill | workflow | bootstrap work | skills/alpha-skill/SKILL.md | Alpha workflow guidance |\n"
        "| beta-skill | review | audit work | skills/beta-skill/SKILL.md | Beta review guidance |\n",
    )
    write_text(
        work / "skills" / "alpha-skill" / "SKILL.md",
        '---\nname: alpha-skill\ndescription: "alpha fixture"\n---\n# Alpha\n',
    )
    write_text(
        work / "skills" / "beta-skill" / "SKILL.md",
        '---\nname: beta-skill\ndescription: "beta fixture"\n---\n# Beta\n',
    )
    first = commit_all(work, "hub fixture v1", session_env)
    git(work, "tag", "v1-light", env=session_env)
    git(
        work,
        "-c", "user.name=Runtime Pack Test",
        "-c", "user.email=runtime-pack-test@example.invalid",
        "tag", "-a", "v1-annot", "-m", "annotated fixture",
        env=session_env,
    )
    git(work, "branch", "dupe", env=session_env)
    git(work, "tag", "dupe", env=session_env)
    write_text(work / "SKILLS_INDEX.md", (work / "SKILLS_INDEX.md").read_text(encoding="utf-8") + "\n# v2\n")
    second = commit_all(work, "hub fixture v2", session_env)
    remote = base / "hub-remote.git"
    subprocess.run(
        [GIT, "clone", "-q", "--bare", str(work), str(remote)],
        check=True,
        capture_output=True,
        env=session_env,
    )
    git(work, "push", "-q", str(remote), "refs/heads/main:refs/heads/main", env=session_env)
    git(work, "push", "-q", str(remote), "refs/heads/dupe:refs/heads/dupe", env=session_env)
    git(work, "push", "-q", str(remote), "refs/tags/v1-light:refs/tags/v1-light", env=session_env)
    git(work, "push", "-q", str(remote), "refs/tags/v1-annot:refs/tags/v1-annot", env=session_env)
    git(work, "push", "-q", str(remote), "refs/tags/dupe:refs/tags/dupe", env=session_env)
    return {
        "path": remote,
        "url": remote.as_uri(),
        "first_commit": first,
        "main_commit": second,
    }


@pytest.fixture(scope="session")
def hub_remote_noindex(
    tmp_path_factory: pytest.TempPathFactory, session_env: dict[str, str]
) -> dict[str, object]:
    base = tmp_path_factory.mktemp("hub-noindex")
    work = base / "hub-work-noindex"
    git_init(work, session_env)
    write_text(work / "README.md", "# hub without canonical index\n")
    commit_all(work, "noindex fixture", session_env)
    remote = base / "hub-noindex.git"
    subprocess.run(
        [GIT, "clone", "-q", "--bare", str(work), str(remote)],
        check=True,
        capture_output=True,
        env=session_env,
    )
    return {"path": remote, "url": remote.as_uri()}


@pytest.fixture()
def project(tmp_path: Path, session_env: dict[str, str]) -> Path:
    repo = tmp_path / "project"
    git_init(repo, session_env)
    write_text(repo / "README.md", "# fixture project\n")
    commit_all(repo, "project fixture", session_env)
    return repo


def staged_paths(repo: Path, env_home: Path) -> list[str]:
    result = subprocess.run(
        [GIT, "-C", str(repo), "diff", "--cached", "--name-only"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=True,
        env=isolated_env(env_home),
    )
    return sorted(line for line in result.stdout.splitlines() if line)


# ---------------------------------------------------------------------------
# 1-3: first init, idempotent reruns
# ---------------------------------------------------------------------------


def test_first_init_blank_repo(project: Path, hub_remote: dict[str, object]) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-HubRef", "main")
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert payload["Resolved_Commit"] == hub_remote["main_commit"]
    assert payload["Index_Change"] == "YES"
    assert payload["Working_Tree_Change"] == "YES"
    assert payload["Manifest_Status"] == "VALID"
    assert int(payload["Changed_Count"]) == 8
    for relative in ADAPTER_PATHS + [".ai/runtime-pack.json", ".gitmodules"]:
        assert (project / relative).is_file(), relative
    staged = staged_paths(project, project.parent / "fake-home")
    assert staged == sorted(ADAPTER_PATHS + [".ai/runtime-pack.json", ".gitmodules", ".ai/ai-skill-hub"])
    gitlink = git(project, "ls-files", "-s", "--", ".ai/ai-skill-hub", env=isolated_env(project.parent / "fake-home")).stdout
    assert gitlink.startswith(f"160000 {hub_remote['main_commit']}")
    head = git(project / ".ai" / "ai-skill-hub", "rev-parse", "HEAD", env=isolated_env(project.parent / "fake-home")).stdout.strip()
    assert head == hub_remote["main_commit"]
    manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    assert manifest["hub"]["resolved_commit"] == hub_remote["main_commit"]
    assert [adapter["id"] for adapter in manifest["adapters"]] == [
        "agents-entry",
        "claude-entry",
        "claude-router",
        "copilot-entry",
        "shared-router",
    ]
    raw_manifest = (project / ".ai" / "runtime-pack.json").read_bytes()
    assert raw_manifest.startswith(b'{\n  "schema_version": 1,')
    assert raw_manifest.endswith(b"}\n")
    assert b"\r" not in raw_manifest
    assert not raw_manifest.startswith(b"\xef\xbb\xbf")
    assert "non-portable" in result.stderr


def test_immediate_staged_rerun_no_change(project: Path, hub_remote: dict[str, object]) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    before = snapshot_state(project, include_mtimes=True)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)
    assert payload["Changed_Count"] == "0"
    assert payload["Index_Change"] == "NO"
    after = snapshot_state(project, include_mtimes=True)
    assert before == after


def test_committed_rerun_no_change(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    before = snapshot_state(project, include_mtimes=True)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)
    after = snapshot_state(project, include_mtimes=True)
    assert before == after
    assert staged_paths(project, project.parent / "fake-home") == []


@pytest.mark.parametrize("newline", ["\n", "\r\n", "\r"])
def test_normalized_hash_accepts_equivalent_router_newlines(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str], newline: str
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    router = project / ".agents" / "skills" / "ai-skill-hub-router" / "SKILL.md"
    router.write_bytes(router.read_text(encoding="utf-8").replace("\n", newline).encode("utf-8"))
    diff = git(project, "diff", "--quiet", env=session_env, check=False)
    if diff.returncode == 1:
        commit_all(project, "equivalent router line endings", session_env)
    elif diff.returncode != 0:
        raise AssertionError(f"git diff --quiet failed: {diff.stdout} {diff.stderr}")
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)


def test_crlf_fresh_clone_rerun_no_change(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    clone = project.parent / "autocrlf-fresh-clone"
    subprocess.run(
        [GIT, "-c", "core.autocrlf=true", "clone", "-q", "--no-local", str(project), str(clone)],
        check=True, capture_output=True, env=session_env,
    )
    git(clone, "config", "core.autocrlf", "true", env=session_env)
    git(clone, "-c", "protocol.file.allow=always", "submodule", "update", "--init", env=session_env)
    assert git(clone, "status", "--porcelain", env=session_env).stdout == ""
    assert git(clone / ".ai" / "ai-skill-hub", "status", "--porcelain", env=session_env).stdout == ""
    result, keys, payload = run_init(clone, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)
    assert git(clone, "status", "--porcelain", env=session_env).stdout == ""


def test_legacy_manifest_crlf_fresh_clone_migrates_and_is_idempotent(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    legacy = legacy_manifest(project)
    commit_all(project, "legacy manifest", session_env)

    clone = project.parent / "legacy-autocrlf-fresh-clone"
    subprocess.run(
        [
            GIT,
            "-c",
            "core.autocrlf=true",
            "clone",
            "-q",
            "--no-local",
            str(project),
            str(clone),
        ],
        check=True,
        capture_output=True,
        env=session_env,
    )
    git(clone, "config", "core.autocrlf", "true", env=session_env)
    git(
        clone,
        "-c",
        "protocol.file.allow=always",
        "submodule",
        "update",
        "--init",
        env=session_env,
    )
    assert git(clone, "status", "--porcelain", env=session_env).stdout == ""
    assert git(
        clone / ".ai" / "ai-skill-hub", "status", "--porcelain", env=session_env
    ).stdout == ""
    assert staged_paths(clone, clone.parent / "fresh-clone-home") == []

    result, keys, payload = run_init(clone)
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    migrated = read_manifest(clone)
    assert migrated["hub"] == legacy["hub"]
    assert without_adapter_hash_metadata(migrated) == without_adapter_hash_metadata(
        legacy
    )
    assert {adapter["hash_algorithm"] for adapter in migrated["adapters"]} == {
        "sha256"
    }
    assert {
        adapter["hash_normalization"] for adapter in migrated["adapters"]
    } == {"utf8-lf-v1"}
    assert staged_paths(clone, clone.parent / "fresh-clone-home") == [
        ".ai/runtime-pack.json"
    ]

    commit_all(clone, "migrate hash metadata", session_env)
    assert git(clone, "status", "--porcelain", env=session_env).stdout == ""
    assert git(
        clone / ".ai" / "ai-skill-hub", "status", "--porcelain", env=session_env
    ).stdout == ""
    assert staged_paths(clone, clone.parent / "fresh-clone-home") == []
    rerun, keys, payload = run_init(clone)
    assert_decision(rerun, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)
    assert git(clone, "status", "--porcelain", env=session_env).stdout == ""


def test_legacy_manifest_migrates_only_hash_metadata_when_logical_content_matches(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    manifest = legacy_manifest(project)
    commit_all(project, "legacy manifest", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert "migrate-hash-normalization:.ai/runtime-pack.json" in payload["Planned_Actions"]
    upgraded = read_manifest(project)
    assert without_adapter_hash_metadata(upgraded) == without_adapter_hash_metadata(manifest)
    assert {adapter["hash_algorithm"] for adapter in upgraded["adapters"]} == {"sha256"}
    assert {adapter["hash_normalization"] for adapter in upgraded["adapters"]} == {"utf8-lf-v1"}
    commit_all(project, "migrate hash semantics", session_env)
    rerun, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(rerun, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)


def test_manifest_migration_preserves_non_default_requested_ref(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(
        project, "-HubUrl", str(hub_remote["url"]), "-HubRef", "v1-light"
    )
    before = legacy_manifest(project)
    commit_all(project, "legacy non-default ref manifest", session_env)

    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    after = read_manifest(project)
    assert before["hub"]["requested_ref"] == "v1-light"
    assert after["hub"]["requested_ref"] == before["hub"]["requested_ref"]
    commit_all(project, "migrate non-default ref manifest", session_env)
    rerun, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(rerun, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)


def test_manifest_migration_preserves_explicit_hub_url_when_omitted_on_rerun(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    explicit_url = str(hub_remote["url"])
    run_init(project, "-HubUrl", explicit_url)
    before = legacy_manifest(project)
    commit_all(project, "legacy explicit URL manifest", session_env)

    result, keys, payload = run_init(project)
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    after = read_manifest(project)
    assert before["hub"]["url"] == explicit_url
    assert after["hub"]["url"] == before["hub"]["url"]
    assert payload["Hub_Url"] == before["hub"]["url"]
    commit_all(project, "migrate explicit URL manifest", session_env)
    rerun, keys, payload = run_init(project)
    assert_decision(rerun, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)


def test_normalization_actual_content_tamper_fails_closed(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    router = project / ".agents" / "skills" / "ai-skill-hub-router" / "SKILL.md"
    router.write_text(router.read_text(encoding="utf-8").replace("read-only", "write-only", 1), encoding="utf-8", newline="\n")
    commit_all(project, "tamper router", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_MANAGED_CONTENT_MODIFIED", 2)


# ---------------------------------------------------------------------------
# 4: DryRun
# ---------------------------------------------------------------------------


def test_dryrun_zero_mutation(project: Path, hub_remote: dict[str, object]) -> None:
    before = snapshot_state(project, include_mtimes=True)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-DryRun")
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_DRY_RUN", 0)
    assert payload["Index_Change"] == "NO"
    assert payload["Working_Tree_Change"] == "NO"
    assert payload["Rollback_Status"] == "NOT_REQUIRED"
    assert payload["Manifest_Status"] == "ABSENT"
    assert payload["Resolved_Commit"] == hub_remote["main_commit"]
    assert payload["Message"] == "DryRun completed with zero repository mutation."
    assert "submodule-add" in payload["Planned_Actions"]
    after = snapshot_state(project, include_mtimes=True)
    assert before == after


def test_dryrun_reports_preflight_conflict(project: Path, hub_remote: dict[str, object]) -> None:
    write_text(project / "dirty.md", "dirty\n")
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-DryRun")
    assert_decision(result, keys, payload, "BLOCKED_DIRTY_WORKTREE", 2)


# ---------------------------------------------------------------------------
# 5-9: existing file protection
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("variant", ["lf", "crlf", "bom"])
def test_existing_human_content_byte_preservation(
    project: Path, hub_remote: dict[str, object], variant: str
) -> None:
    originals: dict[str, bytes] = {}
    for relative in ("AGENTS.md", "CLAUDE.md", ".github/copilot-instructions.md"):
        target = project / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if variant == "lf":
            content = b"# human entry\n\nHuman guidance line.\n"
        elif variant == "crlf":
            content = b"# human entry\r\n\r\nHuman guidance line.\r\n"
        else:
            content = b"\xef\xbb\xbf# human entry\n\nHuman guidance line.\n"
        target.write_bytes(content)
        originals[relative] = content
    git_add_and_commit = commit_all(project, "human entries", isolated_env(project.parent / "fake-home"))
    assert git_add_and_commit
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    hashes = {adapter["path"]: adapter["content_sha256"] for adapter in manifest["adapters"]}
    for relative, original in originals.items():
        data = (project / relative).read_bytes()
        assert data.startswith(original), relative
        appended = data[len(original):]
        assert appended.startswith(b"<!-- ai-skill-hub:runtime-pack:start schema=v1 -->")
        assert appended.rstrip(b"\r\n").endswith(b"<!-- ai-skill-hub:runtime-pack:end -->")
        canonical = appended.replace(b"\r\n", b"\n")
        assert sha256_bytes(canonical) == hashes[relative]


def test_existing_file_policy_fail(project: Path, hub_remote: dict[str, object]) -> None:
    target = project / "AGENTS.md"
    target.write_bytes(b"# keep me\n")
    commit_all(project, "human entry", isolated_env(project.parent / "fake-home"))
    before = target.read_bytes()
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), "-ExistingFilePolicy", "Fail"
    )
    assert_decision(result, keys, payload, "BLOCKED_EXISTING_FILE", 2)
    assert target.read_bytes() == before


def test_normalization_managed_block_internal_tamper_fails_closed(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    agents = project / "AGENTS.md"
    text = agents.read_text(encoding="utf-8")
    agents.write_text(text.replace("Keep this entry thin.", "Keep this entry thick."), encoding="utf-8", newline="\n")
    commit_all(project, "human edit inside managed block", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_MANAGED_CONTENT_MODIFIED", 2)


def test_normalization_managed_block_external_content_is_preserved(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    agents = project / "AGENTS.md"
    outside = "# Human-owned preface\n\n"
    agents.write_text(
        outside + agents.read_text(encoding="utf-8"),
        encoding="utf-8",
        newline="\n",
    )
    commit_all(project, "edit outside managed block", session_env)

    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)
    assert agents.read_text(encoding="utf-8").startswith(outside)


@pytest.mark.parametrize(
    "marker_text",
    [
        "duplicate",
        "nested",
        "orphan",
        "reversed",
        "schema-v2",
    ],
)
def test_invalid_marker_structures(
    project: Path, hub_remote: dict[str, object], marker_text: str, session_env: dict[str, str]
) -> None:
    start = "<!-- ai-skill-hub:runtime-pack:start schema=v1 -->"
    end = "<!-- ai-skill-hub:runtime-pack:end -->"
    bodies = {
        "duplicate": f"{start}\na\n{end}\n{start}\nb\n{end}\n",
        "nested": f"{start}\n{start}\na\n{end}\n{end}\n",
        "orphan": f"# title\n{end}\n",
        "reversed": f"{end}\na\n{start}\n",
        "schema-v2": "<!-- ai-skill-hub:runtime-pack:start schema=v2 -->\na\n" + end + "\n",
    }
    write_text(project / "AGENTS.md", bodies[marker_text])
    commit_all(project, "bad markers", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_MANAGED_BLOCK_INVALID", 2)


def test_valid_block_without_manifest_is_unknown_provenance(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    run_init(project, "-HubUrl", str(hub_remote["url"]))
    commit_all(project, "add runtime pack", session_env)
    (project / ".ai" / "runtime-pack.json").unlink()
    git(project, "add", "-A", env=session_env)
    git(
        project,
        "-c", "user.name=Runtime Pack Test",
        "-c", "user.email=runtime-pack-test@example.invalid",
        "commit", "-qm", "drop manifest",
        env=session_env,
    )
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_UNKNOWN_MANAGED_BLOCK_PROVENANCE", 2)


@pytest.mark.parametrize("kind", ["invalid-utf8", "mixed-newline"])
def test_text_format_unsupported(
    project: Path, hub_remote: dict[str, object], kind: str, session_env: dict[str, str]
) -> None:
    target = project / "AGENTS.md"
    if kind == "invalid-utf8":
        target.write_bytes(b"# title\n\xff\xfe invalid\n")
    else:
        target.write_bytes(b"# title\r\nmixed\nline\r\n")
    commit_all(project, "bad encoding", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_TEXT_FORMAT_UNSUPPORTED", 2)


# ---------------------------------------------------------------------------
# 10-13: repository, operation, dirty and path preconditions
# ---------------------------------------------------------------------------


def test_non_git_directory(tmp_path: Path, hub_remote: dict[str, object]) -> None:
    plain = tmp_path / "plain"
    plain.mkdir()
    result, keys, payload = run_init(plain, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_NOT_GIT_REPOSITORY", 2)


def test_subdirectory_is_not_root(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    sub = project / "docs" / "nested"
    sub.mkdir(parents=True)
    result, keys, payload = run_init(sub, "-HubUrl", str(hub_remote["url"]), ceiling=project.parent)
    assert_decision(result, keys, payload, "BLOCKED_PROJECT_NOT_ROOT", 2)


def test_bare_repo_is_blocked(tmp_path: Path, hub_remote: dict[str, object], session_env: dict[str, str]) -> None:
    bare = tmp_path / "bare.git"
    subprocess.run(
        [GIT, "init", "-q", "--bare", str(bare)],
        check=True,
        capture_output=True,
        env=session_env,
    )
    result, keys, payload = run_init(bare, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_NOT_GIT_REPOSITORY", 2)


@pytest.mark.parametrize("operation", ["merge", "rebase", "index-lock"])
def test_git_operation_active(
    project: Path, hub_remote: dict[str, object], operation: str
) -> None:
    git_dir = project / ".git"
    if operation == "merge":
        (git_dir / "MERGE_HEAD").write_text("0" * 40 + "\n", encoding="ascii")
    elif operation == "rebase":
        (git_dir / "rebase-merge").mkdir()
    else:
        (git_dir / "index.lock").write_bytes(b"")
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_GIT_OPERATION_ACTIVE", 2)


def test_dirty_worktree_blocked(project: Path, hub_remote: dict[str, object]) -> None:
    (project / "README.md").write_text("dirty\n", encoding="utf-8")
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_DIRTY_WORKTREE", 2)


def test_untracked_blocked(project: Path, hub_remote: dict[str, object]) -> None:
    write_text(project / "untracked.md", "untracked\n")
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_DIRTY_WORKTREE", 2)


def test_unrelated_staged_blocked(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    write_text(project / "staged.md", "staged\n")
    git(project, "add", "staged.md", env=session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_STAGED_CHANGES", 2)


@pytest.mark.parametrize("occupant", ["file", "directory", "nested-repo", "junction"])
def test_hub_path_occupied(
    project: Path,
    hub_remote: dict[str, object],
    occupant: str,
    session_env: dict[str, str],
) -> None:
    hub_path = project / ".ai" / "ai-skill-hub"
    hub_path.parent.mkdir(parents=True, exist_ok=True)
    if occupant == "file":
        hub_path.write_text("occupied\n", encoding="utf-8")
        commit_all(project, "occupant file", session_env)
        expected = "BLOCKED_HUB_PATH_CONFLICT"
    elif occupant == "directory":
        hub_path.mkdir()
        write_text(hub_path / "placeholder.txt", "occupied\n")
        commit_all(project, "occupant directory", session_env)
        expected = "BLOCKED_HUB_PATH_CONFLICT"
    elif occupant == "nested-repo":
        git_init(hub_path, session_env)
        write_text(hub_path / "nested.md", "nested\n")
        commit_all(hub_path, "nested repo", session_env)
        git(project, "add", "-A", env=session_env)
        git(
            project,
            "-c", "user.name=Runtime Pack Test",
            "-c", "user.email=runtime-pack-test@example.invalid",
            "commit", "-qm", "register nested gitlink",
            env=session_env,
        )
        expected = "BLOCKED_HUB_PATH_CONFLICT"
    else:
        outside = project.parent / "junction-target"
        outside.mkdir(exist_ok=True)
        junction = subprocess.run(
            ["cmd.exe", "/d", "/c", "mklink", "/J", str(hub_path), str(outside)],
            capture_output=True,
            text=True,
            check=False,
        )
        if junction.returncode != 0:
            pytest.skip(f"junction creation unavailable: {junction.stdout} {junction.stderr}")
        expected = "BLOCKED_PATH_SAFETY_VIOLATION"
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, expected, 2)


@pytest.mark.parametrize(
    "hub_path",
    [
        "..\\escape",
        "absolute-will-fail",
        ".git\\inside",
        "CON",
    ],
)
def test_hub_path_safety(
    project: Path, hub_remote: dict[str, object], hub_path: str
) -> None:
    if hub_path == "absolute-will-fail":
        hub_path = str(project / "abs")
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), "-HubPath", hub_path
    )
    assert_decision(result, keys, payload, "BLOCKED_PATH_SAFETY_VIOLATION", 2)


# ---------------------------------------------------------------------------
# 14-15: existing submodule adoption and conflicts
# ---------------------------------------------------------------------------


def add_existing_submodule(
    project: Path,
    url: str,
    commit: str,
    env: dict[str, str],
) -> None:
    git(
        project,
        "-c", "protocol.file.allow=always",
        "submodule", "add", "--name", "ai-skill-hub", "--", url, ".ai/ai-skill-hub",
        env=env,
    )
    git(project / ".ai" / "ai-skill-hub", "checkout", "-q", "--detach", commit, env=env)
    git(project, "add", ".gitmodules", ".ai/ai-skill-hub", env=env)
    git(
        project,
        "-c", "user.name=Runtime Pack Test",
        "-c", "user.email=runtime-pack-test@example.invalid",
        "commit", "-qm", "add existing submodule",
        env=env,
    )


def test_existing_exact_submodule_reuse(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    add_existing_submodule(project, str(hub_remote["url"]), str(hub_remote["main_commit"]), session_env)
    gitlink_before = git(project, "ls-files", "-s", "--", ".ai/ai-skill-hub", env=session_env).stdout
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-HubRef", "main")
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert "submodule-reuse" in payload["Planned_Actions"]
    gitlink_after = git(project, "ls-files", "-s", "--", ".ai/ai-skill-hub", env=session_env).stdout
    assert gitlink_before == gitlink_after
    staged = staged_paths(project, project.parent / "fake-home")
    assert staged == sorted(ADAPTER_PATHS + [".ai/runtime-pack.json"])


def test_uninitialized_submodule_materialize(
    tmp_path: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    source = tmp_path / "source-project"
    git_init(source, session_env)
    write_text(source / "README.md", "# source\n")
    commit_all(source, "source fixture", session_env)
    result, keys, payload = run_init(source, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    commit_all(source, "add runtime pack", session_env)
    clone = tmp_path / "clone-project"
    subprocess.run(
        [GIT, "clone", "-q", str(source), str(clone)],
        check=True,
        capture_output=True,
        env=session_env,
    )
    assert not (clone / ".ai" / "ai-skill-hub" / "SKILLS_INDEX.md").is_file()
    result, keys, payload = run_init(clone, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert "submodule-materialize" in payload["Planned_Actions"]
    head = git(clone / ".ai" / "ai-skill-hub", "rev-parse", "HEAD", env=session_env).stdout.strip()
    assert head == hub_remote["main_commit"]
    assert (clone / ".ai" / "ai-skill-hub" / "SKILLS_INDEX.md").is_file()
    rerun, keys, payload = run_init(clone, "-HubUrl", str(hub_remote["url"]))
    assert_decision(rerun, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)


def test_submodule_different_url_conflict(
    project: Path,
    hub_remote: dict[str, object],
    hub_remote_noindex: dict[str, object],
    session_env: dict[str, str],
) -> None:
    add_existing_submodule(project, str(hub_remote_noindex["url"]), git(hub_remote_noindex["path"], "rev-parse", "main", env=session_env).stdout.strip(), session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_SUBMODULE_CONFLICT", 2)


def test_submodule_different_commit_requires_upgrade(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    add_existing_submodule(project, str(hub_remote["url"]), str(hub_remote["first_commit"]), session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-HubRef", "main")
    assert_decision(result, keys, payload, "BLOCKED_UPGRADE_REQUIRED", 2)


# ---------------------------------------------------------------------------
# 16-17: HubRef resolution
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("ref", "commit_key"),
    [
        ("main", "main_commit"),
        ("refs/heads/main", "main_commit"),
        ("v1-light", "first_commit"),
        ("refs/tags/v1-light", "first_commit"),
        ("v1-annot", "first_commit"),
    ],
)
def test_hubref_resolution(
    project: Path, hub_remote: dict[str, object], ref: str, commit_key: str
) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-HubRef", ref)
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert payload["Resolved_Commit"] == hub_remote[commit_key]
    assert payload["Requested_Ref"] == ref


def test_hubref_full_commit_resolution(project: Path, hub_remote: dict[str, object]) -> None:
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), "-HubRef", str(hub_remote["first_commit"]).upper()
    )
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert payload["Resolved_Commit"] == hub_remote["first_commit"]


def test_hubref_ambiguous(project: Path, hub_remote: dict[str, object]) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-HubRef", "dupe")
    assert_decision(result, keys, payload, "BLOCKED_REF_AMBIGUOUS", 2)


def test_hubref_not_found(project: Path, hub_remote: dict[str, object]) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-HubRef", "no-such-ref")
    assert_decision(result, keys, payload, "BLOCKED_REF_NOT_FOUND", 2)


@pytest.mark.parametrize("ref", ["819e60", "HEAD", "main~1", "v1^{}", ""])
def test_hubref_invalid(project: Path, hub_remote: dict[str, object], ref: str) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), "-HubRef", ref)
    assert_decision(result, keys, payload, "BLOCKED_REF_INVALID", 2)


# ---------------------------------------------------------------------------
# 18-20: manifest validation, authority mismatch, canonical index
# ---------------------------------------------------------------------------


def init_and_commit(project: Path, hub_remote: dict[str, object], env: dict[str, str]) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    commit_all(project, "add runtime pack", env)


def rewrite_manifest(project: Path, mutate) -> None:
    path = project / ".ai" / "runtime-pack.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    mutate(manifest)
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


@pytest.mark.parametrize(
    ("mutation", "decision"),
    [
        ("unknown-field", "BLOCKED_MANIFEST_UNKNOWN_FIELD"),
        ("unknown-nested-field", "BLOCKED_MANIFEST_UNKNOWN_FIELD"),
        ("schema-version", "BLOCKED_SCHEMA_INCOMPATIBLE"),
        ("schema-type", "BLOCKED_SCHEMA_INCOMPATIBLE"),
        ("adapter-set", "BLOCKED_MANIFEST_INVALID"),
        ("mode-value", "BLOCKED_MANIFEST_INVALID"),
    ],
)
def test_manifest_validation_failures(
    project: Path,
    hub_remote: dict[str, object],
    session_env: dict[str, str],
    mutation: str,
    decision: str,
) -> None:
    init_and_commit(project, hub_remote, session_env)

    def mutate(manifest: dict) -> None:
        if mutation == "unknown-field":
            manifest["extra"] = True
        elif mutation == "unknown-nested-field":
            manifest["adapters"][0]["extra"] = True
        elif mutation == "schema-version":
            manifest["schema_version"] = 2
        elif mutation == "schema-type":
            manifest["schema_version"] = "1"
        elif mutation == "adapter-set":
            manifest["adapters"] = manifest["adapters"][:-1]
        elif mutation == "mode-value":
            manifest["hub"]["mode"] = "Submodule"

    rewrite_manifest(project, mutate)
    commit_all(project, f"corrupt manifest {mutation}", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, decision, 2)
    assert payload["Manifest_Status"] == "INVALID"


@pytest.mark.parametrize(
    "retained_field",
    ["hash_algorithm", "hash_normalization"],
    ids=["hash-algorithm-only", "hash-normalization-only"],
)
def test_partial_manifest_hash_metadata_is_rejected_without_mutation(
    project: Path,
    hub_remote: dict[str, object],
    session_env: dict[str, str],
    retained_field: str,
) -> None:
    init_and_commit(project, hub_remote, session_env)
    manifest = read_manifest(project)
    removed_field = (
        "hash_normalization"
        if retained_field == "hash_algorithm"
        else "hash_algorithm"
    )
    for adapter in manifest["adapters"]:
        adapter.pop(removed_field)
    write_manifest(project, manifest)
    commit_all(project, f"retain only {retained_field}", session_env)
    manifest_bytes_before = (project / ".ai" / "runtime-pack.json").read_bytes()
    state_before = snapshot_state(project, include_mtimes=True)

    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_MANIFEST_INVALID", 2)
    assert payload["Working_Tree_Change"] == "NO"
    assert payload["Index_Change"] == "NO"
    assert (project / ".ai" / "runtime-pack.json").read_bytes() == manifest_bytes_before
    assert snapshot_state(project, include_mtimes=True) == state_before


def test_manifest_key_order_failure(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    init_and_commit(project, hub_remote, session_env)
    path = project / ".ai" / "runtime-pack.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    reordered = {
        "generator": manifest["generator"],
        "schema_version": manifest["schema_version"],
        "hub": manifest["hub"],
        "routing": manifest["routing"],
        "adapters": manifest["adapters"],
    }
    path.write_text(json.dumps(reordered, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    commit_all(project, "reorder manifest keys", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_MANIFEST_INVALID", 2)


def test_manifest_gitlink_mismatch(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    init_and_commit(project, hub_remote, session_env)
    hub_checkout = project / ".ai" / "ai-skill-hub"
    git(hub_checkout, "checkout", "-q", "--detach", str(hub_remote["first_commit"]), env=session_env)
    git(project, "add", ".ai/ai-skill-hub", env=session_env)
    git(
        project,
        "-c", "user.name=Runtime Pack Test",
        "-c", "user.email=runtime-pack-test@example.invalid",
        "commit", "-qm", "move gitlink",
        env=session_env,
    )
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "BLOCKED_RUNTIME_PACK_MISMATCH", 2)


def test_manifest_commit_pin_regression_requested_commit_requires_upgrade(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    init_and_commit(project, hub_remote, session_env)
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), "-HubRef", str(hub_remote["first_commit"])
    )
    assert_decision(result, keys, payload, "BLOCKED_UPGRADE_REQUIRED", 2)


def test_canonical_index_missing(
    project: Path, hub_remote_noindex: dict[str, object]
) -> None:
    before = snapshot_state(project)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote_noindex["url"]))
    assert_decision(result, keys, payload, "BLOCKED_CANONICAL_INDEX_MISSING", 2)
    assert snapshot_state(project) == before


# ---------------------------------------------------------------------------
# 21: router fixture semantics (pure Python reference implementation)
# ---------------------------------------------------------------------------


def parse_index(index_path: Path) -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    for line in index_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line.startswith("|") or "---" in line or "Canonical path" in line:
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) != 5:
            continue
        entries.append(
            {
                "name": cells[0],
                "category": cells[1],
                "scenario": cells[2],
                "path": cells[3],
                "overview": cells[4],
            }
        )
    return entries


def reference_router(project: Path, query: str | None = None, named: str | None = None) -> tuple[str, Path | None]:
    manifest_path = project / ".ai" / "runtime-pack.json"
    if not manifest_path.is_file():
        return "ROUTER_MANIFEST_INVALID", None
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    hub = project / manifest["hub"]["path"]
    index_path = hub / "SKILLS_INDEX.md"
    if not index_path.is_file():
        return "ROUTER_INDEX_MISSING", None
    entries = parse_index(index_path)
    if named is not None:
        selected = [entry for entry in entries if entry["name"] == named]
        if not selected:
            return "ROUTER_NO_MATCH", None
    else:
        selected = [
            entry
            for entry in entries
            if query
            and query.lower()
            in (entry["overview"] + " " + entry["category"] + " " + entry["scenario"] + " " + entry["name"]).lower()
        ]
        if not selected:
            return "ROUTER_NO_MATCH", None
        if len(selected) > 1:
            return "ROUTER_AMBIGUOUS_MATCH", None
    entry = selected[0]
    candidate = (hub / entry["path"]).resolve()
    expected_dir = (hub / "skills" / entry["name"]).resolve()
    if candidate != expected_dir / "SKILL.md":
        return "ROUTER_CANONICAL_PATH_INVALID", None
    if not candidate.is_file():
        return "ROUTER_SKILL_NOT_FOUND", None
    return "OK", candidate


def build_router_fixture(root: Path) -> Path:
    project = root / "router-project"
    hub = project / ".ai" / "ai-skill-hub"
    write_text(
        hub / "SKILLS_INDEX.md",
        "# Skills Index\n\n"
        "| Skill | Category | Use scenario | Canonical path | Overview |\n"
        "| --- | --- | --- | --- | --- |\n"
        "| alpha-skill | workflow | bootstrap work | skills/alpha-skill/SKILL.md | Unique alpha workflow guidance |\n"
        "| beta-skill | review | audit work | skills/beta-skill/SKILL.md | Generic shared guidance |\n"
        "| gamma-skill | review | audit work | skills/gamma-skill/SKILL.md | Generic shared guidance |\n"
        "| ghost-skill | ops | missing target | skills/ghost-skill/SKILL.md | Ghost ops guidance |\n"
        "| escape-skill | ops | escape | ../outside/SKILL.md | Escape guidance |\n",
    )
    for name in ("alpha-skill", "beta-skill", "gamma-skill"):
        write_text(hub / "skills" / name / "SKILL.md", f"# {name}\n")
    manifest = {
        "schema_version": 1,
        "generator": {"id": "ai-skill-hub.project-runtime-pack", "version": 1},
        "hub": {
            "mode": "submodule",
            "path": ".ai/ai-skill-hub",
            "url": "file:///fixture",
            "requested_ref": "main",
            "resolved_commit": "0" * 40,
        },
        "routing": {"strategy": "thin-router", "canonical_index": ".ai/ai-skill-hub/SKILLS_INDEX.md"},
        "adapters": [],
    }
    write_text(project / ".ai" / "runtime-pack.json", json.dumps(manifest, indent=2) + "\n")
    return project


def test_router_exact_name_selection(tmp_path: Path) -> None:
    project = build_router_fixture(tmp_path)
    code, selected = reference_router(project, named="alpha-skill")
    assert code == "OK"
    assert selected is not None
    assert selected.read_text(encoding="utf-8") == "# alpha-skill\n"


def test_router_no_match(tmp_path: Path) -> None:
    project = build_router_fixture(tmp_path)
    assert reference_router(project, named="not-in-index")[0] == "ROUTER_NO_MATCH"
    assert reference_router(project, query="unmatched unique topic zzz")[0] == "ROUTER_NO_MATCH"


def test_router_ambiguous_match(tmp_path: Path) -> None:
    project = build_router_fixture(tmp_path)
    assert reference_router(project, query="generic shared guidance")[0] == "ROUTER_AMBIGUOUS_MATCH"


def test_router_skill_not_found(tmp_path: Path) -> None:
    project = build_router_fixture(tmp_path)
    assert reference_router(project, named="ghost-skill")[0] == "ROUTER_SKILL_NOT_FOUND"


def test_router_path_escape(tmp_path: Path) -> None:
    project = build_router_fixture(tmp_path)
    assert reference_router(project, named="escape-skill")[0] == "ROUTER_CANONICAL_PATH_INVALID"


def test_generated_router_files_exact(project: Path, hub_remote: dict[str, object]) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    shared = (project / ".agents/skills/ai-skill-hub-router/SKILL.md").read_bytes()
    claude = (project / ".claude/skills/ai-skill-hub-router/SKILL.md").read_bytes()
    assert shared == claude
    assert shared.startswith(b"---\nname: ai-skill-hub-router\n")
    assert b"\r" not in shared
    assert shared.endswith(b"\n") and not shared.endswith(b"\n\n")
    text = shared.decode("utf-8")
    assert "`../../../.ai/runtime-pack.json`" in text
    for code in ROUTER_ERROR_CODES:
        assert code in text, code
    manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    router_hashes = {
        adapter["id"]: adapter["content_sha256"]
        for adapter in manifest["adapters"]
        if adapter["management"] == "generated-file"
    }
    assert router_hashes["shared-router"] == sha256_bytes(shared)
    assert router_hashes["claude-router"] == sha256_bytes(claude)
    # managed blocks carry the frozen marker pair
    for relative in ("AGENTS.md", "CLAUDE.md", ".github/copilot-instructions.md"):
        content = (project / relative).read_bytes()
        assert content.startswith(b"<!-- ai-skill-hub:runtime-pack:start schema=v1 -->\n")
        assert content.endswith(b"<!-- ai-skill-hub:runtime-pack:end -->\n")


# ---------------------------------------------------------------------------
# 22: paths with spaces and Chinese characters
# ---------------------------------------------------------------------------


def test_paths_with_spaces_and_chinese(tmp_path: Path, hub_remote: dict[str, object], session_env: dict[str, str]) -> None:
    project = tmp_path / "项目 with 空格"
    git_init(project, session_env)
    write_text(project / "README.md", "# spaced 项目\n")
    commit_all(project, "fixture", session_env)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    assert manifest["hub"]["path"] == ".ai/ai-skill-hub"
    assert "\\" not in (project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# 23-24: failure injection and rollback
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "injection",
    [
        "AfterModuleGitDirCreated",
        "AfterSubmoduleConfigCreated",
        "DuringSubmoduleMutation",
        "AfterSubmodule",
        "AfterFirstAdapter",
        "AfterManifest",
        "BeforeIndexSwap",
        "AfterIndexSwap",
    ],
)
def test_failure_injection_exact_rollback(
    project: Path, hub_remote: dict[str, object], injection: str
) -> None:
    before = snapshot_state(project)
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), fail_at=injection)
    assert_decision(result, keys, payload, "FAILED_APPLY_ROLLED_BACK", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    after = snapshot_state(project)
    assert before == after
    journals = list((project / ".git").glob("runtime-pack-journal-*"))
    assert journals == []


def test_injected_rollback_failure_retains_evidence(
    project: Path, hub_remote: dict[str, object]
) -> None:
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]), fail_at="DuringRollback")
    assert_decision(result, keys, payload, "BLOCKED_ROLLBACK_FAILURE", 4)
    assert payload["Rollback_Status"] == "FAILED_EVIDENCE_RETAINED"
    journals = list((project / ".git").glob("runtime-pack-journal-*"))
    assert len(journals) == 1
    journal = journals[0]
    assert (journal / "journal.json").is_file()
    assert str(journal) in payload["Message"]


def test_rollback_restores_human_files(
    project: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    target = project / "AGENTS.md"
    original = b"# human entry\r\n\r\nkeep me\r\n"
    target.write_bytes(original)
    commit_all(project, "human entry", session_env)
    before = snapshot_state(project)
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), fail_at="AfterManifest"
    )
    assert_decision(result, keys, payload, "FAILED_APPLY_ROLLED_BACK", 3)
    assert target.read_bytes() == original
    after = snapshot_state(project)
    # The raw index byte hash is stat-cache sensitive (Git refreshes stat data
    # after the byte-for-byte file restore), so exact equality is asserted on the
    # staged entry set plus all other pre-state facets.
    assert before["index_entries"] == after["index_entries"]
    for facet in ("worktree", "gitmodules", "config", "modules", "status"):
        assert before[facet] == after[facet], facet


# ---------------------------------------------------------------------------
# 25: ExternalPath mode
# ---------------------------------------------------------------------------


@pytest.fixture()
def external_hub(tmp_path: Path, hub_remote: dict[str, object], session_env: dict[str, str]) -> Path:
    external = tmp_path / "external-hub"
    subprocess.run(
        [GIT, "clone", "-q", str(hub_remote["path"]), str(external)],
        check=True,
        capture_output=True,
        env=session_env,
    )
    return external


def test_external_path_valid(
    project: Path, external_hub: Path, hub_remote: dict[str, object]
) -> None:
    result, keys, payload = run_init(
        project, "-HubMode", "ExternalPath", "-HubPath", str(external_hub)
    )
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert payload["Hub_Mode"] == "ExternalPath"
    assert payload["Resolved_Commit"] == hub_remote["main_commit"]
    manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    assert manifest["hub"]["mode"] == "external-path"
    expected_path = str(external_hub).replace("\\", "/")
    assert manifest["hub"]["path"] == expected_path
    assert manifest["routing"]["canonical_index"] == expected_path + "/SKILLS_INDEX.md"
    staged = staged_paths(project, project.parent / "fake-home")
    assert staged == sorted(ADAPTER_PATHS + [".ai/runtime-pack.json"])
    assert not (project / ".gitmodules").exists()
    external_head = git(external_hub, "rev-parse", "HEAD", env=isolated_env(project.parent / "fake-home")).stdout.strip()
    assert external_head == hub_remote["main_commit"]
    rerun, keys, payload = run_init(
        project, "-HubMode", "ExternalPath", "-HubPath", str(external_hub)
    )
    assert_decision(rerun, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)


def test_external_path_inside_project(
    project: Path, external_hub: Path, session_env: dict[str, str]
) -> None:
    inside = project / "inside-hub"
    subprocess.run(
        [GIT, "clone", "-q", str(external_hub), str(inside)],
        check=True,
        capture_output=True,
        env=session_env,
    )
    result, keys, payload = run_init(project, "-HubMode", "ExternalPath", "-HubPath", str(inside))
    assert_decision(result, keys, payload, "BLOCKED_EXTERNAL_PATH_INVALID", 2)


def test_external_path_non_git(project: Path, tmp_path: Path) -> None:
    plain = tmp_path / "plain-external"
    plain.mkdir()
    result, keys, payload = run_init(project, "-HubMode", "ExternalPath", "-HubPath", str(plain))
    assert_decision(result, keys, payload, "BLOCKED_EXTERNAL_PATH_INVALID", 2)


def test_external_path_reparse(project: Path, tmp_path: Path, external_hub: Path) -> None:
    link = tmp_path / "external-link"
    junction = subprocess.run(
        ["cmd.exe", "/d", "/c", "mklink", "/J", str(link), str(external_hub)],
        capture_output=True,
        text=True,
        check=False,
    )
    if junction.returncode != 0:
        pytest.skip(f"junction creation unavailable: {junction.stdout} {junction.stderr}")
    result, keys, payload = run_init(project, "-HubMode", "ExternalPath", "-HubPath", str(link))
    assert_decision(result, keys, payload, "BLOCKED_EXTERNAL_PATH_INVALID", 2)


def test_external_path_head_mismatch(
    project: Path, external_hub: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    git(external_hub, "checkout", "-q", "--detach", str(hub_remote["first_commit"]), env=session_env)
    result, keys, payload = run_init(
        project, "-HubMode", "ExternalPath", "-HubPath", str(external_hub), "-HubRef", "main"
    )
    assert_decision(result, keys, payload, "BLOCKED_EXTERNAL_PATH_INVALID", 2)


def test_external_path_forbids_huburl(
    project: Path, external_hub: Path, hub_remote: dict[str, object]
) -> None:
    result, keys, payload = run_init(
        project,
        "-HubMode", "ExternalPath",
        "-HubPath", str(external_hub),
        "-HubUrl", str(hub_remote["url"]),
    )
    assert_decision(result, keys, payload, "BLOCKED_EXTERNAL_PATH_INVALID", 2)


def test_external_path_requires_explicit_hubpath(project: Path) -> None:
    result, keys, payload = run_init(project, "-HubMode", "ExternalPath")
    assert_decision(result, keys, payload, "BLOCKED_EXTERNAL_PATH_INVALID", 2)


# ---------------------------------------------------------------------------
# 26: concurrent real index change before swap (deterministic injection)
# ---------------------------------------------------------------------------


def test_concurrent_index_change_before_swap(
    project: Path, hub_remote: dict[str, object]
) -> None:
    # The initializer's test-only hook rewrites the real index (read-tree
    # without stat cache) at the exact pre-swap check inside CommitReady, so
    # the concurrency detection fires deterministically on the first attempt:
    # no polling thread, no retry loop, no timing dependence.
    before = snapshot_state(project)
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), touch_real_index=True
    )
    assert_decision(result, keys, payload, "BLOCKED_CONCURRENT_STATE_CHANGE", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    after = snapshot_state(project)
    assert before == after
    assert list((project / ".git").glob("runtime-pack-journal-*")) == []
    # A subsequent run without injection must succeed from the restored state.
    retry, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(retry, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)


def test_concurrent_index_test_is_deterministic(
    tmp_path: Path, hub_remote: dict[str, object], session_env: dict[str, str]
) -> None:
    # Every attempt must produce the identical outcome from a confirmed-clean
    # starting state; none may rely on a race window or leave residue behind.
    for iteration in range(3):
        fresh = tmp_path / f"concurrent-deterministic-{iteration}"
        git_init(fresh, session_env)
        write_text(fresh / "README.md", "# fixture\n")
        commit_all(fresh, "fixture", session_env)
        before = snapshot_state(fresh)
        result, keys, payload = run_init(
            fresh, "-HubUrl", str(hub_remote["url"]), touch_real_index=True
        )
        assert_decision(result, keys, payload, "BLOCKED_CONCURRENT_STATE_CHANGE", 3)
        assert payload["Rollback_Status"] == "RESTORED"
        assert snapshot_state(fresh) == before
        assert list((fresh / ".git").glob("runtime-pack-journal-*")) == []


# ---------------------------------------------------------------------------
# 27: output contract
# ---------------------------------------------------------------------------


def test_output_key_order_and_exit_codes(project: Path, hub_remote: dict[str, object]) -> None:
    success, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert success.returncode == 0
    assert keys == EXPECTED_KEYS
    assert payload["Decision"] == "PASS_PROJECT_RUNTIME_PACK_INITIALIZED"

    blocking, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), "-HubRef", "no-such-ref"
    )
    # staged-complete state from the successful run stays valid; a missing ref is
    # only resolved on first install, so use a fresh project for the blocking case.
    if blocking.returncode not in (0, 2):
        raise AssertionError(blocking.stdout + blocking.stderr)


def test_output_contract_on_blocking(tmp_path: Path, hub_remote: dict[str, object], session_env: dict[str, str]) -> None:
    fresh = tmp_path / "fresh-project"
    git_init(fresh, session_env)
    write_text(fresh / "README.md", "# fresh\n")
    commit_all(fresh, "fixture", session_env)
    result, keys, payload = run_init(fresh, "-HubUrl", str(hub_remote["url"]), "-HubRef", "no-such-ref")
    assert_decision(result, keys, payload, "BLOCKED_REF_NOT_FOUND", 2)
    assert payload["Index_Change"] == "NO"
    assert payload["Working_Tree_Change"] == "NO"
    assert payload["Rollback_Status"] == "NOT_REQUIRED"
    assert "=" in payload["Message"] or payload["Message"]


# ---------------------------------------------------------------------------
# 28: JSON schema validates golden manifests
# ---------------------------------------------------------------------------


def validate_against_schema(instance, schema, path: str = "$") -> list[str]:
    errors: list[str] = []
    expected_type = schema.get("type")
    if "required" in schema:
        if not isinstance(instance, dict):
            errors.append(f"{path}: required applies to an object")
        else:
            for key in schema["required"]:
                if key not in instance:
                    errors.append(f"{path}: missing required '{key}'")
    if expected_type == "object":
        if not isinstance(instance, dict):
            return [f"{path}: expected object"]
        if schema.get("additionalProperties") is False:
            allowed = set(schema.get("properties", {}))
            for key in instance:
                if key not in allowed:
                    errors.append(f"{path}: unknown field '{key}'")
        for key, subschema in schema.get("properties", {}).items():
            if key in instance:
                errors.extend(validate_against_schema(instance[key], subschema, f"{path}.{key}"))
    elif expected_type == "array":
        if not isinstance(instance, list):
            return [f"{path}: expected array"]
        if "minItems" in schema and len(instance) < schema["minItems"]:
            errors.append(f"{path}: too few items")
        if "maxItems" in schema and len(instance) > schema["maxItems"]:
            errors.append(f"{path}: too many items")
        for index, item in enumerate(instance):
            errors.extend(validate_against_schema(item, schema.get("items", {}), f"{path}[{index}]"))
    elif expected_type == "string":
        if not isinstance(instance, str):
            return [f"{path}: expected string"]
        if "minLength" in schema and len(instance) < schema["minLength"]:
            errors.append(f"{path}: too short")
    if "pattern" in schema and isinstance(instance, str):
        if not re.search(schema["pattern"], instance):
            errors.append(f"{path}: pattern mismatch")
    if "const" in schema and instance != schema["const"]:
        errors.append(f"{path}: expected const {schema['const']!r}")
    if "enum" in schema and instance not in schema["enum"]:
        errors.append(f"{path}: not in enum")
    if "anyOf" in schema:
        branch_errors = [
            validate_against_schema(instance, branch, path)
            for branch in schema["anyOf"]
        ]
        if all(branch for branch in branch_errors):
            errors.append(f"{path}: no anyOf branch matched")
    if "not" in schema and not validate_against_schema(instance, schema["not"], path):
        errors.append(f"{path}: forbidden schema matched")
    return errors


def test_schema_is_draft_2020_12() -> None:
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"


def test_schema_validates_golden_manifests(
    project: Path,
    external_hub: Path,
    hub_remote: dict[str, object],
) -> None:
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    submodule_manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    assert validate_against_schema(submodule_manifest, schema) == []

    external_project = project.parent / "external-mode-project"
    git_init(external_project, isolated_env(project.parent / "fake-home"))
    write_text(external_project / "README.md", "# external mode\n")
    commit_all(external_project, "fixture", isolated_env(project.parent / "fake-home"))
    result, keys, payload = run_init(
        external_project, "-HubMode", "ExternalPath", "-HubPath", str(external_hub)
    )
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    external_manifest = json.loads((external_project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    assert validate_against_schema(external_manifest, schema) == []

    corrupted = json.loads(json.dumps(submodule_manifest))
    corrupted["unknown"] = 1
    assert validate_against_schema(corrupted, schema) != []
    corrupted = json.loads(json.dumps(submodule_manifest))
    corrupted["hub"]["resolved_commit"] = "not-a-commit"
    assert validate_against_schema(corrupted, schema) != []
    corrupted = json.loads(json.dumps(submodule_manifest))
    corrupted["adapters"][0]["id"] = "other-id"
    assert validate_against_schema(corrupted, schema) != []

    legacy = deepcopy(submodule_manifest)
    for adapter in legacy["adapters"]:
        adapter.pop("hash_algorithm")
        adapter.pop("hash_normalization")
    assert validate_against_schema(legacy, schema) == []

    algorithm_only = deepcopy(submodule_manifest)
    algorithm_only["adapters"][0].pop("hash_normalization")
    assert validate_against_schema(algorithm_only, schema) != []

    normalization_only = deepcopy(submodule_manifest)
    normalization_only["adapters"][0].pop("hash_algorithm")
    assert validate_against_schema(normalization_only, schema) != []


# ---------------------------------------------------------------------------
# Round 2R remediation: in-transaction submodule failure (F-01/F-05/F-07)
# ---------------------------------------------------------------------------


def test_failure_inside_submodule_mutation_restores_config_and_module_gitdir(
    project: Path, hub_remote: dict[str, object]
) -> None:
    # The failure is injected inside Invoke-SubmoduleMutation, after Git has
    # already created the submodule config section and .git/modules/ai-skill-hub.
    before = snapshot_state(project)
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), fail_at="AfterSubmoduleConfigCreated"
    )
    assert_decision(result, keys, payload, "FAILED_APPLY_ROLLED_BACK", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    after = snapshot_state(project)
    assert before == after
    assert not (project / ".git" / "modules" / "ai-skill-hub").exists()
    config = git(
        project, "config", "--get-regexp", r"^submodule\.",
        env=isolated_env(project.parent / "fake-home"), check=False,
    )
    assert config.returncode != 0
    assert not (project / ".gitmodules").exists()
    assert list((project / ".git").glob("runtime-pack-journal-*")) == []


def test_failure_inside_submodule_mutation_clean_retry_succeeds(
    project: Path, hub_remote: dict[str, object]
) -> None:
    # The historical failure mode left residue that made every later run return
    # BLOCKED_SUBMODULE_CONFLICT; a verified rollback must allow a clean retry.
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), fail_at="AfterModuleGitDirCreated"
    )
    assert_decision(result, keys, payload, "FAILED_APPLY_ROLLED_BACK", 3)
    retry, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(retry, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    assert payload["Resolved_Commit"] == hub_remote["main_commit"]


def test_rollback_verification_detects_config_residue(
    project: Path, hub_remote: dict[str, object]
) -> None:
    # Test-only hook: rollback deliberately skips the config cleanup; the
    # verification step must catch the residue and retain evidence (exit 4).
    result, keys, payload = run_init(
        project,
        "-HubUrl", str(hub_remote["url"]),
        fail_at="AfterSubmodule",
        rollback_skip="config",
    )
    assert_decision(result, keys, payload, "BLOCKED_ROLLBACK_FAILURE", 4)
    assert payload["Rollback_Status"] == "FAILED_EVIDENCE_RETAINED"
    assert "config section" in payload["Message"]
    journals = list((project / ".git").glob("runtime-pack-journal-*"))
    assert len(journals) == 1
    assert str(journals[0]) in payload["Message"]
    residue = git(
        project, "config", "--get-regexp", r"^submodule\.",
        env=isolated_env(project.parent / "fake-home"), check=False,
    )
    assert residue.returncode == 0


def test_rollback_verification_detects_module_gitdir_residue(
    project: Path, hub_remote: dict[str, object]
) -> None:
    result, keys, payload = run_init(
        project,
        "-HubUrl", str(hub_remote["url"]),
        fail_at="AfterSubmodule",
        rollback_skip="module-gitdir",
    )
    assert_decision(result, keys, payload, "BLOCKED_ROLLBACK_FAILURE", 4)
    assert payload["Rollback_Status"] == "FAILED_EVIDENCE_RETAINED"
    assert "module gitdir" in payload["Message"]
    journals = list((project / ".git").glob("runtime-pack-journal-*"))
    assert len(journals) == 1
    assert (project / ".git" / "modules" / "ai-skill-hub").is_dir()


# ---------------------------------------------------------------------------
# Round 2R remediation: real index isolation until CommitReady (F-06)
# ---------------------------------------------------------------------------

IN_TRANSACTION_INJECTION_POINTS = [
    "AfterModuleGitDirCreated",
    "AfterSubmoduleConfigCreated",
    "DuringSubmoduleMutation",
    "AfterSubmodule",
    "AfterFirstAdapter",
    "AfterManifest",
    "BeforeIndexSwap",
]


@pytest.mark.parametrize("injection", IN_TRANSACTION_INJECTION_POINTS)
def test_real_index_unchanged_until_commit_ready(
    project: Path, hub_remote: dict[str, object], injection: str
) -> None:
    # At every point before the CommitReady swap the real index must remain
    # byte-identical to its pre-transaction state and carry no gitlink; the
    # rollback path must therefore never depend on restoring an early-mutated
    # real index.
    env_home = project.parent / "fake-home"
    index_path = project / ".git" / "index"
    pre_hash = sha256_file(index_path)
    pre_entries = git(project, "ls-files", "-s", env=isolated_env(env_home)).stdout
    assert "160000" not in pre_entries
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), fail_at=injection
    )
    assert_decision(result, keys, payload, "FAILED_APPLY_ROLLED_BACK", 3)
    assert sha256_file(index_path) == pre_hash
    assert git(project, "ls-files", "-s", env=isolated_env(env_home)).stdout == pre_entries
    assert staged_paths(project, env_home) == []
    assert list((project / ".git").glob("runtime-pack-journal-*")) == []


# ---------------------------------------------------------------------------
# Round 2R remediation: empty entry files (F-03)
# ---------------------------------------------------------------------------


def assert_empty_entry_initialized(
    project: Path, hub_remote: dict[str, object], relative: str
) -> None:
    target = project / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(b"")
    commit_all(project, f"empty {relative}", isolated_env(project.parent / "fake-home"))
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)
    data = target.read_bytes()
    assert data.startswith(b"<!-- ai-skill-hub:runtime-pack:start schema=v1 -->\n")
    assert data.endswith(b"<!-- ai-skill-hub:runtime-pack:end -->\n")
    assert b"\r" not in data
    assert not data.startswith(b"\xef\xbb\xbf")
    manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    hashes = {adapter["path"]: adapter["content_sha256"] for adapter in manifest["adapters"]}
    assert sha256_bytes(data) == hashes[relative]
    rerun, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(rerun, keys, payload, "NO_CHANGE_PROJECT_RUNTIME_PACK_ALREADY_CURRENT", 0)
    assert target.read_bytes() == data


def test_empty_existing_agents_file(project: Path, hub_remote: dict[str, object]) -> None:
    assert_empty_entry_initialized(project, hub_remote, "AGENTS.md")


def test_empty_existing_claude_file(project: Path, hub_remote: dict[str, object]) -> None:
    assert_empty_entry_initialized(project, hub_remote, "CLAUDE.md")


def test_empty_existing_copilot_file(project: Path, hub_remote: dict[str, object]) -> None:
    assert_empty_entry_initialized(project, hub_remote, ".github/copilot-instructions.md")


# ---------------------------------------------------------------------------
# Round 2R remediation: path safety preflight (F-04)
# ---------------------------------------------------------------------------


def assert_hub_path_rejected_preflight(
    project: Path, hub_remote: dict[str, object], hub_path: str
) -> None:
    before = snapshot_state(project)
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), "-HubPath", hub_path
    )
    assert_decision(result, keys, payload, "BLOCKED_PATH_SAFETY_VIOLATION", 2)
    assert payload["Index_Change"] == "NO"
    assert payload["Working_Tree_Change"] == "NO"
    assert payload["Rollback_Status"] == "NOT_REQUIRED"
    # The rejection must happen before any transaction starts.
    assert snapshot_state(project) == before
    assert list((project / ".git").glob("runtime-pack-journal-*")) == []


def test_ads_hub_path_rejected_preflight(project: Path, hub_remote: dict[str, object]) -> None:
    assert_hub_path_rejected_preflight(project, hub_remote, ".ai/hub:stream")


def test_nested_dot_git_segment_rejected_preflight(
    project: Path, hub_remote: dict[str, object]
) -> None:
    assert_hub_path_rejected_preflight(project, hub_remote, "sub/.git/hub")


def test_trailing_dot_segment_rejected_preflight(
    project: Path, hub_remote: dict[str, object]
) -> None:
    assert_hub_path_rejected_preflight(project, hub_remote, ".ai/ai-skill-hub.")


def test_trailing_space_segment_rejected_preflight(
    project: Path, hub_remote: dict[str, object]
) -> None:
    assert_hub_path_rejected_preflight(project, hub_remote, ".ai/ai-skill-hub ")


# ---------------------------------------------------------------------------
# Round 2R remediation: transaction-created directory tracking (F-09)
# ---------------------------------------------------------------------------


def test_preexisting_empty_directories_preserved_on_rollback(
    project: Path, hub_remote: dict[str, object]
) -> None:
    preserved = (".github", ".agents", ".claude", ".ai", ".agents/skills", ".claude/skills")
    for relative in preserved:
        (project / relative).mkdir(parents=True, exist_ok=True)
    result, keys, payload = run_init(
        project, "-HubUrl", str(hub_remote["url"]), fail_at="AfterManifest"
    )
    assert_decision(result, keys, payload, "FAILED_APPLY_ROLLED_BACK", 3)
    assert payload["Rollback_Status"] == "RESTORED"
    for relative in preserved:
        assert (project / relative).is_dir(), relative
    assert list((project / ".ai").iterdir()) == []
    assert list((project / ".agents" / "skills").iterdir()) == []
    assert list((project / ".claude" / "skills").iterdir()) == []
    assert list((project / ".github").iterdir()) == []


# ---------------------------------------------------------------------------
# Round 2R remediation: actual generated router resolution (F-08)
# ---------------------------------------------------------------------------


def test_generated_router_drives_real_canonical_resolution(
    project: Path, hub_remote: dict[str, object]
) -> None:
    env_home = project.parent / "fake-home"
    result, keys, payload = run_init(project, "-HubUrl", str(hub_remote["url"]))
    assert_decision(result, keys, payload, "PASS_PROJECT_RUNTIME_PACK_INITIALIZED", 0)

    # 1. Start from the actual generated router artifact and verify the frozen
    #    locate/route steps are present in it.
    router_path = project / ".agents" / "skills" / "ai-skill-hub-router" / "SKILL.md"
    router_text = router_path.read_text(encoding="utf-8")
    assert router_text.startswith("---\nname: ai-skill-hub-router\n")
    assert "`../../../.ai/runtime-pack.json`" in router_text
    for step in ("1.", "2.", "3.", "4.", "5.", "6.", "7.", "8.", "9.", "10."):
        assert f"\n{step} " in router_text, step
    for code in ROUTER_ERROR_CODES:
        assert code in router_text, code

    # 2. Read the actual manifest the initializer generated.
    manifest = json.loads((project / ".ai" / "runtime-pack.json").read_text(encoding="utf-8"))
    assert manifest["schema_version"] == 1
    assert manifest["generator"] == {"id": "ai-skill-hub.project-runtime-pack", "version": 1}
    assert [adapter["id"] for adapter in manifest["adapters"]] == [
        "agents-entry",
        "claude-entry",
        "claude-router",
        "copilot-entry",
        "shared-router",
    ]
    hub_rel = manifest["hub"]["path"]
    hub = project / hub_rel
    resolved_commit = manifest["hub"]["resolved_commit"]

    # 3. Committed gitlink, manifest commit, and materialized hub HEAD agree.
    gitlink = git(project, "ls-files", "-s", "--", hub_rel, env=isolated_env(env_home)).stdout
    assert gitlink.startswith(f"160000 {resolved_commit}")
    head = git(hub, "rev-parse", "HEAD", env=isolated_env(env_home)).stdout.strip()
    assert head == resolved_commit

    # 4. Locate the Skill from the actual canonical index in the real hub.
    index_path = project / manifest["routing"]["canonical_index"]
    assert index_path.is_file()
    assert index_path.parent.resolve() == hub.resolve()
    entries = parse_index(index_path)
    named = "alpha-skill"
    selected = [entry for entry in entries if entry["name"] == named]
    assert len(selected) == 1

    # 5. Containment: the indexed canonical path must resolve to
    #    <hub>/skills/<skill>/SKILL.md with no escape.
    candidate = (hub / selected[0]["path"]).resolve()
    expected = (hub / "skills" / named / "SKILL.md").resolve()
    assert candidate == expected

    # 6. Read the actual canonical SKILL.md in the pinned hub checkout.
    skill_text = candidate.read_text(encoding="utf-8")
    assert "name: alpha-skill" in skill_text
    assert "alpha fixture" in skill_text

    # 7. No project-side copy of the canonical Skill body exists; the only
    #    SKILL.md files outside the hub are the two thin routers.
    for relative in ADAPTER_PATHS:
        assert "alpha fixture" not in (project / relative).read_text(encoding="utf-8")
    outside_hub = [
        path
        for path in project.rglob("SKILL.md")
        if ".ai" not in path.relative_to(project).parts
    ]
    assert sorted(path.relative_to(project).as_posix() for path in outside_hub) == sorted(
        path for path in ADAPTER_PATHS if path.endswith("SKILL.md")
    )
