project = "speckit-project"
release = "0.1.0"

extensions = [
    "sphinx_needs",
]

source_suffix = {
    ".rst": "restructuredtext",
}

needs_from_toml = "ubproject.toml"

# Master document: coverage.rst pulls in the per-feature spec/plan/tasks
# pages via toctree, so sphinx-build resolves the full graph.
master_doc = "coverage"

html_theme = "alabaster"

# Exclude framework-internal RST so neither sphinx-needs nor any HTML
# build walks the unrendered placeholder needs in templates/.
exclude_patterns = [
    "_build",
    ".specify",
    ".venv",
    "node_modules",
]
