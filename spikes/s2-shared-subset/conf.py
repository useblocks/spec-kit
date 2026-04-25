project = "spec-kit-s2-shared-subset"
author = "useblocks research"
release = "0.1.0"

extensions = [
    "myst_parser",
    "sphinx_needs",
]

source_suffix = {
    ".md": "markdown",
    ".rst": "restructuredtext",
}

myst_enable_extensions = [
    "colon_fence",
]

needs_from_toml = "ubproject.toml"

# Keep the HTML builder happy even though we only care about the `needs` builder.
html_theme = "alabaster"
exclude_patterns = ["_build", "_venv", "out-free", "out-paid", "myst-free-only"]
