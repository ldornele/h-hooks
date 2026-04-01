# Setting Up Local Pre-commit Hooks

This guide explains how to configure local commit message validation for HyperFleet repositories using pre-commit hooks.

## Overview

Local pre-commit hooks provide **fast, immediate feedback** before commits are made, catching invalid commit messages early and reducing CI churn.

## Prerequisites

- Python 3.7+ (for pre-commit framework)
- Node.js 18+ and npm (for commitlint)
- Git

## Installation Steps

### 1. Install Pre-commit Framework

Choose your preferred installation method:

**Using pip:**
```bash
pip install pre-commit
```

**Using Homebrew (macOS):**
```bash
brew install pre-commit
```

**Using apt (Ubuntu/Debian):**
```bash
sudo apt install pre-commit
```

Verify installation:
```bash
pre-commit --version
# Output: pre-commit 3.x.x
```

### 2. Configure Repository

In your HyperFleet repository root, create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/openshift-hyperfleet/h-hooks
    rev: v1.0.0  # Use latest release tag
    hooks:
      - id: commitlint
```

**Important:** Always pin to a specific version tag (`v1.0.0`) instead of `main` to ensure consistent behavior.

### 3. Install Commitlint Dependencies

In your repository root:

```bash
npm install --save-dev @commitlint/cli@^19.6.0 @commitlint/config-conventional@^19.6.0
```

This adds the dependencies to your `package.json`:

```json
{
  "devDependencies": {
    "@commitlint/cli": "^19.6.0",
    "@commitlint/config-conventional": "^19.6.0"
  }
}
```

### 4. Install Git Hooks

Run this command in your repository root:

```bash
pre-commit install --hook-type commit-msg
```

This installs the commit-msg hook into `.git/hooks/commit-msg`.

Verify installation:
```bash
ls -la .git/hooks/commit-msg
# Should show the hook file
```

### 5. Create Local Commitlint Config

Create `commitlint.config.js` in your repository root:

```javascript
// Extends the centralized HyperFleet commitlint config
// from h-hooks repository
module.exports = {
  extends: ['@commitlint/config-conventional'],

  // Use the same rules as h-hooks/commitlint/commitlint.config.js
  // This ensures local validation matches CI validation
  rules: {
    'header-max-length': [2, 'always', 100],
    'subject-max-length': [2, 'always', 72],
    'type-case': [2, 'always', 'lower-case'],
    'type-enum': [
      2,
      'always',
      [
        'feat', 'fix', 'docs', 'style', 'refactor',
        'perf', 'test', 'build', 'ci', 'chore', 'revert'
      ]
    ],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'subject-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'body-leading-blank': [2, 'always'],
    'footer-leading-blank': [2, 'always'],
    'scope-empty': [0]
  },

  parserPreset: {
    parserOpts: {
      headerPattern: /^(?:HYPERFLEET-\d+\s+-\s+)?(\w+)(?:\(([^)]*)\))?:\s+(.+)$/,
      headerCorrespondence: ['type', 'scope', 'subject']
    }
  },

  ignores: [
    (commit) => commit.startsWith('Merge branch'),
    (commit) => commit.startsWith('Merge pull request'),
    (commit) => commit.startsWith('Revert "')
  ],

  helpUrl: 'https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md'
};
```

**Note:** In the future, when h-hooks provides an npm package, you can simplify this to:
```javascript
module.exports = {
  extends: ['@hyperfleet/commitlint-config']
};
```

## Usage

### Making a Commit

When you make a commit, the hook runs automatically:

```bash
git add file.txt
git commit -m "HYPERFLEET-813 - feat: add commitlint validation"
```

**If valid:**
```
Validating commit message...
✓ Commit message is valid
[main abc1234] HYPERFLEET-813 - feat: add commitlint validation
 1 file changed, 10 insertions(+)
```

**If invalid:**
```
Validating commit message...

✗ Commit message validation failed

Please follow HyperFleet Conventional Commits standard:

  HYPERFLEET-XXX - <type>: <subject>

Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

Examples:
  ✓ HYPERFLEET-813 - feat: add commitlint validation
  ✓ fix: resolve memory leak

  ✗ feat: Add validation (subject should be lowercase)
  ✗ HYPERFLEET-123 add validation (missing type)
```

### Testing Hooks Manually

Test without making a commit:

```bash
echo "HYPERFLEET-813 - feat: test commit" | pre-commit run --hook-stage commit-msg
```

Test all hooks:
```bash
pre-commit run --all-files --hook-stage commit-msg
```

### Bypassing Hooks (Not Recommended)

If absolutely necessary, you can skip hooks:

```bash
git commit --no-verify -m "emergency fix"
```

**Warning:** Bypassing hooks means the commit will still be validated by Prow CI, and the PR may be blocked from merging.

## Updating Hooks

When h-hooks releases a new version:

1. Update the `rev` in `.pre-commit-config.yaml`:
   ```yaml
   repos:
     - repo: https://github.com/openshift-hyperfleet/h-hooks
       rev: v1.1.0  # Updated version
   ```

2. Update the hooks:
   ```bash
   pre-commit autoupdate
   pre-commit install --hook-type commit-msg
   ```

## Troubleshooting

### Hook Not Running

Check if hooks are installed:
```bash
pre-commit install --hook-type commit-msg
```

Verify configuration:
```bash
pre-commit run --hook-stage commit-msg --verbose
```

### npx Not Found

Install Node.js and npm:
- **macOS:** `brew install node`
- **Ubuntu/Debian:** `sudo apt install nodejs npm`
- **Windows:** Download from https://nodejs.org/

### Commitlint Dependencies Missing

Install dependencies:
```bash
npm install
```

Or install globally:
```bash
npm install -g @commitlint/cli @commitlint/config-conventional
```

### Different Behavior Between Local and CI

Ensure your local `commitlint.config.js` matches the rules in `h-hooks/commitlint/commitlint.config.js`.

Check versions:
```bash
npx commitlint --version
```

## Best Practices

1. **Always pin versions** in `.pre-commit-config.yaml` (use tags, not `main`)
2. **Keep dependencies updated** in `package.json`
3. **Commit the config files** (`.pre-commit-config.yaml`, `commitlint.config.js`, `package.json`)
4. **Don't commit** `.git/hooks/*` or `node_modules/`
5. **Document team workflow** in your repository's README

## Reference

- [Pre-commit Framework Documentation](https://pre-commit.com/)
- [Commitlint Documentation](https://commitlint.js.org/)
- [HyperFleet Commit Standard](https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md)
- [Conventional Commits Specification](https://www.conventionalcommits.org/)
