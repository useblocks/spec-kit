"""Per-project format resolution for spec-kit.

Reads SPECIFY_FORMAT env var (if set and valid) or `.specify/config.toml`
``format`` key (if present and valid). Defaults to ``md``.
"""

from __future__ import annotations

import functools
import os
from pathlib import Path
from typing import Literal

try:  # Python 3.11+
    import tomllib
except ImportError:  # pragma: no cover
    import tomli as tomllib  # type: ignore[no-redef]

Format = Literal["md", "rst"]

_VALID: set[str] = {"md", "rst"}


def get_project_format(repo_root: Path | str) -> Format:
    """Return the configured spec-kit file format for ``repo_root``.

    Resolution order:
        1. ``SPECIFY_FORMAT`` env var.
        2. ``<repo_root>/.specify/config.toml`` ``format`` key.
        3. Default ``md``.

    Any invalid value falls back to ``md``.
    """
    env_val = os.environ.get("SPECIFY_FORMAT", "").strip().lower()
    if env_val in _VALID:
        return env_val  # type: ignore[return-value]
    return _get_project_format_cached(Path(repo_root))


@functools.lru_cache(maxsize=None)
def _get_project_format_cached(repo_root: Path) -> Format:
    """Memoised TOML-read path; env var check is intentionally kept outside."""
    cfg = Path(repo_root) / ".specify" / "config.toml"
    if cfg.is_file():
        try:
            with cfg.open("rb") as f:
                data = tomllib.load(f)
            val = str(data.get("format", "")).strip().lower()
            if val in _VALID:
                return val  # type: ignore[return-value]
        except (OSError, tomllib.TOMLDecodeError):
            pass

    return "md"
