from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "tools" / "check_adapter_consistency.py"
LOCAL_TMP_ROOT = ROOT / ".tmp" / "test_adapter_consistency"


def assert_equal(actual: object, expected: object, message: str) -> None:
    if actual != expected:
        raise AssertionError(f"{message}: expected={expected!r}, actual={actual!r}")


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_module():
    spec = importlib.util.spec_from_file_location("check_adapter_consistency", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Failed to load check_adapter_consistency module.")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


@contextmanager
def temporary_directory():
    LOCAL_TMP_ROOT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=LOCAL_TMP_ROOT) as temp_dir:
        yield Path(temp_dir)


def build_sample_consumer_project(project_root: Path) -> None:
    write_file(project_root / ".codex" / "skills" / "alpha" / "SKILL.md", "# alpha\n")
    write_file(project_root / ".codex" / "skills" / "beta" / "SKILL.md", "# beta\n")
    write_file(project_root / ".codex" / "skills" / "_protocol" / "skill_invocation.md", "protocol\n")

    write_file(
        project_root / ".agents" / "skills" / "alpha" / "SKILL.md",
        "canonical_path: ../../../skills/alpha\n",
    )
    write_file(
        project_root / ".agents" / "skills" / "gamma" / "SKILL.md",
        "canonical_path: ../../../.codex/skills/gamma\n",
    )

    write_file(
        project_root / ".github" / "skills" / "alpha.md",
        "- Canonical skill path: `../../skills/alpha`\n",
    )
    write_file(
        project_root / ".github" / "skills" / "gamma.md",
        "- Canonical skill path: `../../.codex/skills/gamma`\n",
    )


def build_sample_hub_project(project_root: Path) -> None:
    write_file(project_root / "skills" / "alpha" / "SKILL.md", "# alpha\n")
    write_file(project_root / "skills" / "beta" / "SKILL.md", "# beta\n")
    write_file(project_root / "skills" / "_protocol" / "skill_invocation.md", "protocol\n")

    write_file(
        project_root / ".agents" / "skills" / "alpha" / "SKILL.md",
        "canonical_path: ../../../.codex/skills/alpha\n",
    )
    write_file(
        project_root / ".agents" / "skills" / "gamma" / "SKILL.md",
        "canonical_path: ../../../skills/gamma\n",
    )

    write_file(
        project_root / ".github" / "skills" / "alpha.md",
        "- Canonical skill path: `../../.codex/skills/alpha`\n",
    )
    write_file(
        project_root / ".github" / "skills" / "gamma.md",
        "- Canonical skill path: `../../skills/gamma`\n",
    )


def test_check_consistency_consumer_mode() -> None:
    module = load_module()

    with temporary_directory() as project_root:
        build_sample_consumer_project(project_root)
        result = module.check_consistency(project_root, mode="consumer")

        assert_equal(result["missing_agents"], ["beta"], "missing agents mismatch")
        assert_equal(result["missing_github"], ["beta"], "missing github mismatch")
        assert_equal(result["orphan_agents"], ["gamma"], "orphan agents mismatch")
        assert_equal(result["orphan_github"], ["gamma"], "orphan github mismatch")
        assert_equal(result["wrong_reference_agents"], ["alpha"], "wrong agents reference mismatch")
        assert_equal(result["wrong_reference_github"], ["alpha"], "wrong github reference mismatch")


def test_check_consistency_hub_mode() -> None:
    module = load_module()

    with temporary_directory() as project_root:
        build_sample_hub_project(project_root)
        result = module.check_consistency(project_root, mode="hub")

        assert_equal(result["missing_agents"], ["beta"], "missing agents mismatch")
        assert_equal(result["missing_github"], ["beta"], "missing github mismatch")
        assert_equal(result["orphan_agents"], ["gamma"], "orphan agents mismatch")
        assert_equal(result["orphan_github"], ["gamma"], "orphan github mismatch")
        assert_equal(result["wrong_reference_agents"], ["alpha"], "wrong agents reference mismatch")
        assert_equal(result["wrong_reference_github"], ["alpha"], "wrong github reference mismatch")


def test_cli_consumer_exit_code_and_output() -> None:
    with temporary_directory() as project_root:
        build_sample_consumer_project(project_root)

        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), str(project_root), "--mode", "consumer"],
            capture_output=True,
            text=True,
            check=False,
        )

        assert_equal(result.returncode, 1, "CLI must exit with code 1 when issues are detected")
        assert_true("[Adapter Governance Report]" in result.stdout, "CLI report header missing")
        assert_true("Mode: consumer" in result.stdout, "CLI mode header missing")
        assert_true("Contract: .codex/skills -> .agents/.github" in result.stdout, "CLI contract header missing")
        assert_true("codex skills: 2" in result.stdout, "CLI codex count missing")
        assert_true("[Missing]" in result.stdout, "CLI missing section missing")
        assert_true("[Orphan]" in result.stdout, "CLI orphan section missing")
        assert_true("[Wrong Reference]" in result.stdout, "CLI wrong-reference section missing")
        assert_true("Issues detected: 6" in result.stdout, "CLI summary count mismatch")


def test_cli_hub_exit_code_and_output() -> None:
    with temporary_directory() as project_root:
        build_sample_hub_project(project_root)

        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), str(project_root), "--mode", "hub"],
            capture_output=True,
            text=True,
            check=False,
        )

        assert_equal(result.returncode, 1, "CLI must exit with code 1 when issues are detected")
        assert_true("Mode: hub" in result.stdout, "CLI mode header missing")
        assert_true("Contract: skills/ -> .agents/.github" in result.stdout, "CLI contract header missing")
        assert_true("canonical skills: 2" in result.stdout, "CLI canonical count missing")
        assert_true("Expected agents reference prefix: ../../../skills/" in result.stdout, "CLI agents contract hint missing")
        assert_true("Expected github reference prefix: ../../skills/" in result.stdout, "CLI github contract hint missing")


def test_wrong_contract_reports_clear_mode_context() -> None:
    with temporary_directory() as project_root:
        write_file(project_root / "skills" / "alpha" / "SKILL.md", "# alpha\n")
        write_file(
            project_root / ".agents" / "skills" / "alpha" / "SKILL.md",
            "canonical_path: ../../../skills/alpha\n",
        )
        write_file(
            project_root / ".github" / "skills" / "alpha.md",
            "- Canonical skill path: `../../skills/alpha`\n",
        )

        result = subprocess.run(
            [sys.executable, str(SCRIPT_PATH), str(project_root), "--mode", "consumer"],
            capture_output=True,
            text=True,
            check=False,
        )

        assert_equal(result.returncode, 1, "wrong contract usage must fail clearly")
        assert_true("Mode: consumer" in result.stdout, "wrong-contract report must show the selected mode")
        assert_true("Contract: .codex/skills -> .agents/.github" in result.stdout, "wrong-contract report must show the expected contract")
        assert_true("Expected agents reference prefix: ../../../.codex/skills/" in result.stdout, "wrong-contract report must show agents expectation")
        assert_true("Expected github reference prefix: ../../.codex/skills/" in result.stdout, "wrong-contract report must show github expectation")


def main() -> int:
    test_check_consistency_consumer_mode()
    test_check_consistency_hub_mode()
    test_cli_consumer_exit_code_and_output()
    test_cli_hub_exit_code_and_output()
    test_wrong_contract_reports_clear_mode_context()
    print("adapter consistency smoke test passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
