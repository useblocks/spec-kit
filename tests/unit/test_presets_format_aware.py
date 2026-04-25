"""Verify the preset resolver respects get_project_format."""
from __future__ import annotations

from pathlib import Path

import pytest

# Use a unique template name so Priority 5 (repo-root fallback) cannot
# accidentally find a real shipped template like spec-template.{md,rst}.
TEMPLATE_NAME = "test-fmt-fixture-tpl-xq9z"


@pytest.fixture(autouse=True)
def _clear_format_cache():
    from specify_cli.project_format import _get_project_format_cached
    _get_project_format_cached.cache_clear()
    yield
    _get_project_format_cached.cache_clear()


def _make_layout(root: Path, ext_variants: list[str]) -> None:
    (root / ".specify" / "templates").mkdir(parents=True)
    for e in ext_variants:
        (root / ".specify" / "templates" / f"{TEMPLATE_NAME}.{e}").write_text(
            f"{e}-body", encoding="utf-8",
        )


def _get_resolver_class():
    """Import the resolver class — name may be PresetResolver or TemplateResolver."""
    from specify_cli import presets

    for name in ("PresetResolver", "TemplateResolver", "CoreTemplateResolver"):
        cls = getattr(presets, name, None)
        if cls is not None and hasattr(cls, "resolve"):
            return cls
    raise RuntimeError("Could not find resolver class in specify_cli.presets")


def test_resolver_prefers_rst_when_configured(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
) -> None:
    _make_layout(tmp_path, ["md", "rst"])
    (tmp_path / ".specify" / "config.toml").write_text('format = "rst"\n', encoding="utf-8")
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)

    cls = _get_resolver_class()
    resolver = cls(project_root=tmp_path)
    result = resolver.resolve(TEMPLATE_NAME, "template")
    assert result is not None
    assert result.suffix == ".rst"


def test_resolver_falls_back_to_md_when_rst_missing(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
) -> None:
    _make_layout(tmp_path, ["md"])
    (tmp_path / ".specify" / "config.toml").write_text('format = "rst"\n', encoding="utf-8")
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)

    cls = _get_resolver_class()
    resolver = cls(project_root=tmp_path)
    result = resolver.resolve(TEMPLATE_NAME, "template")
    assert result is not None
    assert result.suffix == ".md"


def test_resolver_default_is_md(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch,
) -> None:
    _make_layout(tmp_path, ["md", "rst"])
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)

    cls = _get_resolver_class()
    resolver = cls(project_root=tmp_path)
    result = resolver.resolve(TEMPLATE_NAME, "template")
    assert result is not None
    assert result.suffix == ".md"
