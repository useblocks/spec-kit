#!/usr/bin/env bash
# Compare section structure of .md and .rst template variants.
#
# Flags drift when one side has a heading the other lacks. Headings are
# normalised by text only (case-insensitive, trimmed) so syntax differences
# (Markdown ## vs RST underline) do not register as drift.
#
# Markdown:
#   - Skips fenced code blocks (```...```).
#   - Recognises only ATX-style headings (# through ######).
# RST:
#   - Skips literal/code blocks (any line indented after `::` or `.. code-block::`).
#   - Recognises section underlines using = - ~ ^ " * + # of length >= 3.
#   - Skips grid-table row/separator lines that start with `+` or `|`.

set -euo pipefail

ROOT="${1:-templates}"
STATUS=0

normalise_md_headings() {
    local f="$1"
    awk '
    BEGIN { in_fence = 0 }
    /^```/ { in_fence = !in_fence; next }
    in_fence { next }
    /^#{1,6} / {
        sub(/^#+[[:space:]]+/, "")
        gsub(/`+/, "")
        print tolower($0)
    }
    ' "$f" | sort -u
}

normalise_rst_headings() {
    local f="$1"
    awk '
    BEGIN { in_block = 0; block_indent = -1 }

    # Track entering / leaving indented literal or directive blocks.
    # A directive (".. <name>::" or ".. code-block:: foo") opens a block whose
    # body is indented; we exit the block on the next non-blank, non-indented
    # line. Same for a paragraph ending in "::".
    /^[[:space:]]*$/ {
        prev = $0
        next
    }
    {
        # Compute current indent (count of leading spaces).
        cur_indent = match($0, /[^ ]/) - 1
        if (in_block && cur_indent <= block_indent) {
            in_block = 0
            block_indent = -1
        }
    }
    in_block { prev = $0; next }

    # Detect block opener after this line so the body skips it.
    /^[[:space:]]*\.\. [^[:space:]]+::/ {
        in_block = 1
        block_indent = match($0, /[^ ]/) - 1
        prev = $0
        next
    }
    /::[[:space:]]*$/ {
        in_block = 1
        block_indent = match($0, /[^ ]/) - 1
        prev = $0
        next
    }

    # Skip grid-table rows and separators.
    /^[[:space:]]*[+|]/ { prev = $0; next }

    # Detect a heading: previous non-blank line is text, current line is an
    # underline of length >= 3 made of one of the RST adornment characters.
    /^[=\-~^"*+#]+[[:space:]]*$/ {
        line = $0
        sub(/[[:space:]]+$/, "", line)
        if (length(line) >= 3 && prev != "") {
            title = prev
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", title)
            if (title != "" && length(title) <= length(line) + 2) {
                gsub(/`+/, "", title)
                print tolower(title)
            }
        }
    }
    { prev = $0 }
    ' "$f" | sort -u
}

check_pair() {
    local md="$1"
    local rst="${md%.md}.rst"
    if [ ! -f "$rst" ]; then
        return 0
    fi
    local md_h rst_h diff_out
    md_h="$(normalise_md_headings "$md")"
    rst_h="$(normalise_rst_headings "$rst")"
    if ! diff_out="$(diff <(echo "$md_h") <(echo "$rst_h"))"; then
        echo "DRIFT in $md <-> $rst"
        echo "$diff_out" | head -20
        STATUS=1
    fi
}

for md in "$ROOT"/spec-template.md "$ROOT"/plan-template.md "$ROOT"/tasks-template.md "$ROOT"/checklist-template.md "$ROOT"/constitution-template.md; do
    [ -f "$md" ] && check_pair "$md"
done

exit "$STATUS"
