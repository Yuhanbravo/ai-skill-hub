"""Read-only canonical Skill resolution for AI-level Hub back references.

The resolver intentionally keeps the Consumer Project out of the lookup
contract.  An agent-neutral machine-local locator points to one Hub checkout,
and exact logical Skill IDs resolve only to canonical entries inside that
checkout.  Every supported local AI consumer (Codex, Claude Code, GitHub
Copilot, Kimi Code) shares the same neutral locator; each consumer discovers
the routing entry through its own native user-level Skill directory via a thin
adapter that carries no canonical payload.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


LOCATOR_SCHEMA_VERSION = 1
LOCATOR_KIND = "ai-skill-hub.canonical-hub-locator"
ROUTER_SKILL_NAME = "ai-skill-hub-router"
SKILL_ID_PATTERN = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")
NAME_PATTERN = re.compile(r"(?m)^name:\s*[\"']?([^\"'\r\n]+)[\"']?\s*$")
SAFE_DIRECTORY_REJECTION_PATTERN = re.compile(
    r"detected dubious ownership.*safe\.directory", re.IGNORECASE | re.DOTALL
)

CONFIG_HOME_ENV_VAR = "AI_SKILL_HUB_CONFIG_HOME"
AGENTS_HOME_ENV_VAR = "AI_SKILL_HUB_AGENTS_HOME"
CODEX_HOME_ENV_VAR = "CODEX_HOME"
CLAUDE_HOME_ENV_VAR = "CLAUDE_CONFIG_DIR"
PUBLIC_DEFAULT_LOCATOR = "~/.ai-skill-hub/locator.json"


@dataclass(frozen=True)
class HubCheck:
    state: str
    code: str


@dataclass(frozen=True)
class Resolution:
    skill_id: str
    status: str
    code: str
    canonical_entry: str | None = None


@dataclass(frozen=True)
class ManagedTarget:
    """One configure-managed destination inspected before any mutation."""

    target_id: str
    path: Path
    expected: str
    conflict_code: str
    public_path: str


class ConfigurationError(ValueError):
    """Raised when a machine-local configuration write would be unsafe."""


def is_reparse_point(path: Path) -> bool:
    """Return True for symlinks, junctions, and equivalent reparse points."""
    try:
        if path.is_symlink():
            return True
        attributes = path.lstat().st_file_attributes
    except (AttributeError, FileNotFoundError, OSError):
        return False
    return bool(attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT)


def resolve_machine_home(
    raw_value: str | None, env_var: str | None, default: Path, label: str
) -> Path:
    """Resolve one machine-level home directory, fail closed on relative input.

    Resolution order: explicit CLI value, then the environment override for
    tests / isolated environments, then the default derived from the current
    user's home.
    """
    value = raw_value
    if not value and env_var:
        value = os.environ.get(env_var)
    candidate = Path(value).expanduser() if value else default
    if not candidate.is_absolute():
        raise ConfigurationError(f"{label} must resolve to an absolute path.")
    return candidate


def get_config_home(raw_value: str | None) -> Path:
    """Agent-neutral configuration home; defaults to the current user's home."""
    return resolve_machine_home(raw_value, CONFIG_HOME_ENV_VAR, Path.home(), "Config home")


def get_codex_home(raw_value: str | None) -> Path:
    return resolve_machine_home(
        raw_value, CODEX_HOME_ENV_VAR, Path.home() / ".codex", "Codex home"
    )


def get_claude_home(raw_value: str | None) -> Path:
    return resolve_machine_home(
        raw_value, CLAUDE_HOME_ENV_VAR, Path.home() / ".claude", "Claude home"
    )


def get_agents_home(raw_value: str | None) -> Path:
    return resolve_machine_home(
        raw_value, AGENTS_HOME_ENV_VAR, Path.home() / ".agents", "Agents home"
    )


def default_locator_path(config_home: Path) -> Path:
    return config_home / ".ai-skill-hub" / "locator.json"


def default_router_path(skills_home: Path) -> Path:
    return skills_home / "skills" / ROUTER_SKILL_NAME / "SKILL.md"


def public_locator_path(locator_path: Path, config_home: Path) -> str:
    if locator_path == default_locator_path(config_home):
        return PUBLIC_DEFAULT_LOCATOR
    return "EXPLICIT_MACHINE_LOCATOR"


def public_adapter_path(path: Path, skills_home: Path, home_label: str) -> str:
    try:
        relative = path.relative_to(skills_home)
    except ValueError:
        return "EXPLICIT_MACHINE_PATH"
    return home_label + "/" + relative.as_posix()


def expected_locator_text(hub_root: Path) -> str:
    value = {
        "schema_version": LOCATOR_SCHEMA_VERSION,
        "kind": LOCATOR_KIND,
        "hub_root": str(hub_root),
    }
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def expected_router_text() -> str:
    """Keep the installed router a thin pointer, not a copied Skill payload.

    Codex user skills, Claude Code user skills, and the generic Agent Skills
    discovery surface all consume the same SKILL.md frontmatter + body
    contract, so one byte-identical thin adapter serves every V1 consumer;
    only the discovery root differs per agent.
    """
    return """---
name: ai-skill-hub-router
description: "Resolve logical ai-skill-hub Skill IDs through the agent-neutral machine-level Hub locator."
---

# AI Skill Hub Router

This is a machine-level thin routing adapter shared by the supported local
AI consumers. It does not contain canonical Skill payload and it does not
grant write, install, update, or fallback authority.

## Route

1. Read the machine-local locator at `~/.ai-skill-hub/locator.json`. Resolve
   `~` to the current user's home directory first (for example `echo $HOME`
   or `$env:USERPROFILE`); do not guess another user's profile path. When the
   environment sets `AI_SKILL_HUB_CONFIG_HOME` (reserved for tests and
   isolated environments), read `<that>/.ai-skill-hub/locator.json` instead.
2. Require locator schema `1` and kind `ai-skill-hub.canonical-hub-locator`.
3. From the located Hub checkout, use `tools/ai_skill_hub_resolver.py` with an
   exact logical Skill ID. Do not infer a physical Consumer Project path.
4. Accept only a `RESOLVED` result, then read the returned canonical
   `skills/<skill-id>/SKILL.md` completely.
5. If the locator, Hub, canonical identity, or entry is invalid or missing,
   stop and report the resolver result. Do not fall back to a project copy,
   Runtime Pack, Bundle payload, adapter, or model memory.

Use `doctor` or `smoke` in the resolver for a reusable required-Skill routing
check. The Consumer Project declares logical IDs only; the machine locator is
the only component that may store a local Hub checkout path.
"""


def build_managed_targets(
    hub_root: Path,
    config_home: Path,
    codex_home: Path,
    claude_home: Path,
    agents_home: Path,
) -> list[ManagedTarget]:
    """The complete V1 target set: one neutral locator plus one thin adapter
    per supported agent discovery surface, all sharing the same locator."""
    expected_router = expected_router_text()
    locator_path = default_locator_path(config_home)
    return [
        ManagedTarget(
            target_id="locator",
            path=locator_path,
            expected=expected_locator_text(hub_root),
            conflict_code="BLOCKED_LOCATOR_CONFLICT",
            public_path=public_locator_path(locator_path, config_home),
        ),
        ManagedTarget(
            target_id="codex_adapter",
            path=default_router_path(codex_home),
            expected=expected_router,
            conflict_code="BLOCKED_ROUTER_CONFLICT",
            public_path=public_adapter_path(
                default_router_path(codex_home), codex_home, "$CODEX_HOME"
            ),
        ),
        ManagedTarget(
            target_id="claude_adapter",
            path=default_router_path(claude_home),
            expected=expected_router,
            conflict_code="BLOCKED_ROUTER_CONFLICT",
            public_path=public_adapter_path(
                default_router_path(claude_home), claude_home, "$CLAUDE_HOME"
            ),
        ),
        ManagedTarget(
            target_id="agents_adapter",
            path=default_router_path(agents_home),
            expected=expected_router,
            conflict_code="BLOCKED_ROUTER_CONFLICT",
            public_path=public_adapter_path(
                default_router_path(agents_home), agents_home, "$AGENTS_HOME"
            ),
        ),
    ]


def read_locator(locator_path: Path) -> tuple[dict[str, Any] | None, str, str]:
    if not locator_path.is_file() or is_reparse_point(locator_path):
        return None, "MISSING", "LOCATOR_MISSING"
    try:
        parsed = json.loads(locator_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None, "INVALID", "LOCATOR_INVALID_JSON"
    if not isinstance(parsed, dict) or set(parsed) != {"schema_version", "kind", "hub_root"}:
        return None, "INVALID", "LOCATOR_SCHEMA_UNSUPPORTED"
    if (
        parsed["schema_version"] != LOCATOR_SCHEMA_VERSION
        or parsed["kind"] != LOCATOR_KIND
        or not isinstance(parsed["hub_root"], str)
        or not parsed["hub_root"].strip()
    ):
        return None, "INVALID", "LOCATOR_SCHEMA_UNSUPPORTED"
    hub_root = Path(parsed["hub_root"])
    if not hub_root.is_absolute():
        return None, "INVALID", "LOCATOR_HUB_ROOT_NOT_ABSOLUTE"
    return parsed, "VALID", "LOCATOR_VALID"


def git_checkout_failure_code(*stderr_values: str) -> str:
    if SAFE_DIRECTORY_REJECTION_PATTERN.search("\n".join(stderr_values)):
        return "HUB_GIT_SAFE_DIRECTORY_UNTRUSTED"
    return "HUB_CHECKOUT_INVALID"


def check_hub(hub_root: Path) -> HubCheck:
    if not hub_root.exists() or not hub_root.is_dir() or is_reparse_point(hub_root):
        return HubCheck("UNAVAILABLE", "HUB_CHECKOUT_UNAVAILABLE")

    skills_root = hub_root / "skills"
    if not skills_root.is_dir() or is_reparse_point(skills_root):
        return HubCheck("INVALID", "HUB_STRUCTURE_INVALID")

    try:
        top_level = subprocess.run(
            ["git", "-C", str(hub_root), "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
        bare = subprocess.run(
            ["git", "-C", str(hub_root), "rev-parse", "--is-bare-repository"],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
    except OSError:
        return HubCheck("UNAVAILABLE", "GIT_UNAVAILABLE")

    if top_level.returncode != 0 or bare.returncode != 0:
        return HubCheck(
            "INVALID", git_checkout_failure_code(top_level.stderr, bare.stderr)
        )
    if bare.stdout.strip().lower() == "true":
        return HubCheck("INVALID", "HUB_CHECKOUT_BARE")
    try:
        if Path(top_level.stdout.strip()).resolve() != hub_root.resolve():
            return HubCheck("INVALID", "HUB_ROOT_NOT_GIT_TOPLEVEL")
    except OSError:
        return HubCheck("UNAVAILABLE", "HUB_CHECKOUT_UNAVAILABLE")
    return HubCheck("VALID", "HUB_VALID")


def read_frontmatter_name(skill_file: Path) -> str | None:
    try:
        text = skill_file.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end == -1:
        return None
    match = NAME_PATTERN.search(text[4:end])
    return match.group(1).strip() if match else None


def has_competing_declared_name(hub_root: Path, skill_id: str, selected_dir: Path) -> bool:
    """Reject a second directory that claims the selected logical identity.

    A legal canonical entry has matching directory and frontmatter names, so a
    duplicate is not representable by a healthy checkout.  Inspecting for a
    conflicting declaration still makes a malformed or injected checkout fail
    closed instead of silently preferring the directory-shaped candidate.
    """
    try:
        entries = list((hub_root / "skills").iterdir())
    except OSError:
        return True
    for entry in entries:
        if entry == selected_dir or not entry.is_dir() or is_reparse_point(entry):
            continue
        skill_file = entry / "SKILL.md"
        if skill_file.is_file() and not is_reparse_point(skill_file):
            if read_frontmatter_name(skill_file) == skill_id:
                return True
    return False


def resolve_from_hub(hub_root: Path, skill_id: str) -> Resolution:
    if not SKILL_ID_PATTERN.fullmatch(skill_id):
        return Resolution(skill_id, "INVALID", "SKILL_ID_SYNTAX_INVALID")

    skill_dir = hub_root / "skills" / skill_id
    if not skill_dir.exists():
        return Resolution(skill_id, "MISSING", "CANONICAL_SKILL_MISSING")
    if not skill_dir.is_dir() or is_reparse_point(skill_dir):
        return Resolution(skill_id, "INVALID", "CANONICAL_SKILL_PATH_INVALID")
    if has_competing_declared_name(hub_root, skill_id, skill_dir):
        return Resolution(skill_id, "INVALID", "CANONICAL_IDENTITY_AMBIGUOUS")

    skill_file = skill_dir / "SKILL.md"
    if not skill_file.exists():
        return Resolution(skill_id, "MISSING", "CANONICAL_ENTRY_MISSING")
    if not skill_file.is_file() or is_reparse_point(skill_file):
        return Resolution(skill_id, "INVALID", "CANONICAL_ENTRY_INVALID")

    frontmatter_name = read_frontmatter_name(skill_file)
    if frontmatter_name != skill_id:
        return Resolution(skill_id, "INVALID", "CANONICAL_IDENTITY_INVALID")

    return Resolution(
        skill_id,
        "RESOLVED",
        "CANONICAL_ENTRY_RESOLVED",
        f"skills/{skill_id}/SKILL.md",
    )


def resolve_required_skills(
    locator_path: Path, required_skills: list[str]
) -> tuple[str, str, str, list[Resolution]]:
    locator, locator_state, locator_code = read_locator(locator_path)
    if locator is None:
        status = "HUB_UNAVAILABLE" if locator_state == "MISSING" else "INVALID"
        return locator_state, "UNKNOWN", locator_code, [
            Resolution(skill_id, status, locator_code) for skill_id in required_skills
        ]

    hub_check = check_hub(Path(locator["hub_root"]))
    if hub_check.state != "VALID":
        status = "HUB_UNAVAILABLE" if hub_check.state == "UNAVAILABLE" else "INVALID"
        return locator_state, hub_check.state, hub_check.code, [
            Resolution(skill_id, status, hub_check.code) for skill_id in required_skills
        ]

    hub_root = Path(locator["hub_root"])
    return (
        locator_state,
        hub_check.state,
        hub_check.code,
        [resolve_from_hub(hub_root, skill_id) for skill_id in required_skills],
    )


def summarize(
    operation: str,
    locator_path: Path,
    config_home: Path,
    locator_state: str,
    hub_state: str,
    required_skills: list[str],
    resolutions: list[Resolution],
    *,
    decision: str | None = None,
    overall: str | None = None,
    message: str = "",
    mutation: str = "NONE",
    managed_targets: list[dict[str, str]] | None = None,
    requirements_declared: bool | None = None,
    zero_requirements_intentional: bool = False,
) -> dict[str, Any]:
    if overall is None:
        overall = "PASS" if all(item.status == "RESOLVED" for item in resolutions) else "BLOCKED"
    if decision is None:
        if operation == "doctor":
            decision = "ADOPT_AS_IS" if overall == "PASS" else "BLOCKED"
        elif operation == "resolve":
            decision = "RESOLVED" if overall == "PASS" else "BLOCKED"
        else:
            decision = (
                "PASS_REQUIRED_SKILL_ROUTING_SMOKE"
                if overall == "PASS"
                else "BLOCKED_REQUIRED_SKILL_ROUTING_SMOKE"
            )
    if requirements_declared is None:
        requirements_declared = bool(required_skills)
    return {
        "decision": decision,
        "operation": operation,
        "locator_state": locator_state,
        "hub_state": hub_state,
        "locator_path": public_locator_path(locator_path, config_home),
        "required_skills": required_skills,
        "requirements_declared": requirements_declared,
        "zero_requirements_intentional": zero_requirements_intentional,
        "resolutions": [asdict(item) for item in resolutions],
        "overall": overall,
        "routing_gap": overall != "PASS",
        "mutation": mutation,
        "managed_targets": managed_targets or [],
        "message": message,
    }


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    for ancestor in (path.parent, *path.parents):
        if ancestor.exists() and is_reparse_point(ancestor):
            raise ConfigurationError("A machine configuration parent is a reparse point.")
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", newline="\n", dir=path.parent, delete=False
    ) as stream:
        stream.write(content)
        temporary_path = Path(stream.name)
    try:
        os.replace(temporary_path, path)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def inspect_managed_text(target: ManagedTarget) -> bool:
    """Read-only preflight of one managed destination.

    Returns True when a write is required.  Raises ConfigurationError on any
    unknown or conflicting existing content, or when an existing ancestor of
    the destination is a reparse point.  This function never writes.
    """
    path = target.path
    if path.exists() or path.is_symlink():
        if not path.is_file() or is_reparse_point(path):
            raise ConfigurationError(target.conflict_code)
        try:
            if path.read_text(encoding="utf-8") == target.expected:
                return False
        except (OSError, UnicodeDecodeError) as exc:
            raise ConfigurationError(target.conflict_code) from exc
        raise ConfigurationError(target.conflict_code)
    for ancestor in path.parents:
        if ancestor.exists() and is_reparse_point(ancestor):
            raise ConfigurationError(target.conflict_code)
    return True


def configure(
    args: argparse.Namespace,
    config_home: Path,
    codex_home: Path,
    claude_home: Path,
    agents_home: Path,
    locator_path: Path,
) -> dict[str, Any]:
    if locator_path != default_locator_path(config_home):
        return summarize(
            "configure", locator_path, config_home, "INVALID", "UNKNOWN", [], [],
            decision="BLOCKED_LOCATOR_PATH_UNSUPPORTED", overall="BLOCKED",
            message="Configure uses the fixed agent-neutral locator path so every thin router stays valid.",
        )
    hub_root = Path(args.hub_root).expanduser()
    if not hub_root.is_absolute():
        return summarize(
            "configure", locator_path, config_home, "INVALID", "UNKNOWN", [], [],
            decision="BLOCKED_HUB_INVALID", overall="BLOCKED",
            message="Hub root must be an absolute machine-local path.",
        )
    hub_root = Path(os.path.abspath(hub_root))
    hub_check = check_hub(hub_root)
    if hub_check.state != "VALID":
        return summarize(
            "configure", locator_path, config_home, "INVALID", hub_check.state, [], [],
            decision="BLOCKED_HUB_INVALID", overall="BLOCKED", message=hub_check.code,
        )

    targets = build_managed_targets(hub_root, config_home, codex_home, claude_home, agents_home)

    # Phase 1: read-only preflight of the locator destination and ALL adapter
    # destinations.  Any unknown or conflicting existing content blocks the
    # whole configure run before a single write happens.
    pending: list[tuple[ManagedTarget, bool]] = []
    try:
        for target in targets:
            pending.append((target, inspect_managed_text(target)))
    except ConfigurationError as exc:
        return summarize(
            "configure", locator_path, config_home, "INVALID", "VALID", [], [],
            decision=str(exc), overall="BLOCKED", mutation="NONE",
            managed_targets=[
                {"target": target.target_id, "path": target.public_path, "action": "inspected"}
                for target in targets
            ],
            message=f"Existing machine routing state differs from the expected thin adapter at target '{target.target_id}' ({target.public_path}). Mutation=NONE.",
        )

    # Phase 2: only after every destination passed preflight, write the
    # destinations that actually need changes.  Each file write remains
    # temp-file + atomic replace.
    actions: list[dict[str, str]] = []
    changed = False
    for target, needs_write in pending:
        if needs_write:
            write_atomic(target.path, target.expected)
            changed = True
            actions.append({"target": target.target_id, "path": target.public_path, "action": "written"})
        else:
            actions.append({"target": target.target_id, "path": target.public_path, "action": "current"})

    return summarize(
        "configure", locator_path, config_home, "VALID", "VALID", [], [],
        decision="PASS_HUB_LOCATOR_CONFIGURED" if changed else "NO_CHANGE_HUB_LOCATOR_CURRENT",
        overall="PASS", mutation="PERFORMED" if changed else "NONE",
        managed_targets=actions,
        message="Agent-neutral locator and thin routers are ready." if changed else "All managed routing state is already current.",
    )


def print_report(report: dict[str, Any], output_format: str) -> None:
    if output_format == "json":
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return
    print(f"Decision={report['decision']}")
    print(f"Operation={report['operation']}")
    print(f"Locator_State={report['locator_state']}")
    print(f"Hub_State={report['hub_state']}")
    print(f"Locator_Path={report['locator_path']}")
    print("Required_Skills=" + ",".join(report["required_skills"]))
    print("Requirements_Declared=" + ("YES" if report["requirements_declared"] else "NO"))
    print("Zero_Requirements_Intentional=" + ("YES" if report["zero_requirements_intentional"] else "NO"))
    for resolution in report["resolutions"]:
        entry = resolution["canonical_entry"] or ""
        print(
            "Skill_Result={skill_id}|{status}|{code}|{entry}".format(
                skill_id=resolution["skill_id"],
                status=resolution["status"],
                code=resolution["code"],
                entry=entry,
            )
        )
    for target in report["managed_targets"]:
        print(
            "Managed_Target={target}|{action}|{path}".format(
                target=target["target"], action=target["action"], path=target["path"]
            )
        )
    print(f"Overall={report['overall']}")
    print(f"Mutation={report['mutation']}")
    print("Routing_Gap=" + ("YES" if report["routing_gap"] else "NO"))
    print(f"Message={report['message']}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Resolve logical canonical Skill IDs through an agent-neutral machine-level Hub locator."
    )
    subparsers = parser.add_subparsers(dest="operation", required=True)

    for operation in ("resolve", "smoke", "doctor"):
        child = subparsers.add_parser(operation)
        child.add_argument(
            "--config-home",
            help=f"Agent-neutral configuration home; defaults to {CONFIG_HOME_ENV_VAR} or the current user's home.",
        )
        child.add_argument("--locator", help="Explicit machine-level locator path for read-only inspection.")
        child.add_argument("--output-format", choices=("text", "json"), default="text")
        if operation == "resolve":
            child.add_argument("skill_id", help="Exact logical canonical Skill ID.")
        else:
            child.add_argument(
                "--required-skill",
                dest="required_skills",
                action="append",
                default=[],
                help="Required logical Skill ID; repeat for each requirement.",
            )
            child.add_argument(
                "--allow-empty-requirements",
                action="store_true",
                help="Explicitly confirm that requiring zero skills is intentional; without it, an empty requirement set fails closed.",
            )

    configure_parser = subparsers.add_parser("configure")
    configure_parser.add_argument("--hub-root", required=True, help="Absolute path to the local Hub checkout.")
    configure_parser.add_argument(
        "--config-home",
        help=f"Agent-neutral configuration home; defaults to {CONFIG_HOME_ENV_VAR} or the current user's home.",
    )
    configure_parser.add_argument("--codex-home", help="Codex user home; defaults to CODEX_HOME or ~/.codex.")
    configure_parser.add_argument("--claude-home", help=f"Claude user home; defaults to {CLAUDE_HOME_ENV_VAR} or ~/.claude.")
    configure_parser.add_argument("--agents-home", help=f"Generic Agent Skills user home; defaults to {AGENTS_HOME_ENV_VAR} or ~/.agents.")
    configure_parser.add_argument("--locator", help="Explicit machine-level locator path to create or verify.")
    configure_parser.add_argument("--output-format", choices=("text", "json"), default="text")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        config_home = get_config_home(args.config_home)
    except ConfigurationError as exc:
        print(f"Decision=BLOCKED_CONFIG_HOME_INVALID\nMessage={exc}")
        return 2

    locator_path = Path(args.locator).expanduser() if args.locator else default_locator_path(config_home)
    if not locator_path.is_absolute():
        print("Decision=BLOCKED_LOCATOR_INVALID\nMessage=Locator path must be absolute.")
        return 2

    if args.operation == "configure":
        try:
            codex_home = get_codex_home(args.codex_home)
            claude_home = get_claude_home(args.claude_home)
            agents_home = get_agents_home(args.agents_home)
        except ConfigurationError as exc:
            print(f"Decision=BLOCKED_ADAPTER_HOME_INVALID\nMessage={exc}")
            return 2
        report = configure(args, config_home, codex_home, claude_home, agents_home, locator_path)
    else:
        required_skills = [args.skill_id] if args.operation == "resolve" else list(args.required_skills)
        if not required_skills and not getattr(args, "allow_empty_requirements", False):
            report = summarize(
                args.operation,
                locator_path,
                config_home,
                "UNKNOWN",
                "UNKNOWN",
                required_skills,
                [],
                decision="INSUFFICIENT_REQUIREMENTS",
                overall="BLOCKED",
                requirements_declared=False,
                zero_requirements_intentional=False,
                message=(
                    "No required skills declared; an empty requirement set is not evidence of "
                    "routing health and automation must not treat it as migration-safe. Declare "
                    "--required-skill for each requirement, or rerun with --allow-empty-requirements "
                    "only when requiring zero skills is intentional."
                ),
            )
        else:
            locator_state, hub_state, hub_code, resolutions = resolve_required_skills(locator_path, required_skills)
            zero_intentional = not required_skills
            message = hub_code
            if zero_intentional:
                message = (
                    "Zero required skills declared; the caller explicitly confirmed this is intentional. "
                    + hub_code
                )
            report = summarize(
                args.operation,
                locator_path,
                config_home,
                locator_state,
                hub_state,
                required_skills,
                resolutions,
                message=message,
                requirements_declared=bool(required_skills),
                zero_requirements_intentional=zero_intentional,
            )

    print_report(report, args.output_format)
    return 0 if report["overall"] == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
