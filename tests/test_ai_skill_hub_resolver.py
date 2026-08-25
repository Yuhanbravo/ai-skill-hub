from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "ai_skill_hub_resolver.py"


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def write_skill(hub_root: Path, skill_id: str, *, declared_name: str | None = None) -> None:
    name = declared_name if declared_name is not None else skill_id
    write_text(
        hub_root / "skills" / skill_id / "SKILL.md",
        "---\n"
        f"name: {name}\n"
        'description: "fixture canonical Skill"\n'
        "---\n\n"
        f"# {skill_id}\n",
    )


def build_hub(parent: Path) -> Path:
    hub_root = parent / "canonical-hub"
    for skill_id in ("workflow-bootstrap", "chatgpt-handoff-pilot", "project-takeover"):
        write_skill(hub_root, skill_id)
    write_text(hub_root / "skills" / "_protocol" / "skill_assessment_output.md", "protocol\n")
    result = subprocess.run(["git", "init", str(hub_root)], capture_output=True, text=True, check=False)
    assert result.returncode == 0, result.stderr
    return hub_root


def run_router(codex_home: Path, *arguments: str) -> tuple[subprocess.CompletedProcess[str], dict]:
    result = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            *arguments,
            "--codex-home",
            str(codex_home),
            "--output-format",
            "json",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    return result, json.loads(result.stdout)


def configure(codex_home: Path, hub_root: Path) -> dict:
    result, payload = run_router(codex_home, "configure", "--hub-root", str(hub_root))
    assert result.returncode == 0, result.stderr
    assert payload["decision"] == "PASS_HUB_LOCATOR_CONFIGURED"
    return payload


def test_configure_creates_only_machine_level_locator_and_thin_router() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        codex_home = root / "codex-home"
        configure(codex_home, hub_root)

        locator = json.loads((codex_home / "ai-skill-hub" / "locator.json").read_text(encoding="utf-8"))
        router_text = (codex_home / "skills" / "ai-skill-hub-router" / "SKILL.md").read_text(encoding="utf-8")
        assert locator["hub_root"] == str(hub_root.resolve())
        assert str(hub_root.resolve()) not in router_text
        assert not (codex_home / "skills" / "project-takeover").exists()
        assert "Do not fall back" in router_text

        result, payload = run_router(codex_home, "configure", "--hub-root", str(hub_root))
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "NO_CHANGE_HUB_LOCATOR_CURRENT"


def test_smoke_resolves_bundled_and_unbundled_canonical_skills() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        codex_home = root / "codex-home"
        configure(codex_home, hub_root)

        result, payload = run_router(
            codex_home,
            "smoke",
            "--required-skill",
            "workflow-bootstrap",
            "--required-skill",
            "chatgpt-handoff-pilot",
            "--required-skill",
            "project-takeover",
        )

        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "PASS_REQUIRED_SKILL_ROUTING_SMOKE"
        assert payload["overall"] == "PASS"
        assert [item["status"] for item in payload["resolutions"]] == ["RESOLVED"] * 3
        assert payload["resolutions"][2]["canonical_entry"] == "skills/project-takeover/SKILL.md"
        assert "project-takeover" not in {"workflow-bootstrap", "chatgpt-handoff-pilot"}


def test_doctor_reports_adopt_as_is_when_required_routing_is_complete() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        codex_home = root / "codex-home"
        configure(codex_home, hub_root)

        result, payload = run_router(
            codex_home,
            "doctor",
            "--required-skill",
            "documentation-governance",
        )

        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED"
        assert payload["routing_gap"] is True
        assert payload["resolutions"][0]["status"] == "MISSING"

        write_skill(hub_root, "documentation-governance")
        result, payload = run_router(
            codex_home,
            "doctor",
            "--required-skill",
            "documentation-governance",
        )
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "ADOPT_AS_IS"
        assert payload["routing_gap"] is False


def test_negative_resolution_fails_closed_for_invalid_missing_and_unavailable_states() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        codex_home = root / "codex-home"

        result, payload = run_router(codex_home, "smoke", "--required-skill", "workflow-bootstrap")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "HUB_UNAVAILABLE"

        configure(codex_home, hub_root)
        result, payload = run_router(codex_home, "resolve", "not a skill")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "SKILL_ID_SYNTAX_INVALID"

        result, payload = run_router(codex_home, "resolve", "does-not-exist")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "MISSING"
        assert payload["resolutions"][0]["code"] == "CANONICAL_SKILL_MISSING"

        result, payload = run_router(codex_home, "resolve", "_protocol")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "SKILL_ID_SYNTAX_INVALID"


def test_invalid_hub_and_missing_canonical_entry_are_blocked() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        codex_home = root / "codex-home"
        invalid_hub = root / "not-a-hub"
        invalid_hub.mkdir()
        locator_path = codex_home / "ai-skill-hub" / "locator.json"
        write_text(
            locator_path,
            json.dumps(
                {
                    "schema_version": 1,
                    "kind": "ai-skill-hub.canonical-hub-locator",
                    "hub_root": str(invalid_hub),
                }
            )
            + "\n",
        )
        result, payload = run_router(codex_home, "resolve", "workflow-bootstrap")
        assert result.returncode == 2
        assert payload["hub_state"] == "INVALID"
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "HUB_STRUCTURE_INVALID"

        hub_root = build_hub(root)
        write_text(
            locator_path,
            json.dumps(
                {
                    "schema_version": 1,
                    "kind": "ai-skill-hub.canonical-hub-locator",
                    "hub_root": str(hub_root),
                }
            )
            + "\n",
        )
        (hub_root / "skills" / "project-takeover" / "SKILL.md").unlink()
        result, payload = run_router(codex_home, "resolve", "project-takeover")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "MISSING"
        assert payload["resolutions"][0]["code"] == "CANONICAL_ENTRY_MISSING"


def test_unsupported_locator_schema_is_invalid_without_fallback() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        codex_home = root / "codex-home"
        write_text(
            codex_home / "ai-skill-hub" / "locator.json",
            '{"schema_version": 2, "kind": "ai-skill-hub.canonical-hub-locator", "hub_root": "X:/invalid"}\n',
        )
        result, payload = run_router(codex_home, "resolve", "workflow-bootstrap")
        assert result.returncode == 2
        assert payload["locator_state"] == "INVALID"
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "LOCATOR_SCHEMA_UNSUPPORTED"


def test_competing_declared_canonical_identity_is_ambiguous_and_blocked() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        codex_home = root / "codex-home"
        configure(codex_home, hub_root)
        write_skill(hub_root, "unexpected-copy", declared_name="project-takeover")

        result, payload = run_router(codex_home, "resolve", "project-takeover")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "CANONICAL_IDENTITY_AMBIGUOUS"


def main() -> int:
    test_configure_creates_only_machine_level_locator_and_thin_router()
    test_smoke_resolves_bundled_and_unbundled_canonical_skills()
    test_doctor_reports_adopt_as_is_when_required_routing_is_complete()
    test_negative_resolution_fails_closed_for_invalid_missing_and_unavailable_states()
    test_invalid_hub_and_missing_canonical_entry_are_blocked()
    test_unsupported_locator_schema_is_invalid_without_fallback()
    test_competing_declared_canonical_identity_is_ambiguous_and_blocked()
    print("AI-level canonical Skill resolver tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
