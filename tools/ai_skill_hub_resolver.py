"""Read-only canonical Skill resolution for AI-level Hub back references.

The resolver intentionally keeps the Consumer Project out of the lookup
contract.  A machine-local locator points to one Hub checkout, and exact
logical Skill IDs resolve only to canonical entries inside that checkout.
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


def get_codex_home(raw_value: str | None) -> Path:
    value = raw_value or os.environ.get("CODEX_HOME")
    if not value:
        value = str(Path.home() / ".codex")
    candidate = Path(value).expanduser()
    if not candidate.is_absolute():
        raise ConfigurationError("CODEX_HOME must resolve to an absolute path.")
    return candidate


def default_locator_path(codex_home: Path) -> Path:
    return codex_home / "ai-skill-hub" / "locator.json"


def default_router_path(codex_home: Path) -> Path:
    return codex_home / "skills" / ROUTER_SKILL_NAME / "SKILL.md"


def public_locator_path(locator_path: Path, codex_home: Path) -> str:
    try:
        relative = locator_path.relative_to(codex_home)
    except ValueError:
        return "EXPLICIT_MACHINE_LOCATOR"
    return "$CODEX_HOME/" + relative.as_posix()


def expected_locator_text(hub_root: Path) -> str:
    value = {
        "schema_version": LOCATOR_SCHEMA_VERSION,
        "kind": LOCATOR_KIND,
        "hub_root": str(hub_root),
    }
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def expected_router_text() -> str:
    """Keep the installed router a thin pointer, not a copied Skill payload."""
    return """---
name: ai-skill-hub-router
description: "Resolve logical ai-skill-hub Skill IDs through the machine-level Hub locator."
---

# AI Skill Hub Router

This is a machine-level thin routing adapter. It does not contain canonical
Skill payload and it does not grant write, install, update, or fallback
authority.

## Route

1. Read the machine-local locator at `$CODEX_HOME/ai-skill-hub/locator.json`.
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
        return HubCheck("INVALID", "HUB_CHECKOUT_INVALID")
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
    codex_home: Path,
    locator_state: str,
    hub_state: str,
    required_skills: list[str],
    resolutions: list[Resolution],
    *,
    decision: str | None = None,
    message: str = "",
) -> dict[str, Any]:
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
    return {
        "decision": decision,
        "operation": operation,
        "locator_state": locator_state,
        "hub_state": hub_state,
        "locator_path": public_locator_path(locator_path, codex_home),
        "required_skills": required_skills,
        "resolutions": [asdict(item) for item in resolutions],
        "overall": overall,
        "routing_gap": overall != "PASS",
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


def ensure_managed_text(path: Path, expected: str, conflict_code: str) -> bool:
    if path.exists() or path.is_symlink():
        if not path.is_file() or is_reparse_point(path):
            raise ConfigurationError(conflict_code)
        try:
            if path.read_text(encoding="utf-8") == expected:
                return False
        except (OSError, UnicodeDecodeError) as exc:
            raise ConfigurationError(conflict_code) from exc
        raise ConfigurationError(conflict_code)
    write_atomic(path, expected)
    return True


def configure(args: argparse.Namespace, codex_home: Path, locator_path: Path) -> dict[str, Any]:
    if locator_path != default_locator_path(codex_home):
        return summarize(
            "configure", locator_path, codex_home, "INVALID", "UNKNOWN", [], [],
            decision="BLOCKED_LOCATOR_PATH_UNSUPPORTED",
            message="Configure uses the fixed machine-level locator path so the thin router remains valid.",
        )
    hub_root = Path(args.hub_root).expanduser()
    if not hub_root.is_absolute():
        return summarize(
            "configure", locator_path, codex_home, "INVALID", "UNKNOWN", [], [],
            decision="BLOCKED_HUB_INVALID", message="Hub root must be an absolute machine-local path."
        )
    hub_root = Path(os.path.abspath(hub_root))
    hub_check = check_hub(hub_root)
    if hub_check.state != "VALID":
        return summarize(
            "configure", locator_path, codex_home, "INVALID", hub_check.state, [], [],
            decision="BLOCKED_HUB_INVALID", message=hub_check.code
        )

    router_path = default_router_path(codex_home)
    expected_locator = expected_locator_text(hub_root)
    expected_router = expected_router_text()
    try:
        changed = ensure_managed_text(locator_path, expected_locator, "BLOCKED_LOCATOR_CONFLICT")
        changed = ensure_managed_text(router_path, expected_router, "BLOCKED_ROUTER_CONFLICT") or changed
    except ConfigurationError as exc:
        return summarize(
            "configure", locator_path, codex_home, "INVALID", "VALID", [], [],
            decision=str(exc), message="Existing machine routing state differs from the expected thin adapter."
        )
    return summarize(
        "configure", locator_path, codex_home, "VALID", "VALID", [], [],
        decision="PASS_HUB_LOCATOR_CONFIGURED" if changed else "NO_CHANGE_HUB_LOCATOR_CURRENT",
        message="Machine-level locator and thin router are ready.",
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
    print(f"Overall={report['overall']}")
    print("Routing_Gap=" + ("YES" if report["routing_gap"] else "NO"))
    print(f"Message={report['message']}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Resolve logical canonical Skill IDs through a machine-level Hub locator."
    )
    subparsers = parser.add_subparsers(dest="operation", required=True)

    for operation in ("resolve", "smoke", "doctor"):
        child = subparsers.add_parser(operation)
        child.add_argument("--codex-home", help="Machine-level Codex home; defaults to CODEX_HOME or ~/.codex.")
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

    configure_parser = subparsers.add_parser("configure")
    configure_parser.add_argument("--hub-root", required=True, help="Absolute path to the local Hub checkout.")
    configure_parser.add_argument("--codex-home", help="Machine-level Codex home; defaults to CODEX_HOME or ~/.codex.")
    configure_parser.add_argument("--locator", help="Explicit machine-level locator path to create or verify.")
    configure_parser.add_argument("--output-format", choices=("text", "json"), default="text")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        codex_home = get_codex_home(args.codex_home)
    except ConfigurationError as exc:
        print(f"Decision=BLOCKED_CODEX_HOME_INVALID\nMessage={exc}")
        return 2

    locator_path = Path(args.locator).expanduser() if args.locator else default_locator_path(codex_home)
    if not locator_path.is_absolute():
        print("Decision=BLOCKED_LOCATOR_INVALID\nMessage=Locator path must be absolute.")
        return 2

    if args.operation == "configure":
        report = configure(args, codex_home, locator_path)
    else:
        required_skills = [args.skill_id] if args.operation == "resolve" else list(args.required_skills)
        locator_state, hub_state, hub_code, resolutions = resolve_required_skills(locator_path, required_skills)
        report = summarize(
            args.operation,
            locator_path,
            codex_home,
            locator_state,
            hub_state,
            required_skills,
            resolutions,
            message=hub_code,
        )

    print_report(report, args.output_format)
    return 0 if report["overall"] == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
