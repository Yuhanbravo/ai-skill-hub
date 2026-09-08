from __future__ import annotations

import importlib.util
import json
import re
import tempfile
from pathlib import Path
from types import ModuleType


ROOT = Path(__file__).resolve().parents[1]
GENERATOR_PATH = ROOT / "tools" / "generate_skill_metadata.py"
ADAPTER_CHECK_PATH = ROOT / "tools" / "check_adapter_consistency.py"
LOCAL_TMP_ROOT = ROOT / ".tmp" / "test_skill_inventory_consistency"


def load_module(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load module: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def extract_section(text: str, heading: str) -> str:
    pattern = re.compile(
        rf"^## {re.escape(heading)}\s*$\n(.*?)(?=^##\s|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        raise AssertionError(f"missing markdown section: {heading}")
    return match.group(1)


def canonical_inventory(generator: ModuleType) -> tuple[set[str], list[str]]:
    skill_ids: set[str] = set()
    failures: list[str] = []

    for skill_dir in sorted(generator.SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir() or skill_dir.name.startswith("_"):
            continue

        skill_file = skill_dir / "SKILL.md"
        if not skill_file.is_file():
            continue

        try:
            frontmatter = generator.read_frontmatter(skill_file)
        except ValueError as exc:
            failures.append(f"canonical frontmatter invalid: {exc}")
            continue

        frontmatter_name = str(frontmatter.get("name", "")).strip()
        if frontmatter_name != skill_dir.name:
            failures.append(
                "canonical identity mismatch: "
                f"directory={skill_dir.name!r}, frontmatter name={frontmatter_name!r}"
            )
            continue

        skill_ids.add(skill_dir.name)

    return skill_ids, failures


def list_agents_flat_entries() -> set[str]:
    excluded = {"README.md", "skills_index.md"}
    return {
        entry.stem
        for entry in (ROOT / ".agents" / "skills").glob("*.md")
        if entry.name not in excluded
    }


def parse_backtick_bullets_text(text: str, heading: str) -> set[str]:
    section = extract_section(text, heading)
    return set(
        re.findall(
            r"^[ \t]*-[ \t]+`([a-z0-9][a-z0-9-]*)`[ \t]*$",
            section,
            re.MULTILINE,
        )
    )


def parse_backtick_bullets(path: Path, heading: str) -> set[str]:
    return parse_backtick_bullets_text(path.read_text(encoding="utf-8"), heading)


def parse_canonical_paths(path: Path, heading: str) -> set[str]:
    section = extract_section(path.read_text(encoding="utf-8"), heading)
    return set(re.findall(r"`skills/([a-z0-9][a-z0-9-]*)/`", section))


def parse_catalog_inventory_text(text: str, heading: str) -> set[str]:
    section = extract_section(text, heading)
    return set(
        re.findall(
            r"^\|[ \t]*`skills/([a-z0-9][a-z0-9-]*)/`[ \t]*\|",
            section,
            re.MULTILINE,
        )
    )


def parse_catalog_inventory(path: Path, heading: str) -> set[str]:
    return parse_catalog_inventory_text(path.read_text(encoding="utf-8"), heading)


def parse_agents_mirror_index() -> set[str]:
    text = (ROOT / ".agents" / "skills" / "skills_index.md").read_text(encoding="utf-8")
    return set(re.findall(r"`\.\./\.\./skills/([a-z0-9][a-z0-9-]*)/`", text))


def parse_json_inventory() -> set[str]:
    entries = json.loads((ROOT / "skills_index.json").read_text(encoding="utf-8"))
    return {str(entry["name"]) for entry in entries}


def compare_inventory(
    label: str,
    canonical: set[str],
    actual: set[str],
    failures: list[str],
) -> None:
    missing = sorted(canonical - actual)
    orphan = sorted(actual - canonical)
    if missing or orphan:
        failures.append(f"{label}: missing={missing or 'none'}, orphan={orphan or 'none'}")


def test_catalog_primary_row_is_required(canonical: set[str]) -> None:
    catalog_text = (ROOT / "docs" / "SKILL_CATALOG.md").read_text(encoding="utf-8")
    catalog_without_primary_row, removed_count = re.subn(
        r"^\|[ \t]*`skills/workflow-bootstrap/`[ \t]*\|.*(?:\n|\Z)",
        "",
        catalog_text,
        count=1,
        flags=re.MULTILINE,
    )
    if removed_count != 1:
        raise AssertionError("catalog regression fixture could not remove workflow-bootstrap primary row")
    if "workflow-bootstrap" not in catalog_without_primary_row:
        raise AssertionError("catalog regression fixture must retain an auxiliary workflow-bootstrap reference")

    parsed = parse_catalog_inventory_text(catalog_without_primary_row, "Skill Index")
    regression_failures: list[str] = []
    compare_inventory("Skill_Catalog_Count", canonical, parsed, regression_failures)
    if not any("workflow-bootstrap" in failure for failure in regression_failures):
        raise AssertionError(
            "catalog parser must report workflow-bootstrap missing when only auxiliary references remain"
        )


def test_readme_inventory_allows_additional_list_whitespace(canonical: set[str]) -> None:
    readme_text = (ROOT / "README.md").read_text(encoding="utf-8")
    readme_with_two_spaces, replacement_count = re.subn(
        r"(?m)^- (`[a-z0-9][a-z0-9-]*`)[ \t]*$",
        r"-  \1",
        readme_text,
    )
    if replacement_count == 0:
        raise AssertionError("README regression fixture did not change any inventory list markers")

    parsed = parse_backtick_bullets_text(readme_with_two_spaces, "当前包含的 Skills")
    if parsed != canonical:
        raise AssertionError(
            "README parser must preserve inventory identity with two spaces after the list marker: "
            f"missing={sorted(canonical - parsed) or 'none'}, "
            f"orphan={sorted(parsed - canonical) or 'none'}"
        )


def compare_generated_outputs(
    generator: ModuleType,
    canonical: set[str],
    failures: list[str],
) -> None:
    LOCAL_TMP_ROOT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=LOCAL_TMP_ROOT) as temporary_directory:
        temp_root = Path(temporary_directory)
        generator.OUTPUT_JSON = temp_root / "skills_index.json"
        generator.AGENTS_DIR = temp_root / "agents"

        result = generator.main()
        if result != 0:
            failures.append(f"fresh metadata generation failed with exit code {result}")
            return

        committed_json = (ROOT / "skills_index.json").read_text(encoding="utf-8")
        generated_json = generator.OUTPUT_JSON.read_text(encoding="utf-8")
        if committed_json != generated_json:
            failures.append("skills_index.json differs from fresh generation")

        stale_flat_summaries = sorted(
            skill_id
            for skill_id in canonical
            if (ROOT / ".agents" / "skills" / f"{skill_id}.md").read_text(encoding="utf-8")
            != (generator.AGENTS_DIR / f"{skill_id}.md").read_text(encoding="utf-8")
        )
        if stale_flat_summaries:
            failures.append(
                ".agents flat summaries differ from fresh generation: "
                f"{stale_flat_summaries}"
            )


def main() -> int:
    generator = load_module("generate_skill_metadata", GENERATOR_PATH)
    adapter_check = load_module("check_adapter_consistency", ADAPTER_CHECK_PATH)
    canonical, failures = canonical_inventory(generator)

    test_catalog_primary_row_is_required(canonical)
    print("Catalog_Missing_Primary_Row_Regression=PASS missing=workflow-bootstrap")
    test_readme_inventory_allows_additional_list_whitespace(canonical)
    print("README_Whitespace_Regression=PASS spacing=two-spaces")

    surfaces = {
        "Agents_Directory_Count": adapter_check.list_agents_entries(ROOT),
        "Agents_Flat_Count": list_agents_flat_entries(),
        "Agents_Mirror_Index_Count": parse_agents_mirror_index(),
        "Github_Count": adapter_check.list_github_entries(ROOT),
        "Skills_Index_JSON_Count": parse_json_inventory(),
        "Skills_Index_MD_Count": parse_canonical_paths(ROOT / "SKILLS_INDEX.md", "Skill Catalog"),
        "README_Count": parse_backtick_bullets(ROOT / "README.md", "当前包含的 Skills"),
        "Skill_Catalog_Count": parse_catalog_inventory(
            ROOT / "docs" / "SKILL_CATALOG.md", "Skill Index"
        ),
    }

    for label, actual in surfaces.items():
        compare_inventory(label, canonical, actual, failures)

    compare_generated_outputs(generator, canonical, failures)

    print(f"Canonical_Count={len(canonical)}")
    for label, inventory in surfaces.items():
        print(f"{label}={len(inventory)}")

    if failures:
        print("fail list:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("Skill inventory consistency validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
