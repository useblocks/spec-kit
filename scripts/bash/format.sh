#!/usr/bin/env bash

# speckit_format_ext — resolve project spec/plan/tasks file extension.
#
# Priority:
#   1. SPECIFY_FORMAT env var (if set and valid)
#   2. .specify/config.toml 'format' key (if file exists and valid)
#   3. Default: "md"
#
# Valid values: "md" or "rst". Anything else falls back to "md".
#
# Usage: ext="$(speckit_format_ext "$repo_root")"
speckit_format_ext() {
    local repo_root="${1:-.}"
    local candidate=""

    # Env var wins
    if [ -n "${SPECIFY_FORMAT:-}" ]; then
        candidate="$SPECIFY_FORMAT"
    elif [ -f "$repo_root/.specify/config.toml" ] && command -v python3 >/dev/null 2>&1; then
        candidate="$(
            SPECKIT_CONFIG="$repo_root/.specify/config.toml" python3 - <<'PY' 2>/dev/null
import os, sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib  # type: ignore
try:
    with open(os.environ["SPECKIT_CONFIG"], "rb") as f:
        data = tomllib.load(f)
    val = data.get("format", "")
    if isinstance(val, str):
        print(val.strip().lower())
except Exception:
    sys.exit(0)
PY
        )"
    fi

    case "$candidate" in
        rst) echo "rst" ;;
        md|"") echo "md" ;;
        *) echo "md" ;;
    esac
}
