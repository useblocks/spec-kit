#!/usr/bin/env bats

setup() {
  unset SPECIFY_FORMAT
  TMP="$(mktemp -d)"
  export TMP
  cd "$TMP"
  mkdir -p .specify
  # shellcheck source=../../scripts/bash/format.sh
  source "$BATS_TEST_DIRNAME/../../scripts/bash/format.sh"
}

teardown() {
  rm -rf "$TMP"
}

@test "default is md when no config and no env" {
  run speckit_format_ext "$TMP"
  [ "$status" -eq 0 ]
  [ "$output" = "md" ]
}

@test "config.toml format=rst returns rst" {
  printf 'format = "rst"\n' > .specify/config.toml
  run speckit_format_ext "$TMP"
  [ "$output" = "rst" ]
}

@test "config.toml format=md returns md" {
  printf 'format = "md"\n' > .specify/config.toml
  run speckit_format_ext "$TMP"
  [ "$output" = "md" ]
}

@test "env var overrides config" {
  printf 'format = "md"\n' > .specify/config.toml
  SPECIFY_FORMAT=rst run speckit_format_ext "$TMP"
  [ "$output" = "rst" ]
}

@test "invalid format falls back to md with warning" {
  printf 'format = "yaml"\n' > .specify/config.toml
  run speckit_format_ext "$TMP"
  [ "$output" = "md" ]
}

@test "missing python3 still returns default md" {
  PATH_WITHOUT_PYTHON="$(echo "$PATH" | tr ':' '\n' | grep -v -E 'python|conda' | tr '\n' ':')"
  PATH="$PATH_WITHOUT_PYTHON" run speckit_format_ext "$TMP"
  [ "$output" = "md" ]
}

@test "resolve_template falls back from rst to md when rst variant missing" {
  mkdir -p "$TMP/.specify/templates"
  printf 'md-content\n' > "$TMP/.specify/templates/spec-template.md"
  source "$BATS_TEST_DIRNAME/../../scripts/bash/common.sh"
  SPECIFY_FORMAT=rst run resolve_template "spec-template" "$TMP"
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/.specify/templates/spec-template.md" ]
}

@test "resolve_template prefers rst variant when present and format=rst" {
  mkdir -p "$TMP/.specify/templates"
  printf 'md-content\n' > "$TMP/.specify/templates/spec-template.md"
  printf 'rst-content\n' > "$TMP/.specify/templates/spec-template.rst"
  source "$BATS_TEST_DIRNAME/../../scripts/bash/common.sh"
  SPECIFY_FORMAT=rst run resolve_template "spec-template" "$TMP"
  [ "$output" = "$TMP/.specify/templates/spec-template.rst" ]
}

@test "resolve_template uses md by default even when rst exists" {
  mkdir -p "$TMP/.specify/templates"
  printf 'md-content\n' > "$TMP/.specify/templates/spec-template.md"
  printf 'rst-content\n' > "$TMP/.specify/templates/spec-template.rst"
  source "$BATS_TEST_DIRNAME/../../scripts/bash/common.sh"
  unset SPECIFY_FORMAT
  run resolve_template "spec-template" "$TMP"
  [ "$output" = "$TMP/.specify/templates/spec-template.md" ]
}
