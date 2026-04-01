# HyperFleet Hooks (h-hooks)

Central repository for HyperFleet validation logic, commit standards enforcement, and CI configurations.

**Single source of truth** for commitlint rules, pre-commit hooks, and Prow job definitions used across all HyperFleet repositories.

## Repository Structure

```
h-hooks/
├── README.md                      # This file
├── .pre-commit-hooks.yaml         # Pre-commit hooks definition
├── hooks/
│   └── commitlint.sh              # Commitlint hook script
├── commitlint/
│   ├── commitlint.config.js       # Shared commitlint configuration
│   └── validate-commits.sh        # Standalone validation script
├── prow/
│   ├── commitlint-job.yaml        # Prow presubmit job template
│   └── scripts/
│       └── run-commitlint.sh      # Script executed by Prow
├── docs/
│   ├── setup-local-hooks.md       # Local development setup
│   ├── setup-prow-jobs.md         # CI integration guide
│   └── migration-guide.md         # Migration from existing configs
├── package.json                   # npm dependencies
└── LICENSE                        # Apache 2.0 license
```

## Quick Start

### For Repository Maintainers

To add commitlint validation to a HyperFleet repository:

1. **Add pre-commit hooks** (local validation):
   ```bash
   # In your repository root
   cat > .pre-commit-config.yaml <<EOF
   repos:
     - repo: https://github.com/ldornele/h-hooks
       rev: v1.0.0
       hooks:
         - id: commitlint
   EOF
   ```

2. **Add commitlint config**:
   ```bash
   # Copy from h-hooks or create minimal version
   cp path/to/h-hooks/commitlint/commitlint.config.js .
   ```

3. **Install dependencies**:
   ```bash
   npm install --save-dev @commitlint/cli@^19.6.0 @commitlint/config-conventional@^19.6.0
   ```

### For Developers

To set up local commit validation:

```bash
# Install pre-commit framework
pip install pre-commit

# Install Node.js dependencies
npm install

# Install git hooks
pre-commit install --hook-type commit-msg

# Test (optional)
echo "HYPERFLEET-001 - feat: test" | npx commitlint
```

See [docs/setup-local-hooks.md](docs/setup-local-hooks.md) for detailed instructions.

## Commit Message Format

All HyperFleet repositories follow the Conventional Commits specification with JIRA ticket prefix:

```
HYPERFLEET-XXX - <type>: <subject>

[optional body]

[optional footer]
```

### Valid Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style (formatting, gofmt, goimports)
- `refactor` - Code restructuring
- `perf` - Performance improvements
- `test` - Adding tests
- `build` - Build system changes
- `ci` - CI configuration changes
- `chore` - Other changes
- `revert` - Reverting commits

### Examples

✅ **Valid:**
```
HYPERFLEET-813 - feat: add commitlint validation to sentinel
HYPERFLEET-425 - docs: update commit message standard
fix: resolve memory leak in event handler
```

❌ **Invalid:**
```
feat: Add validation (subject should be lowercase)
HYPERFLEET-123 add validation (missing type and colon)
added validation feature (not conventional format)
```

## Prow CI Integration

For CI enforcement, copy the Prow job template:

```bash
cp path/to/h-hooks/prow/commitlint-job.yaml .prow.yaml
# Update repository name in .prow.yaml
```

See [docs/setup-prow-jobs.md](docs/setup-prow-jobs.md) for complete Prow setup.

## Testing

To test this configuration, see the [test-commitlint](https://github.com/ldornele/test-commitlint) repository.

## Reference

- [HyperFleet Commit Standard](https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md)
- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Pre-commit Framework](https://pre-commit.com/)
- [Prow Documentation](https://docs.prow.k8s.io/)

## Contributing

Changes to validation rules affect all HyperFleet repositories. Follow these guidelines:

1. Propose changes via pull request
2. Update version in tags (semantic versioning)
3. Update documentation
4. Notify teams before releasing breaking changes

## Versioning

This repository uses semantic versioning:

- **MAJOR**: Breaking changes to validation rules
- **MINOR**: New features (new hooks, scripts)
- **PATCH**: Bug fixes, documentation updates

Repositories reference specific versions via git tags:
```yaml
repos:
  - repo: https://github.com/ldornele/h-hooks
    rev: v1.0.0  # Pin to specific version
```

## License

Apache License 2.0 - See [LICENSE](LICENSE) file.
