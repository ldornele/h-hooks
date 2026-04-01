#!/usr/bin/env bash
#
# Standalone commit message validation script
# Can be used in CI environments, pre-commit hooks, or manually
#
# Usage:
#   ./validate-commits.sh [FROM_SHA] [TO_SHA]
#   ./validate-commits.sh HEAD~1 HEAD        # Validate last commit
#   ./validate-commits.sh main HEAD          # Validate commits since main
#   ./validate-commits.sh                    # Validate last commit (default)
#
# Environment variables:
#   COMMITLINT_CONFIG - Path to commitlint config (default: ./commitlint.config.js)
#   VERBOSE           - Set to 1 for verbose output

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMITLINT_CONFIG="${COMMITLINT_CONFIG:-${SCRIPT_DIR}/commitlint.config.js}"
VERBOSE="${VERBOSE:-0}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_verbose() {
    if [[ "${VERBOSE}" == "1" ]]; then
        echo -e "[DEBUG] $*"
    fi
}

# Check dependencies
check_dependencies() {
    if ! command -v npx &> /dev/null; then
        log_error "npx not found. Please install Node.js and npm."
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        log_error "git not found. Please install git."
        exit 1
    fi
}

# Validate config file exists
check_config() {
    if [[ ! -f "${COMMITLINT_CONFIG}" ]]; then
        log_error "Commitlint config not found: ${COMMITLINT_CONFIG}"
        log_error "Please set COMMITLINT_CONFIG environment variable or run from h-hooks/commitlint directory"
        exit 1
    fi
    log_verbose "Using commitlint config: ${COMMITLINT_CONFIG}"
}

# Main validation function
validate_commits() {
    local from_sha="${1:-HEAD~1}"
    local to_sha="${2:-HEAD}"

    log_info "Validating commits from ${from_sha} to ${to_sha}"

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi

    # Verify SHAs exist
    if ! git rev-parse "${from_sha}" > /dev/null 2>&1; then
        log_error "Invalid FROM SHA: ${from_sha}"
        exit 1
    fi

    if ! git rev-parse "${to_sha}" > /dev/null 2>&1; then
        log_error "Invalid TO SHA: ${to_sha}"
        exit 1
    fi

    # Run commitlint
    log_info "Running commitlint..."

    local commitlint_cmd="npx commitlint --config ${COMMITLINT_CONFIG} --from ${from_sha} --to ${to_sha}"

    if [[ "${VERBOSE}" == "1" ]]; then
        commitlint_cmd="${commitlint_cmd} --verbose"
    fi

    log_verbose "Command: ${commitlint_cmd}"

    if ${commitlint_cmd}; then
        log_info "✓ All commit messages are valid"
        return 0
    else
        log_error "✗ Commit message validation failed"
        log_error ""
        log_error "Please fix commit messages to follow HyperFleet Conventional Commits standard:"
        log_error "https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md"
        log_error ""
        log_error "Valid format: HYPERFLEET-XXX - type: subject"
        log_error "Example: HYPERFLEET-813 - feat: add commitlint validation"
        return 1
    fi
}

# Main execution
main() {
    check_dependencies
    check_config

    local from_sha="${1:-HEAD~1}"
    local to_sha="${2:-HEAD}"

    validate_commits "${from_sha}" "${to_sha}"
}

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
