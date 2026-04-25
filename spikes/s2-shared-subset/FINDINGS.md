# S2 — shared-subset acceptance audit

**Date:** 2026-04-23
**Branch:** `useblocks/integration`
**Free tier:** sphinx 9.1.0 + sphinx-needs 8.0.0 + myst-parser 5.0.0
**Paid tier:** ubcode 0.28.2 (built from `/home/bburda/projects/useblocks/ubcode` via `rye sync`; OSS activation on public git remote)

## Goal

Empirically verify that a single source file exercising the declared shared subset
(`need`, `needextend`, roles `need` / `need_outgoing` / `need_incoming` / `need_part`) produces semantically equivalent `needs.json` in both tiers, or document the divergences.

## Corpus

Under `spikes/s2-shared-subset/`:

- `ubproject.toml` — declarative config (types `req`/`spec`/`test`, typed links `satisfies`/`verifies`, `id_regex`, status enum schema).
- `conf.py` — minimal free-tier bootstrap, `needs_from_toml = "ubproject.toml"`, MyST enabled.
- `index.rst` — canonical source with 6 needs, 1 `needextend`, one `need_part`, inline audit of all four shared-subset roles.
- `myst-free-only/index.md` — identical content in MyST fenced-block form, excluded from the paid-tier index.

## Commands

```bash
# Free tier
_venv/bin/python -m sphinx -b needs -W . out-free

# Paid tier (from same working dir)
/home/bburda/projects/useblocks/ubcode/.venv/bin/ubc build needs --no-cache -o out-paid/needs.json
```

Both succeeded with zero errors on the RST source.

## Results

### On the shared subset (RST input) — semantically identical

After dropping rendering-only fields that each tier computes independently,
both tiers emit identical data for all 6 needs:

| Field                    | Free tier                             | Paid tier                             | Match |
| ------------------------ | ------------------------------------- | ------------------------------------- | :---: |
| `id`                     | `REQ_START`, …                        | `REQ_START`, …                        | ✅    |
| `type`                   | `req` / `spec` / `test`               | same                                  | ✅    |
| `title`                  | exact string                          | exact string                          | ✅    |
| `status`                 | `open` / `in_progress` / `done`       | same                                  | ✅    |
| `needextend` override    | `TC_START_HIL.status = done`          | same                                  | ✅    |
| `satisfies` (typed link) | `['REQ_STOP']`                        | same                                  | ✅    |
| `verifies` (typed link)  | `['REQ_START']`                       | same                                  | ✅    |
| `parts`                  | `{ack: {id, content}}` inside parent  | same                                  | ✅    |
| Inline roles             | `:need:`, `:need_outgoing:`, `:need_incoming:`, `:need_part:` all resolved | same | ✅ |

### Serialization differences (cosmetic, not semantic)

- **Free tier emits default-valued fields** (`satisfies: []`, `verifies: []`, `links: []`).
  **Paid tier omits them** when `needs_defaults_removed = false` in project settings — field absent means "default".
- **Free tier-only fields** (rendering / Sphinx-specific): `lineno`, `type_name`,
  `satisfies_back`, `verifies_back` (computed reverse links),
  `content`, `docname`, `doctype`, `sections`, `tags`, `is_external`, `layout`, `status_schema` and similar.
- **Paid tier-only fields**: `__source__` (source map — file path + byte offsets),
  `needs_defaults_removed` flag, ubcode field defaults that sphinx-needs doesn't serialize by the same name (`collapse`, `hide`).

A downstream consumer that looks only at `id`, `type`, `status`, `title`, typed links
and `parts` sees identical graphs from both tiers.

### MyST Markdown source — paid tier does not parse it

When the corpus is authored in `.md` with MyST fenced-block directives:

- **Free tier:** parses cleanly, produces the same 6 needs.
  (`myst-parser` is a free-tier Sphinx extension.)
- **Paid tier:** even after adding `*.md` to `source.extend_include`,
  ubcode finds **0 needs** (27 warnings).
  Root cause: ubcode ships a single RST parser (`rst_fast_parse` Rust crate, see
  `ubcode/AGENTS.md` — Python packages list).
  MyST fenced blocks are not recognised as directives by the RST tokeniser.

**Implication.** Authoring in MyST is not a shared-subset path. If paid tier must see
the source file directly, it has to be RST. If authoring must be in Markdown,
the spec-kit extension itself must emit `needs.json` from `.md` (parser-side) and
both tiers consume the resulting JSON rather than the original source.

## Hypotheses — status after S2

| ID   | Status                             | Note                                                                                       |
| ---- | ---------------------------------- | ------------------------------------------------------------------------------------------ |
| H2   | Partially confirmed; refine.       | MyST works on free tier only. Paid tier shared subset is RST. Update wording in plan.      |
| H11  | Confirmed for RST input.           | Free → paid is drop-in on RST with no source-file edits. Output differs only cosmetically. |
| H12  | Confirmed for this corpus.         | All directives/roles stayed within the subset; both tiers accepted the same file.          |

## Decisions to take back into the plan

1. **Authoring format is RST**, not MyST, if a single source must be readable by both tiers.
2. **Alternative**: our spec-kit extension owns a MyST-to-`needs.json` converter; both tiers then consume `needs.json` downstream (via `needs_external_needs` on free tier, or as ubcode input). This keeps the spec-kit-idiomatic `.md` authoring experience without forcing ubcode to grow a MyST parser.
3. **Normalisation script** is needed for any "diff free-vs-paid `needs.json`" comparisons — drop default-valued fields and rendering-only fields before comparing. This normalisation utility is small and reusable; worth making part of the extension's test harness.
4. **Rendering directives** (`needtable`, `needflow`, …) are out of the shared subset and stay there — not needed for the authoring story.

## Next

Task unblocks Phase 1 exits for S2.
Adjacent spikes to run next: S1 (preset bootstrap), S0 (invisible-bootstrap path),
S9 (adversarial constitution), S3 (agent compliance at scale).
