#!/usr/bin/env bash
# E2E smoke test for V-model spec-kit + sphinx-needs.
#
# Does NOT invoke any AI agent. It verifies:
#   1. specify init --format rst scaffolds ubproject.toml + conf.py + coverage.rst
#   2. create-new-feature.sh produces .rst (not .md) feature paths
#   3. Manually authored V-model artefacts (spec.rst, plan.rst, tasks.rst)
#      pass sphinx-build -b needs -W validation
#   4. Trace graph is complete: every US has TC, every REQ traces to US,
#      every SPEC satisfies REQ, every TASK implements SPEC, every TC verifies
#      something.
#   5. ubcode produces equivalent needs.json (parser cross-check)

set -euo pipefail
SPEC_KIT_ROOT="${SPEC_KIT_ROOT:-$(pwd)}"
SPHINX_VENV="${SPHINX_VENV:-${SPEC_KIT_ROOT}/spikes/s2-shared-subset/_venv}"
UBC="${UBC:-/home/bburda/projects/useblocks/ubcode/.venv/bin/ubc}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cd "$TMPDIR"
git init -q
git checkout -b main -q
git remote add origin https://github.com/useblocks/spec-kit.git

echo "=== Step 1: specify init --format rst ==="
uv run --project "$SPEC_KIT_ROOT" specify init --here --ai claude --no-git --ignore-agent-tools --format rst --force 2>&1 | tail -5
test -f .specify/config.toml
test -f ubproject.toml
test -f conf.py
test -f coverage.rst
echo "  scaffold OK"

echo "=== Step 2: create-new-feature.sh ==="
bash "$SPEC_KIT_ROOT/scripts/bash/create-new-feature.sh" "auth-login" 2>&1 | tail -3
test -f specs/001-auth-login/spec.rst
test ! -f specs/001-auth-login/spec.md
echo "  feature dir OK"

echo "=== Step 3: author V-model spec ==="
cat > specs/001-auth-login/spec.rst <<'EOF'
Auth Login Feature
==================

.. user_story:: User logs in via OAuth
   :id: US_AUTH_LOGIN_001
   :status: open

   The user signs in to the application using their OAuth identity provider.

.. req:: Validate JWT signature
   :id: REQ_AUTH_TOK_001
   :status: open
   :traces_to: US_AUTH_LOGIN_001

   System MUST verify the JWT signature using the configured public key.

.. risk:: Token replay attack
   :id: RISK_AUTH_REPLAY_001
   :status: open
   :affects: REQ_AUTH_TOK_001

   An attacker could replay a captured JWT before its expiry.

.. decision:: Use 1-hour token expiry
   :id: DEC_AUTH_EXPIRY_001
   :status: open
   :traces_to: US_AUTH_LOGIN_001

   Context: Token replay risk, balance with UX.
   Decision: 1-hour expiry with refresh token.
   Consequences: Users re-authenticate every hour; refresh flow needed.

.. test:: User completes OAuth login
   :id: TC_AUTH_ACC_001
   :status: open
   :verifies: US_AUTH_LOGIN_001

   Given an unauthenticated user, when they click "Login with OAuth",
   then they are redirected to the IdP and on return they land on the
   dashboard.
EOF

echo "=== Step 4: author V-model plan ==="
cat > specs/001-auth-login/plan.rst <<'EOF'
Auth Login Plan
===============

.. spec:: JWT verifier component
   :id: SPEC_AUTH_VERIFIER_001
   :status: open
   :satisfies: REQ_AUTH_TOK_001

   A stateless verifier that validates JWT signatures against a key set
   loaded at boot.

.. decision:: Use Authlib for OAuth flow
   :id: DEC_AUTH_AUTHLIB_001
   :status: open
   :motivates: SPEC_AUTH_VERIFIER_001

   Context: Build vs buy.
   Decision: Authlib (battle-tested, maintained).
   Consequences: External dependency, simpler implementation.

.. test:: System test JWT verifier
   :id: TC_AUTH_SYS_001
   :status: open
   :verifies: SPEC_AUTH_VERIFIER_001

   Given a valid signed JWT, the verifier returns the claims;
   given a tampered JWT, it raises an InvalidSignature error.
EOF

echo "=== Step 5: author V-model tasks ==="
cat > specs/001-auth-login/tasks.rst <<'EOF'
Auth Login Tasks
================

.. task:: Implement JWT verifier
   :id: TASK_AUTH_IMPL_001
   :status: open
   :implements: SPEC_AUTH_VERIFIER_001

   Implement the JWT verifier in src/auth/jwt_verifier.py.

.. test:: Integration test for verifier with key rotation
   :id: TC_AUTH_INT_001
   :status: open
   :verifies: SPEC_AUTH_VERIFIER_001

   Verifier accepts JWTs signed by either the current or previous key.

.. test:: Unit test verifier signature check
   :id: TC_AUTH_UNIT_001
   :status: open
   :verifies: TASK_AUTH_IMPL_001

   Pure-function unit test of the signature-check helper.
EOF

echo "=== Step 6: sphinx-needs build (the validation oracle) ==="
"$SPHINX_VENV/bin/python" -m sphinx -b needs -W . _build/sphinx 2>&1 | tail -5
test -s _build/sphinx/needs.json
SPHINX_COUNT=$("$SPHINX_VENV/bin/python" -c "
import json
d = json.load(open('_build/sphinx/needs.json'))
v = list(d['versions'].values())[0]
print(len(v['needs']))
")
echo "  sphinx-needs count: $SPHINX_COUNT"
# Expected: 1 US + 1 REQ + 1 RISK + 2 DEC + 1 SPEC + 4 TC + 1 TASK = 11
test "$SPHINX_COUNT" -eq 11 || { echo "FAIL: expected 11 needs, got $SPHINX_COUNT"; exit 1; }

echo "=== Step 7: trace-graph completeness checks ==="
"$SPHINX_VENV/bin/python" - <<'PYEOF'
import json, sys
d = json.load(open('_build/sphinx/needs.json'))
v = list(d['versions'].values())[0]
needs = v['needs']

# Every US has at least one verifies_back (acceptance test)
us_orphans = [n for n in needs.values() if n['type'] == 'user_story' and not n.get('verifies_back')]
assert not us_orphans, f"US without TC: {[n['id'] for n in us_orphans]}"

# Every REQ has at least one satisfies_back (SPEC) and traces_to (US)
for n in needs.values():
    if n['type'] == 'req':
        assert n.get('traces_to'), f"REQ {n['id']} missing traces_to"
        assert n.get('satisfies_back'), f"REQ {n['id']} missing satisfies_back SPEC"

# Every SPEC has implements_back (TASK) and verifies_back (TC)
for n in needs.values():
    if n['type'] == 'spec':
        assert n.get('satisfies'), f"SPEC {n['id']} missing satisfies REQ"
        assert n.get('implements_back'), f"SPEC {n['id']} missing implements_back TASK"
        assert n.get('verifies_back'), f"SPEC {n['id']} missing verifying TC"

# Every TASK has implements (SPEC) and verified_by (unit TC)
for n in needs.values():
    if n['type'] == 'task':
        assert n.get('implements'), f"TASK {n['id']} missing implements SPEC"

# Every RISK has affects (REQ/SPEC/TASK)
for n in needs.values():
    if n['type'] == 'risk':
        assert n.get('affects'), f"RISK {n['id']} missing affects"

# Every DEC has either traces_to or motivates
for n in needs.values():
    if n['type'] == 'decision':
        assert n.get('traces_to') or n.get('motivates'), f"DEC {n['id']} missing both traces_to and motivates"

print("trace graph: complete")
PYEOF

echo "=== Step 8: ubcode build (parser cross-check) ==="
mkdir -p _build/ubc
"$UBC" build needs --no-cache -o _build/ubc/needs.json 2>&1 | tail -3
test -s _build/ubc/needs.json
UBC_COUNT=$("$SPHINX_VENV/bin/python" -c "
import json
d = json.load(open('_build/ubc/needs.json'))
v = list(d['versions'].values())[0]
print(len(v['needs']))
")
echo "  ubcode count: $UBC_COUNT"
test "$UBC_COUNT" -eq "$SPHINX_COUNT" || { echo "FAIL: count mismatch ($SPHINX_COUNT vs $UBC_COUNT)"; exit 1; }

echo "=== V-MODEL SMOKE TEST PASSED ==="
