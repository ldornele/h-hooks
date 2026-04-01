#!/usr/bin/env bash
#
# Prow job script for commitlint validation
# Executed by Prow presubmit jobs to validate PR commit messages
#
# Environment variables (provided by Prow):
#   PULL_BASE_SHA - Base commit SHA of the PR
#   PULL_PULL_SHA - Head commit SHA of the PR
#   REPO_OWNER    - Repository owner (e.g., openshift-hyperfleet)
#   REPO_NAME     - Repository name (e.g., hyperfleet-sentinel)
#   PULL_NUMBER   - Pull request number
#
# Exit codes:
#   0 - All commit messages are valid
#   1 - One or more commit messages are invalid

set -euo pipefail

# Configuration
HOOKS_REPO_URL="${HOOKS_REPO_URL:-https://raw.githubusercontent.com/openshift-hyperfleet/h-hooks/main}"
COMMITLINT_VERSION="${COMMITLINT_VERSION:-19.6.0}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_section() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
}

# Validate environment variables
validate_env() {
    local missing_vars=()

    if [[ -z "${PULL_BASE_SHA:-}" ]]; then
        missing_vars+=("PULL_BASE_SHA")
    fi

    if [[ -z "${PULL_PULL_SHA:-}" ]]; then
        missing_vars+=("PULL_PULL_SHA")
    fi

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_error "This script should be run by Prow CI"
        exit 1
    fi
}

# Download centralized commitlint config
download_config() {
    log_info "Downloading centralized commitlint config..."

    local config_url="${HOOKS_REPO_URL}/commitlint/commitlint.config.js"

    if command -v wget &> /dev/null; then
        wget -q -O commitlint.config.js "${config_url}"
    elif command -v curl &> /dev/null; then
        curl -sL -o commitlint.config.js "${config_url}"
    else
        log_error "Neither wget nor curl is available"
        exit 1
    fi

    if [[ ! -f commitlint.config.js ]]; then
        log_error "Failed to download commitlint config from ${config_url}"
        exit 1
    fi

    log_info "✓ Downloaded commitlint config"
}

# Install commitlint dependencies
install_dependencies() {
    log_info "Installing commitlint dependencies..."

    npm install --silent --no-save \
        "@commitlint/cli@^${COMMITLINT_VERSION}" \
        "@commitlint/config-conventional@^${COMMITLINT_VERSION}"

    log_info "✓ Dependencies installed"
}

# Validate commit messages
validate_commits() {
    log_info "Validating commit messages..."
    log_info "Base SHA: ${PULL_BASE_SHA}"
    log_info "Head SHA: ${PULL_PULL_SHA}"

    if npx commitlint \
        --config ./commitlint.config.js \
        --from "${PULL_BASE_SHA}" \
        --to "${PULL_PULL_SHA}" \
        --verbose; then
        return 0
    else
        return 1
    fi
}

# Print failure help
print_failure_help() {
    echo ""
    log_section "✗ Commit Message Validation Failed"
    echo "Please fix commit messages to follow HyperFleet Conventional Commits standard."
    echo ""
    echo "Required format:"
    echo "  ${GREEN}HYPERFLEET-XXX - <type>: <subject>${NC}"
    echo ""
    echo "Valid types:"
    echo "  feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
    echo ""
    echo "Examples:"
    echo "  ${GREEN}✓${NC} HYPERFLEET-813 - feat: add commitlint validation"
    echo "  ${GREEN}✓${NC} HYPERFLEET-425 - docs: update commit standard"
    echo "  ${GREEN}✓${NC} fix: resolve memory leak"
    echo ""
    echo "  ${RED}✗${NC} feat: Add validation (subject should be lowercase)"
    echo "  ${RED}✗${NC} HYPERFLEET-123 add validation (missing type)"
    echo ""
    echo "Documentation:"
    echo "  https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md"
    echo ""
}

# Main execution
main() {
    log_section "HyperFleet Commitlint Validation"

    # Print PR information
    echo "Repository: ${REPO_OWNER:-unknown}/${REPO_NAME:-unknown}"
    echo "PR: #${PULL_NUMBER:-unknown}"
    echo ""

    # Validate environment
    validate_env

    # Download config
    download_config

    # Install dependencies
    install_dependencies

    # Validate commits
    echo ""
    if validate_commits; then
        log_section "✓ All Commit Messages Are Valid"
        exit 0
    else
        print_failure_help
        exit 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
