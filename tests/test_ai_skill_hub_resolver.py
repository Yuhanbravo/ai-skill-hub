from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from unittest.mock import patch


# Exact known stale router shape from the pre-remediation generation (base
# 9231e5f, before the 240f74d locator neutralization).  The sanctioned
# maintainer reconciliation in docs/governance/stale_router_reconciliation_v1.md
# keys on this exact byte shape; the fixture is pinned by hash so any drift in
# the constant fails loudly instead of silently weakening the fail-closed
# coverage.  Lines are joined explicitly so the fixture is independent of the
# checkout's line-ending convention.
KNOWN_STALE_ROUTER_SHA256 = (
    "80272ffa8e0bf699ffc9ee2fb39bf8246089d530161a21c26827307e939979aa"
)
KNOWN_STALE_ROUTER_TEXT = (
    "\n".join(
        (
            "---",
            "name: ai-skill-hub-router",
            'description: "Resolve logical ai-skill-hub Skill IDs through the machine-level Hub locator."',
            "---",
            "",
            "# AI Skill Hub Router",
            "",
            "This is a machine-level thin routing adapter. It does not contain canonical",
            "Skill payload and it does not grant write, install, update, or fallback",
            "authority.",
            "",
            "## Route",
            "",
            "1. Read the machine-local locator at `$CODEX_HOME/ai-skill-hub/locator.json`.",
            "2. Require locator schema `1` and kind `ai-skill-hub.canonical-hub-locator`.",
            "3. From the located Hub checkout, use `tools/ai_skill_hub_resolver.py` with an",
            "   exact logical Skill ID. Do not infer a physical Consumer Project path.",
            "4. Accept only a `RESOLVED` result, then read the returned canonical",
            "   `skills/<skill-id>/SKILL.md` completely.",
            "5. If the locator, Hub, canonical identity, or entry is invalid or missing,",
            "   stop and report the resolver result. Do not fall back to a project copy,",
            "   Runtime Pack, Bundle payload, adapter, or model memory.",
            "",
            "Use `doctor` or `smoke` in the resolver for a reusable required-Skill routing",
            "check. The Consumer Project declares logical IDs only; the machine locator is",
            "the only component that may store a local Hub checkout path.",
        )
    )
    + "\n"
)


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "ai_skill_hub_resolver.py"
RESOLVER_SPEC = importlib.util.spec_from_file_location("ai_skill_hub_resolver_under_test", SCRIPT)
assert RESOLVER_SPEC is not None and RESOLVER_SPEC.loader is not None
RESOLVER = importlib.util.module_from_spec(RESOLVER_SPEC)
sys.modules[RESOLVER_SPEC.name] = RESOLVER
RESOLVER_SPEC.loader.exec_module(RESOLVER)

MACHINE_ENV_VARS = (
    "AI_SKILL_HUB_CONFIG_HOME",
    "AI_SKILL_HUB_AGENTS_HOME",
    "CODEX_HOME",
    "CLAUDE_CONFIG_DIR",
)


@dataclass(frozen=True)
class Sandbox:
    """Isolated machine-level homes; nothing here touches the real user profile."""

    root: Path
    config_home: Path
    codex_home: Path
    claude_home: Path
    agents_home: Path

    @property
    def locator_path(self) -> Path:
        return self.config_home / ".ai-skill-hub" / "locator.json"

    def adapter_path(self, adapter: str) -> Path:
        home = {
            "codex": self.codex_home,
            "claude": self.claude_home,
            "agents": self.agents_home,
        }[adapter]
        return home / "skills" / "ai-skill-hub-router" / "SKILL.md"


def make_sandbox(root: Path) -> Sandbox:
    return Sandbox(
        root=root,
        config_home=root / "home",
        codex_home=root / "codex-home",
        claude_home=root / "claude-home",
        agents_home=root / "agents-home",
    )


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


def run_resolver(
    sandbox: Sandbox, *arguments: str, extra_env: dict[str, str] | None = None
) -> tuple[subprocess.CompletedProcess[str], dict]:
    env = os.environ.copy()
    for name in MACHINE_ENV_VARS:
        env.pop(name, None)
    if extra_env:
        env.update(extra_env)
    result = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            *arguments,
            "--config-home",
            str(sandbox.config_home),
            "--output-format",
            "json",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        env=env,
    )
    return result, json.loads(result.stdout)


def run_configure(
    sandbox: Sandbox, *arguments: str, extra_env: dict[str, str] | None = None
) -> tuple[subprocess.CompletedProcess[str], dict]:
    return run_resolver(
        sandbox,
        "configure",
        "--codex-home",
        str(sandbox.codex_home),
        "--claude-home",
        str(sandbox.claude_home),
        "--agents-home",
        str(sandbox.agents_home),
        *arguments,
        extra_env=extra_env,
    )


def configure(sandbox: Sandbox, hub_root: Path) -> dict:
    result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
    assert result.returncode == 0, result.stderr
    assert payload["decision"] == "PASS_HUB_LOCATOR_CONFIGURED"
    assert payload["mutation"] == "PERFORMED"
    return payload


def test_configure_creates_neutral_locator_and_all_thin_adapters() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        payload = configure(sandbox, hub_root)

        locator = json.loads(sandbox.locator_path.read_text(encoding="utf-8"))
        assert locator["schema_version"] == 1
        assert locator["kind"] == "ai-skill-hub.canonical-hub-locator"
        assert locator["hub_root"] == str(hub_root.resolve())
        assert payload["locator_path"] == "~/.ai-skill-hub/locator.json"

        adapter_texts = {
            adapter: sandbox.adapter_path(adapter).read_text(encoding="utf-8")
            for adapter in ("codex", "claude", "agents")
        }
        assert len(set(adapter_texts.values())) == 1
        router_text = adapter_texts["codex"]
        assert router_text.startswith("---\nname: ai-skill-hub-router\n")
        assert "~/.ai-skill-hub/locator.json" in router_text
        assert "Do not fall back" in router_text
        assert str(hub_root.resolve()) not in router_text
        assert str(root) not in router_text
        assert "$CODEX_HOME" not in router_text

        # Thin adapters only: no canonical Skill payload is copied anywhere.
        for home in (sandbox.codex_home, sandbox.claude_home, sandbox.agents_home):
            installed = sorted(path.name for path in (home / "skills").iterdir())
            assert installed == ["ai-skill-hub-router"]

        managed_ids = [target["target"] for target in payload["managed_targets"]]
        assert managed_ids == ["locator", "codex_adapter", "claude_adapter", "agents_adapter"]
        assert all(target["action"] == "written" for target in payload["managed_targets"])

        result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "NO_CHANGE_HUB_LOCATOR_CURRENT"
        assert payload["mutation"] == "NONE"


def test_neutral_locator_config_home_env_override_and_codex_home_independence() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        # Environment override (no --config-home): the neutral locator is found.
        env = os.environ.copy()
        for name in MACHINE_ENV_VARS:
            env.pop(name, None)
        env["AI_SKILL_HUB_CONFIG_HOME"] = str(sandbox.config_home)
        # A stray CODEX_HOME must not influence agent-neutral resolution.
        env["CODEX_HOME"] = str(root / "unrelated-codex-home")
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "resolve", "project-takeover", "--output-format", "json"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
            env=env,
        )
        payload = json.loads(result.stdout)
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "RESOLVED"
        assert payload["locator_path"] == "~/.ai-skill-hub/locator.json"

        # Explicit --locator override remains available for read-only inspection.
        result, payload = run_resolver(
            sandbox, "resolve", "project-takeover", "--locator", str(sandbox.locator_path)
        )
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "RESOLVED"
        assert payload["locator_path"] == "~/.ai-skill-hub/locator.json"


def test_codex_thin_adapter_routes_through_neutral_locator() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        adapter_text = sandbox.adapter_path("codex").read_text(encoding="utf-8")
        assert "~/.ai-skill-hub/locator.json" in adapter_text

        result, payload = run_resolver(sandbox, "resolve", "project-takeover")
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "RESOLVED"
        assert payload["resolutions"][0]["canonical_entry"] == "skills/project-takeover/SKILL.md"


def test_claude_thin_adapter_routes_through_neutral_locator() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        adapter_path = sandbox.adapter_path("claude")
        assert adapter_path == sandbox.claude_home / "skills" / "ai-skill-hub-router" / "SKILL.md"
        adapter_text = adapter_path.read_text(encoding="utf-8")
        assert adapter_text == sandbox.adapter_path("codex").read_text(encoding="utf-8")
        assert "~/.ai-skill-hub/locator.json" in adapter_text

        result, payload = run_resolver(sandbox, "smoke", "--required-skill", "workflow-bootstrap")
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "PASS_REQUIRED_SKILL_ROUTING_SMOKE"


def test_generic_agents_adapter_routes_through_neutral_locator() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        adapter_path = sandbox.adapter_path("agents")
        assert adapter_path == sandbox.agents_home / "skills" / "ai-skill-hub-router" / "SKILL.md"
        adapter_text = adapter_path.read_text(encoding="utf-8")
        assert adapter_text == sandbox.adapter_path("codex").read_text(encoding="utf-8")
        assert "~/.ai-skill-hub/locator.json" in adapter_text

        result, payload = run_resolver(sandbox, "resolve", "chatgpt-handoff-pilot")
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "RESOLVED"


def test_configure_all_target_preflight_conflict_leaves_no_new_managed_state() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)

        # Unknown content occupies the Claude adapter destination.
        conflicting = sandbox.adapter_path("claude")
        write_text(conflicting, "---\nname: ai-skill-hub-router\n---\nunknown local content\n")

        result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED_ROUTER_CONFLICT"
        assert payload["mutation"] == "NONE"
        assert payload["overall"] == "BLOCKED"

        # Mutation=NONE is literal: no locator and no adapter was created.
        assert not sandbox.locator_path.exists()
        assert not sandbox.adapter_path("codex").exists()
        assert not sandbox.adapter_path("agents").exists()
        assert not (sandbox.config_home / ".ai-skill-hub").exists()
        assert conflicting.read_text(encoding="utf-8").endswith("unknown local content\n")

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)

        # Unknown content occupies the locator destination itself.
        write_text(sandbox.locator_path, '{"schema_version": 1, "kind": "other", "hub_root": "X:/x"}\n')

        result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED_LOCATOR_CONFLICT"
        assert payload["mutation"] == "NONE"
        assert not sandbox.adapter_path("codex").exists()
        assert not sandbox.adapter_path("claude").exists()
        assert not sandbox.adapter_path("agents").exists()


def test_configure_rejects_non_default_locator_path() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)

        result, payload = run_configure(
            sandbox, "--hub-root", str(hub_root), "--locator", str(root / "custom" / "locator.json")
        )
        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED_LOCATOR_PATH_UNSUPPORTED"
        assert payload["mutation"] == "NONE"
        assert not (root / "custom").exists()


def test_zero_required_skills_fail_closed_unless_explicitly_intentional() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        for operation in ("smoke", "doctor"):
            result, payload = run_resolver(sandbox, operation)
            assert result.returncode == 2
            assert payload["decision"] == "INSUFFICIENT_REQUIREMENTS"
            assert payload["overall"] == "BLOCKED"
            assert payload["routing_gap"] is True
            assert payload["requirements_declared"] is False
            assert payload["zero_requirements_intentional"] is False

        result, payload = run_resolver(sandbox, "smoke", "--allow-empty-requirements")
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "PASS_REQUIRED_SKILL_ROUTING_SMOKE"
        assert payload["zero_requirements_intentional"] is True
        assert payload["requirements_declared"] is False

        result, payload = run_resolver(sandbox, "doctor", "--allow-empty-requirements")
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "ADOPT_AS_IS"
        assert payload["zero_requirements_intentional"] is True


def make_junction(link: Path, target: Path) -> bool:
    """Create a directory junction (reparse point) without requiring symlink privilege."""
    target.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        ["cmd", "/c", "mklink", "/J", str(link), str(target)],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode == 0 and link.exists()


def test_reparse_point_locator_is_rejected() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)

        real_locator = root / "real-locator.json"
        write_text(
            real_locator,
            json.dumps(
                {
                    "schema_version": 1,
                    "kind": "ai-skill-hub.canonical-hub-locator",
                    "hub_root": str(hub_root),
                }
            )
            + "\n",
        )
        link_path = sandbox.locator_path
        link_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            os.symlink(real_locator, link_path)
        except OSError as exc:
            print(f"[SKIP] symlinked-locator rejection requires symlink privilege: {exc}")
        else:
            result, payload = run_resolver(sandbox, "resolve", "project-takeover")
            assert result.returncode == 2
            assert payload["locator_state"] == "MISSING"
            assert payload["resolutions"][0]["status"] == "HUB_UNAVAILABLE"
            assert payload["resolutions"][0]["code"] == "LOCATOR_MISSING"

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)

        # Junction (reparse point) as the Hub checkout: fail closed.
        hub_link = root / "hub-link"
        if not make_junction(hub_link, hub_root):
            print("[SKIP] junction-based hub rejection requires junction creation")
        else:
            write_text(
                sandbox.locator_path,
                json.dumps(
                    {
                        "schema_version": 1,
                        "kind": "ai-skill-hub.canonical-hub-locator",
                        "hub_root": str(hub_link),
                    }
                )
                + "\n",
            )
            result, payload = run_resolver(sandbox, "resolve", "project-takeover")
            assert result.returncode == 2
            assert payload["hub_state"] == "UNAVAILABLE"
            assert payload["resolutions"][0]["code"] == "HUB_CHECKOUT_UNAVAILABLE"

        # Junction (reparse point) as a canonical Skill directory: fail closed.
        skill_link = hub_root / "skills" / "linked-skill"
        if not make_junction(skill_link, hub_root / "skills" / "project-takeover"):
            print("[SKIP] junction-based skill rejection requires junction creation")
        else:
            write_text(
                sandbox.locator_path,
                json.dumps(
                    {
                        "schema_version": 1,
                        "kind": "ai-skill-hub.canonical-hub-locator",
                        "hub_root": str(hub_root),
                    },
                    indent=2,
                )
                + "\n",
            )
            result, payload = run_resolver(sandbox, "resolve", "linked-skill")
            assert result.returncode == 2
            assert payload["resolutions"][0]["status"] == "INVALID"
            assert payload["resolutions"][0]["code"] == "CANONICAL_SKILL_PATH_INVALID"

        # A reparse point at the adapter destination is a preflight conflict
        # and still leaves Mutation=NONE everywhere.
        adapter_link_parent = sandbox.codex_home / "skills"
        adapter_link_parent.mkdir(parents=True, exist_ok=True)
        junction_target = root / "junction-target"
        if not make_junction(adapter_link_parent / "ai-skill-hub-router", junction_target):
            print("[SKIP] adapter reparse-point conflict requires junction creation")
            return
        result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED_ROUTER_CONFLICT"
        assert payload["mutation"] == "NONE"
        assert not sandbox.adapter_path("claude").exists()


def test_malformed_locator_json_fails_closed() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        sandbox = make_sandbox(root)
        write_text(sandbox.locator_path, "this is not json {\n")

        result, payload = run_resolver(sandbox, "resolve", "project-takeover")
        assert result.returncode == 2
        assert payload["locator_state"] == "INVALID"
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "LOCATOR_INVALID_JSON"


def test_relative_hub_root_fails_closed() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        sandbox = make_sandbox(root)

        result, payload = run_configure(sandbox, "--hub-root", "relative/hub")
        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED_HUB_INVALID"
        assert payload["mutation"] == "NONE"

        write_text(
            sandbox.locator_path,
            json.dumps(
                {
                    "schema_version": 1,
                    "kind": "ai-skill-hub.canonical-hub-locator",
                    "hub_root": "relative/hub",
                }
            )
            + "\n",
        )
        result, payload = run_resolver(sandbox, "resolve", "project-takeover")
        assert result.returncode == 2
        assert payload["locator_state"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "LOCATOR_HUB_ROOT_NOT_ABSOLUTE"


def test_frontmatter_identity_mismatch_fails_closed() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        write_skill(hub_root, "project-takeover", declared_name="renamed-elsewhere")
        result, payload = run_resolver(sandbox, "resolve", "project-takeover")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "CANONICAL_IDENTITY_INVALID"


def test_smoke_resolves_bundled_and_unbundled_canonical_skills() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        result, payload = run_resolver(
            sandbox,
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
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)

        result, payload = run_resolver(
            sandbox,
            "doctor",
            "--required-skill",
            "documentation-governance",
        )

        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED"
        assert payload["routing_gap"] is True
        assert payload["resolutions"][0]["status"] == "MISSING"

        write_skill(hub_root, "documentation-governance")
        result, payload = run_resolver(
            sandbox,
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
        sandbox = make_sandbox(root)

        result, payload = run_resolver(sandbox, "smoke", "--required-skill", "workflow-bootstrap")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "HUB_UNAVAILABLE"

        configure(sandbox, hub_root)
        result, payload = run_resolver(sandbox, "resolve", "not a skill")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "SKILL_ID_SYNTAX_INVALID"

        result, payload = run_resolver(sandbox, "resolve", "does-not-exist")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "MISSING"
        assert payload["resolutions"][0]["code"] == "CANONICAL_SKILL_MISSING"

        result, payload = run_resolver(sandbox, "resolve", "_protocol")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "SKILL_ID_SYNTAX_INVALID"


def test_invalid_hub_and_missing_canonical_entry_are_blocked() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        sandbox = make_sandbox(root)
        invalid_hub = root / "not-a-hub"
        invalid_hub.mkdir()
        write_text(
            sandbox.locator_path,
            json.dumps(
                {
                    "schema_version": 1,
                    "kind": "ai-skill-hub.canonical-hub-locator",
                    "hub_root": str(invalid_hub),
                }
            )
            + "\n",
        )
        result, payload = run_resolver(sandbox, "resolve", "workflow-bootstrap")
        assert result.returncode == 2
        assert payload["hub_state"] == "INVALID"
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "HUB_STRUCTURE_INVALID"

        hub_root = build_hub(root)
        write_text(
            sandbox.locator_path,
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
        result, payload = run_resolver(sandbox, "resolve", "project-takeover")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "MISSING"
        assert payload["resolutions"][0]["code"] == "CANONICAL_ENTRY_MISSING"


def test_dubious_hub_checkout_ownership_is_reported_explicitly() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        dubious_ownership = subprocess.CompletedProcess(
            args=["git"],
            returncode=128,
            stdout="",
            stderr=(
                "fatal: detected dubious ownership in repository at 'D:/canonical-hub'\n"
                "To add an exception for this directory, call: git config --global "
                "--add safe.directory D:/canonical-hub\n"
            ),
        )
        with patch.object(
            RESOLVER.subprocess,
            "run",
            side_effect=[dubious_ownership, dubious_ownership],
        ):
            hub_check = RESOLVER.check_hub(hub_root)

        assert hub_check.state == "INVALID"
        assert hub_check.code == "HUB_GIT_SAFE_DIRECTORY_UNTRUSTED"
        assert (
            RESOLVER.git_checkout_failure_code("fatal: unrelated git failure")
            == "HUB_CHECKOUT_INVALID"
        )


def test_unsupported_locator_schema_is_invalid_without_fallback() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        sandbox = make_sandbox(root)
        write_text(
            sandbox.locator_path,
            '{"schema_version": 2, "kind": "ai-skill-hub.canonical-hub-locator", "hub_root": "X:/invalid"}\n',
        )
        result, payload = run_resolver(sandbox, "resolve", "workflow-bootstrap")
        assert result.returncode == 2
        assert payload["locator_state"] == "INVALID"
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "LOCATOR_SCHEMA_UNSUPPORTED"


def test_competing_declared_canonical_identity_is_ambiguous_and_blocked() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)
        configure(sandbox, hub_root)
        write_skill(hub_root, "unexpected-copy", declared_name="project-takeover")

        result, payload = run_resolver(sandbox, "resolve", "project-takeover")
        assert result.returncode == 2
        assert payload["resolutions"][0]["status"] == "INVALID"
        assert payload["resolutions"][0]["code"] == "CANONICAL_IDENTITY_AMBIGUOUS"


def test_known_stale_router_shape_is_blocked_then_reconciled_by_documented_removal() -> None:
    """Sanctioned reconciliation path from docs/governance/stale_router_reconciliation_v1.md.

    The exact known stale router shape must still be blocked by configure with
    Mutation=NONE (the frozen contract is unchanged); only the documented
    maintainer removal step may transition the machine, after which the frozen
    configure converges and is idempotent.
    """
    assert hashlib.sha256(KNOWN_STALE_ROUTER_TEXT.encode("utf-8")).hexdigest() == (
        KNOWN_STALE_ROUTER_SHA256
    )
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)

        stale_adapter = sandbox.adapter_path("codex")
        write_text(stale_adapter, KNOWN_STALE_ROUTER_TEXT)

        result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED_ROUTER_CONFLICT"
        assert payload["overall"] == "BLOCKED"
        assert payload["mutation"] == "NONE"
        # Mutation=NONE is literal: no neutral locator and no other adapter.
        assert not sandbox.locator_path.exists()
        assert not sandbox.adapter_path("claude").exists()
        assert not sandbox.adapter_path("agents").exists()
        assert stale_adapter.read_text(encoding="utf-8") == KNOWN_STALE_ROUTER_TEXT

        # Documented maintainer step: remove exactly the verified stale file.
        stale_adapter.unlink()

        payload = configure(sandbox, hub_root)
        assert payload["mutation"] == "PERFORMED"
        assert stale_adapter.read_text(encoding="utf-8") != KNOWN_STALE_ROUTER_TEXT
        assert "~/.ai-skill-hub/locator.json" in stale_adapter.read_text(encoding="utf-8")
        assert "$CODEX_HOME" not in stale_adapter.read_text(encoding="utf-8")

        # Already-current state is idempotent.
        result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
        assert result.returncode == 0, result.stderr
        assert payload["decision"] == "NO_CHANGE_HUB_LOCATOR_CURRENT"
        assert payload["mutation"] == "NONE"


def test_known_stale_router_near_miss_still_fails_closed() -> None:
    """A one-character deviation from the known stale shape is unknown content:
    still BLOCKED_ROUTER_CONFLICT with Mutation=NONE, and it must never be
    treated as reconcilable."""
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        hub_root = build_hub(root)
        sandbox = make_sandbox(root)

        near_miss = KNOWN_STALE_ROUTER_TEXT.replace(
            "machine-level Hub locator", "machine level Hub locator", 1
        )
        assert near_miss != KNOWN_STALE_ROUTER_TEXT
        stale_adapter = sandbox.adapter_path("codex")
        write_text(stale_adapter, near_miss)

        result, payload = run_configure(sandbox, "--hub-root", str(hub_root))
        assert result.returncode == 2
        assert payload["decision"] == "BLOCKED_ROUTER_CONFLICT"
        assert payload["overall"] == "BLOCKED"
        assert payload["mutation"] == "NONE"
        assert not sandbox.locator_path.exists()
        assert not sandbox.adapter_path("claude").exists()
        assert not sandbox.adapter_path("agents").exists()
        assert stale_adapter.read_text(encoding="utf-8") == near_miss


def main() -> int:
    tests = [
        test_configure_creates_neutral_locator_and_all_thin_adapters,
        test_neutral_locator_config_home_env_override_and_codex_home_independence,
        test_codex_thin_adapter_routes_through_neutral_locator,
        test_claude_thin_adapter_routes_through_neutral_locator,
        test_generic_agents_adapter_routes_through_neutral_locator,
        test_configure_all_target_preflight_conflict_leaves_no_new_managed_state,
        test_configure_rejects_non_default_locator_path,
        test_zero_required_skills_fail_closed_unless_explicitly_intentional,
        test_reparse_point_locator_is_rejected,
        test_malformed_locator_json_fails_closed,
        test_relative_hub_root_fails_closed,
        test_frontmatter_identity_mismatch_fails_closed,
        test_smoke_resolves_bundled_and_unbundled_canonical_skills,
        test_doctor_reports_adopt_as_is_when_required_routing_is_complete,
        test_negative_resolution_fails_closed_for_invalid_missing_and_unavailable_states,
        test_invalid_hub_and_missing_canonical_entry_are_blocked,
        test_dubious_hub_checkout_ownership_is_reported_explicitly,
        test_unsupported_locator_schema_is_invalid_without_fallback,
        test_competing_declared_canonical_identity_is_ambiguous_and_blocked,
        test_known_stale_router_shape_is_blocked_then_reconciled_by_documented_removal,
        test_known_stale_router_near_miss_still_fails_closed,
    ]
    for test in tests:
        test()
        print(f"[PASS] {test.__name__}")
    print("AI-level canonical Skill resolver tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
