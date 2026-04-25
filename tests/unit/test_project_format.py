from __future__ import annotations

import os
from pathlib import Path

import pytest

from specify_cli.project_format import get_project_format


def test_default_is_md(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)
    assert get_project_format(tmp_path) == "md"


def test_config_rst(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)
    (tmp_path / ".specify").mkdir()
    (tmp_path / ".specify" / "config.toml").write_text('format = "rst"\n', encoding="utf-8")
    assert get_project_format(tmp_path) == "rst"


def test_env_overrides_config(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    (tmp_path / ".specify").mkdir()
    (tmp_path / ".specify" / "config.toml").write_text('format = "md"\n', encoding="utf-8")
    monkeypatch.setenv("SPECIFY_FORMAT", "rst")
    assert get_project_format(tmp_path) == "rst"


def test_invalid_config_falls_back_to_md(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)
    (tmp_path / ".specify").mkdir()
    (tmp_path / ".specify" / "config.toml").write_text('format = "yaml"\n', encoding="utf-8")
    assert get_project_format(tmp_path) == "md"


def test_malformed_toml_falls_back_to_md(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("SPECIFY_FORMAT", raising=False)
    (tmp_path / ".specify").mkdir()
    (tmp_path / ".specify" / "config.toml").write_text('this is = not = toml\n', encoding="utf-8")
    assert get_project_format(tmp_path) == "md"
