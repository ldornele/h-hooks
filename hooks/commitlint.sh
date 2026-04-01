#!/usr/bin/env bash
#
# Pre-commit hook for commitlint validation
# This script is executed by the pre-commit framework
#
# Validates the commit message in .git/COMMIT_EDITMSG against
# HyperFleet Conventional Commits standard using commitlint
#
# Exit codes:
#   0 - Commit message is valid
#   1 - Commit message is invalid

set -euo pipefail

# Get the commit message file path from pre-commit
COMMIT_MSG_FILE="${1:-}"

if [[ -z "${COMMIT_MSG_FILE}" ]]; then
    echo "Error: No commit message file provided"
    echo "Usage: $0 <commit-msg-file>"
    exit 1
fi

if [[ ! -f "${COMMIT_MSG_FILE}" ]]; then
    echo "Error: Commit message file not found: ${COMMIT_MSG_FILE}"
    exit 1
fi

# Check if npx is available
if ! command -v npx &> /dev/null; then
    echo "Error: npx not found. Please install Node.js and npm."
    echo "See: https://nodejs.org/"
    exit 1
fi

# Check if commitlint dependencies are installed
if ! npx --no-install commitlint --version &> /dev/null; then
    echo "Error: @commitlint/cli not found."
    echo "Please install commitlint dependencies:"
    echo "  npm install --save-dev @commitlint/cli @commitlint/config-conventional"
    exit 1
fi

# Run commitlint on the commit message
echo "Validating commit message..."

if npx commitlint --edit "${COMMIT_MSG_FILE}"; then
    echo "✓ Commit message is valid"
    exit 0
else
    echo ""
    echo "✗ Commit message validation failed"
    echo ""
    echo "Please follow HyperFleet Conventional Commits standard:"
    echo ""
    echo "  HYPERFLEET-XXX - <type>: <subject>"
    echo ""
    echo "Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
    echo ""
    echo "Examples:"
    echo "  ✓ HYPERFLEET-813 - feat: add commitlint validation"
    echo "  ✓ HYPERFLEET-425 - docs: update commit standard"
    echo "  ✓ fix: resolve memory leak in event handler"
    echo ""
    echo "  ✗ feat: Add validation (subject should be lowercase)"
    echo "  ✗ HYPERFLEET-123 add validation (missing type and colon)"
    echo ""
    echo "See: https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md"
    exit 1
fi
