"""Verify specify init --format rst installs V-model prompts in agent skill dirs."""
from __future__ import annotations

import subprocess
from pathlib import Path

import pytest


def _run_specify_init(tmp_path: Path, fmt: str) -> None:
    """Run specify init --here --format <fmt> in tmp_path."""
    project_dir = tmp_path / "proj"
    project_dir.mkdir()
    subprocess.run(["git", "init", "-q"], cwd=project_dir, check=True)
    subprocess.run(
        ["git", "remote", "add", "origin", "https://github.com/useblocks/spec-kit.git"],
        cwd=project_dir, check=True,
    )
    spec_kit_root = Path(__file__).resolve().parents[2]
    result = subprocess.run(
        [
            "uv", "run", "--project", str(spec_kit_root),
            "specify", "init", "--here",
            "--ai", "claude",
            "--no-git", "--ignore-agent-tools",
            "--format", fmt, "--force",
        ],
        cwd=project_dir,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, f"init failed: {result.stderr}"


def test_init_rst_installs_vmodel_specify_prompt(tmp_path: Path) -> None:
    """init --format rst must install commands-rst/specify.md as the speckit-specify skill."""
    _run_specify_init(tmp_path, "rst")
    skill = tmp_path / "proj" / ".claude" / "skills" / "speckit-specify" / "SKILL.md"
    assert skill.is_file(), "speckit-specify SKILL.md missing"
    body = skill.read_text(encoding="utf-8")
    # V-model markers (drawn from templates/commands-rst/specify.md content)
    assert "user_story" in body, "V-model user_story directive missing — MD prompt installed"
    assert "sphinx-build" in body, "V-model self-validation step missing"
    # Source frontmatter should reflect the rst variant
    assert "templates/commands-rst/" in body, "source: frontmatter still points at templates/commands/"


def test_init_md_installs_md_specify_prompt(tmp_path: Path) -> None:
    """init --format md (default) must install commands/specify.md unchanged."""
    _run_specify_init(tmp_path, "md")
    skill = tmp_path / "proj" / ".claude" / "skills" / "speckit-specify" / "SKILL.md"
    assert skill.is_file()
    body = skill.read_text(encoding="utf-8")
    # MD prompt should NOT contain V-model markers
    assert "user_story" not in body, "V-model directive leaked into MD-mode install"
    assert "templates/commands/" in body, "source: frontmatter wrong"
    assert "templates/commands-rst/" not in body
