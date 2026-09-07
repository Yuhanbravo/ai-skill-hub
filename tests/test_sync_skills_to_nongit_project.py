from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS_DIR = ROOT / "skills"
SCRIPT_PATH = ROOT / "tools" / "sync_skills_to_nongit_project.ps1"
CHECK_ADAPTER_SCRIPT_PATH = ROOT / "tools" / "check_adapter_consistency.py"


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def run_sync(project_path: Path, *extra_args: str) -> subprocess.CompletedProcess[str]:
    command = [
        "powershell.exe",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(SCRIPT_PATH),
        "-SkillHubPath",
        str(ROOT),
        "-ProjectPath",
        str(project_path),
        *extra_args,
    ]
    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=True,
    )


def get_skill_names() -> list[str]:
    return sorted(
        path.name
        for path in SKILLS_DIR.iterdir()
        if path.is_dir() and not path.name.startswith("_") and (path / "SKILL.md").exists()
    )


def snapshot_tree(root: Path) -> list[str]:
    if not root.exists():
        return []

    snapshot: list[str] = []
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        relative_path = path.relative_to(root).as_posix()
        snapshot.append(f"{relative_path}|{path.read_text(encoding='utf-8')}")
    return snapshot


def assert_adapter_consistency(project_path: Path) -> None:
    result = subprocess.run(
        [sys.executable, str(CHECK_ADAPTER_SCRIPT_PATH), str(project_path)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    assert_true(result.returncode == 0, f"adapter consistency check failed:\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}")


def assert_project_local_wrapper(wrapper_path: Path, expected_skill: str) -> None:
    text = wrapper_path.read_text(encoding="utf-8")
    assert_true(
        f"canonical_path: ../../../.codex/skills/{expected_skill}" in text,
        f"{wrapper_path} must point to project-local .codex skill path",
    )
    assert_true(
        "../../../skills/" not in text,
        f"{wrapper_path} must not point back to hub skills/",
    )
    assert_true(
        f"name: {expected_skill}" in text,
        f"{wrapper_path} must declare the expected skill name",
    )
    assert_true(
        f"Project-local skill definition: `../../../.codex/skills/{expected_skill}/SKILL.md`" in text,
        f"{wrapper_path} must point to the expected project-local skill definition",
    )


def assert_project_local_agents_summary(summary_path: Path, expected_skill: str) -> None:
    text = summary_path.read_text(encoding="utf-8")
    assert_true(
        f"- name: `{expected_skill}`" in text,
        f"{summary_path} must declare the expected skill name",
    )
    assert_true(
        f"- path: `.codex/skills/{expected_skill}`" in text,
        f"{summary_path} must point to project-local .codex skill path",
    )
    assert_true(
        "Read the project-local SKILL.md before execution." in text,
        f"{summary_path} must instruct readers to load the project-local skill",
    )


def assert_project_local_github_entry(entry_path: Path, expected_skill: str) -> None:
    text = entry_path.read_text(encoding="utf-8")
    assert_true(
        f"../../.codex/skills/{expected_skill}" in text,
        f"{entry_path} must point to project-local .codex skill path",
    )
    assert_true(
        "../../skills/" not in text,
        f"{entry_path} must not point back to hub skills/",
    )
    assert_true(
        f"- Canonical skill definition: `../../.codex/skills/{expected_skill}/SKILL.md`" in text,
        f"{entry_path} must point to the expected project-local skill definition",
    )


def test_all_sync() -> None:
    expected_skills = get_skill_names()

    with tempfile.TemporaryDirectory() as temp_dir:
        project_path = Path(temp_dir)
        (project_path / ".agents" / "skills" / "stale-skill").mkdir(parents=True, exist_ok=True)
        (project_path / ".agents" / "skills" / "stale-skill" / "SKILL.md").write_text(
            "canonical_path: ../../../.codex/skills/stale-skill\n- Read the project-local skill before execution.\n",
            encoding="utf-8",
        )
        (project_path / ".agents" / "skills" / "stale-skill.md").write_text(
            "- path: `.codex/skills/stale-skill`\nRead the project-local SKILL.md before execution.\n",
            encoding="utf-8",
        )
        (project_path / ".github" / "skills").mkdir(parents=True, exist_ok=True)
        (project_path / ".github" / "skills" / "stale-skill.md").write_text(
            "- Canonical skill path: `../../.codex/skills/stale-skill`\n- This compatibility entry is generated from the project-local .codex skill copy.\n",
            encoding="utf-8",
        )

        run_sync(project_path)

        codex_skills_root = project_path / ".codex" / "skills"
        agents_root = project_path / ".agents" / "skills"
        github_root = project_path / ".github" / "skills"

        actual_codex_skills = sorted(
            path.name
            for path in codex_skills_root.iterdir()
            if path.is_dir() and not path.name.startswith("_") and (path / "SKILL.md").exists()
        )
        actual_agents_wrappers = sorted(
            path.name
            for path in agents_root.iterdir()
            if path.is_dir() and (path / "SKILL.md").exists()
        )
        actual_github_entries = sorted(path.stem for path in github_root.glob("*.md"))

        assert_true(actual_codex_skills == expected_skills, "all sync must preserve full .codex skill coverage")
        assert_true(actual_agents_wrappers == expected_skills, "all sync must emit .agents wrappers for all skills")
        assert_true(actual_github_entries == expected_skills, "all sync must emit .github entries for all skills")
        assert_true((codex_skills_root / "_protocol").is_dir(), "all sync must keep _protocol under .codex/skills")
        assert_true((codex_skills_root / "_skillset_version.txt").is_file(), "all sync must write version metadata")

        for skill_name in expected_skills:
            assert_true((agents_root / f"{skill_name}.md").is_file(), f"missing flat .agents summary for {skill_name}")
            assert_project_local_wrapper(agents_root / skill_name / "SKILL.md", skill_name)
            assert_project_local_agents_summary(agents_root / f"{skill_name}.md", skill_name)
            assert_project_local_github_entry(github_root / f"{skill_name}.md", skill_name)

        assert_true(not (agents_root / "stale-skill").exists(), "all sync must remove stale generated .agents wrapper directories")
        assert_true(not (agents_root / "stale-skill.md").exists(), "all sync must remove stale generated .agents summaries")
        assert_true(not (github_root / "stale-skill.md").exists(), "all sync must remove stale generated .github entries")
        assert_adapter_consistency(project_path)


def test_single_skill_sync() -> None:
    target_skill = "project-takeover"

    with tempfile.TemporaryDirectory() as temp_dir:
        project_path = Path(temp_dir)
        run_sync(project_path, "-SkillName", target_skill)

        codex_skills_root = project_path / ".codex" / "skills"
        agents_root = project_path / ".agents" / "skills"
        github_root = project_path / ".github" / "skills"

        actual_codex_skills = sorted(
            path.name
            for path in codex_skills_root.iterdir()
            if path.is_dir() and not path.name.startswith("_") and (path / "SKILL.md").exists()
        )
        actual_agents_wrappers = sorted(
            path.name
            for path in agents_root.iterdir()
            if path.is_dir() and (path / "SKILL.md").exists()
        )
        actual_github_entries = sorted(path.stem for path in github_root.glob("*.md"))

        assert_true(actual_codex_skills == [target_skill], "single-skill sync must only materialize the requested .codex skill")
        assert_true(actual_agents_wrappers == [target_skill], "single-skill sync must only emit the requested .agents wrapper")
        assert_true(actual_github_entries == [target_skill], "single-skill sync must only emit the requested .github entry")
        assert_true((agents_root / f"{target_skill}.md").is_file(), "single-skill sync must emit the requested flat .agents summary")
        assert_true((codex_skills_root / "_skillset_version.txt").is_file(), "single-skill sync must still write version metadata")

        assert_project_local_wrapper(agents_root / target_skill / "SKILL.md", target_skill)
        assert_project_local_agents_summary(agents_root / f"{target_skill}.md", target_skill)
        assert_project_local_github_entry(github_root / f"{target_skill}.md", target_skill)
        assert_adapter_consistency(project_path)


def test_codex_only_target_sync_preserves_existing_adapters() -> None:
    expected_skills = get_skill_names()

    with tempfile.TemporaryDirectory() as temp_dir:
        project_path = Path(temp_dir)
        agents_root = project_path / ".agents" / "skills"
        github_root = project_path / ".github" / "skills"
        agents_root.mkdir(parents=True, exist_ok=True)
        github_root.mkdir(parents=True, exist_ok=True)
        (agents_root / "custom-note.md").write_text("keep this agent file\n", encoding="utf-8")
        (github_root / "custom-note.md").write_text("keep this github file\n", encoding="utf-8")

        before_agents = snapshot_tree(agents_root)
        before_github = snapshot_tree(github_root)

        run_sync(project_path, "-Targets", "codex")

        codex_skills_root = project_path / ".codex" / "skills"
        actual_codex_skills = sorted(
            path.name
            for path in codex_skills_root.iterdir()
            if path.is_dir() and not path.name.startswith("_") and (path / "SKILL.md").exists()
        )

        assert_true(actual_codex_skills == expected_skills, "codex-only sync must still materialize full .codex skill coverage")
        assert_true((codex_skills_root / "_skillset_version.txt").is_file(), "codex-only sync must still write version metadata")
        assert_true(before_agents == snapshot_tree(agents_root), "codex-only sync must not modify .agents/skills")
        assert_true(before_github == snapshot_tree(github_root), "codex-only sync must not modify .github/skills")


def test_explicit_full_targets_sync_single_skill() -> None:
    target_skill = "project-takeover"

    with tempfile.TemporaryDirectory() as temp_dir:
        project_path = Path(temp_dir)
        run_sync(project_path, "-SkillName", target_skill, "-Targets", "codex,agents,github")

        codex_skills_root = project_path / ".codex" / "skills"
        agents_root = project_path / ".agents" / "skills"
        github_root = project_path / ".github" / "skills"

        assert_true((codex_skills_root / target_skill / "SKILL.md").is_file(), "explicit full-target sync must materialize the requested .codex skill")
        assert_true((codex_skills_root / "_skillset_version.txt").is_file(), "explicit full-target sync must write version metadata")
        assert_project_local_wrapper(agents_root / target_skill / "SKILL.md", target_skill)
        assert_project_local_agents_summary(agents_root / f"{target_skill}.md", target_skill)
        assert_project_local_github_entry(github_root / f"{target_skill}.md", target_skill)
        assert_adapter_consistency(project_path)


def main() -> int:
    test_all_sync()
    test_single_skill_sync()
    test_codex_only_target_sync_preserves_existing_adapters()
    test_explicit_full_targets_sync_single_skill()
    print("sync_skills_to_nongit_project smoke test passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
