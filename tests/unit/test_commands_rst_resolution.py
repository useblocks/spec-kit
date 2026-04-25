"""Verify command prompt resolution respects project format."""
from __future__ import annotations

from pathlib import Path

import pytest

pytestmark = pytest.mark.skip(reason="commands-rst directory authored in Task 11")

from specify_cli.presets import PresetResolver


@pytest.fixture(autouse=True)
def _clear_format_cache():
    from specify_cli.project_format import _get_project_format_cached
    _get_project_format_cached.cache_clear()
    yield
    _get_project_format_cached.cache_clear()


# Name used in tests 1 and 2 — must also exist in the repo's commands-rst/ so
# that priority-5 resolution works (Task 11 ships this file).
_SHARED_CMD = "specify"

# Name used in test 3 — must NOT exist in the repo's commands/ or commands-rst/
# so the test can verify the project-local fallback without hitting priority 5.
_LOCAL_ONLY_CMD = "test-local-only-xq9z"


def _make_layout(root: Path, variants: list[str], cmd: str = _SHARED_CMD) -> None:
    md = root / ".specify" / "templates" / "commands"
    rst = root / ".specify" / "templates" / "commands-rst"
    md.mkdir(parents=True, exist_ok=True)
    rst.mkdir(parents=True, exist_ok=True)
    if "md" in variants:
        (md / f"{cmd}.md").write_text("md-specify", encoding="utf-8")
    if "rst" in variants:
        (rst / f"{cmd}.md").write_text("rst-specify", encoding="utf-8")


def test_rst_format_picks_commands_rst(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    _make_layout(tmp_path, ["md", "rst"])
    (tmp_path / ".specify" / "config.toml").write_text('format = "rst"\n', encoding="utf-8")
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)

    resolver = PresetResolver(project_root=tmp_path)
    result = resolver.resolve(_SHARED_CMD, "command")
    assert result is not None
    assert result.parent.name == "commands-rst"
    assert result.read_text(encoding="utf-8") == "rst-specify"


def test_md_format_picks_commands(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    _make_layout(tmp_path, ["md", "rst"])
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)

    resolver = PresetResolver(project_root=tmp_path)
    result = resolver.resolve(_SHARED_CMD, "command")
    assert result is not None
    assert result.parent.name == "commands"
    assert result.read_text(encoding="utf-8") == "md-specify"


def test_rst_falls_back_to_md_commands_when_rst_missing(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
) -> None:
    # Use a project-local-only name so priority-5 (repo root) doesn't interfere.
    _make_layout(tmp_path, ["md"], cmd=_LOCAL_ONLY_CMD)
    (tmp_path / ".specify" / "config.toml").write_text('format = "rst"\n', encoding="utf-8")
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)

    resolver = PresetResolver(project_root=tmp_path)
    result = resolver.resolve(_LOCAL_ONLY_CMD, "command")
    assert result is not None
    assert result.parent.name == "commands"
    assert result.read_text(encoding="utf-8") == "md-specify"
