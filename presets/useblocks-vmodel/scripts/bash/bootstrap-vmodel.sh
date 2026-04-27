#!/usr/bin/env bash
# Bootstrap sphinx-needs RST scaffolding into the project root.
# Idempotent: existing files are left untouched.
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
PRESET_DIR="$PROJECT_ROOT/.specify/presets/useblocks-vmodel"

if [ ! -d "$PRESET_DIR" ]; then
    echo "error: useblocks-vmodel preset not installed at $PRESET_DIR" >&2
    echo "run: specify preset add useblocks-vmodel" >&2
    exit 1
fi

mkdir -p "$PROJECT_ROOT/.specify"

created=0

# Project-root scaffolding files (sphinx + ubcode + sphinx-needs config).
# Per-feature template files (spec/plan/tasks/coverage/checklist/constitution)
# stay inside the preset directory so sphinx-build does not pick them up as
# orphan documents; command prompts reference them via the preset path.
for name in ubproject.toml conf.py coverage.rst; do
    src="$PRESET_DIR/scaffold/$name"
    dst="$PROJECT_ROOT/$name"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        echo "created: $name"
        created=$((created + 1))
    fi
done

# Format flag consumed by command prompts ("This project is configured for RST output").
cfg="$PROJECT_ROOT/.specify/config.toml"
if [ ! -f "$cfg" ]; then
    printf 'format = "rst"\n' > "$cfg"
    echo "created: .specify/config.toml"
    created=$((created + 1))
fi

if [ "$created" -eq 0 ]; then
    echo "scaffolding already present, nothing to do"
else
    echo "bootstrap complete: $created file(s) created"
fi
