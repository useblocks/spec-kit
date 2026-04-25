project = "speckit-project"
release = "0.1.0"

extensions = [
    "sphinx_needs",
]

source_suffix = {
    ".rst": "restructuredtext",
}

needs_from_toml = "ubproject.toml"

html_theme = "alabaster"

# Exclude framework-internal RST so sphinx-needs and ubcode do not parse the
# unrendered placeholder needs (REQ_PLACEHOLDER_001 etc.) shipped inside the
# spec-kit templates / extensions / presets directories. Only feature artefacts
# under specs/<feature>/ should be picked up.
exclude_patterns = [
    "_build",
    ".specify",
    ".venv",
    "node_modules",
]
