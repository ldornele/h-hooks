# Setting Up Prow Jobs for Commitlint Validation

This guide explains how to configure Prow CI jobs for commit message validation in HyperFleet repositories.

## Overview

Prow jobs provide **automated enforcement** in CI, acting as the source of truth that blocks non-compliant PRs from merging — even if developers skip local hooks.

## Prerequisites

- Access to Prow cluster configuration
- Repository registered in Prow
- GitHub repository with pull request workflow

## Architecture

```
Pull Request Created
       ↓
Prow Detects PR
       ↓
Triggers Commitlint Presubmit Job
       ↓
Job Downloads Centralized Config from h-hooks
       ↓
Validates All Commits in PR
       ↓
Reports Pass/Fail to GitHub
       ↓
Blocks Merge if Failed
```

## Setup Steps

### 1. Copy Prow Job Template

From the h-hooks repository, copy the template to your repository:

```bash
cd /path/to/your/hyperfleet-repository
cp /path/to/h-hooks/prow/commitlint-job.yaml .prow.yaml
```

### 2. Customize for Your Repository

Edit `.prow.yaml` and update the repository name:

```yaml
presubmits:
  # BEFORE: openshift-hyperfleet/<REPOSITORY-NAME>
  # AFTER:
  openshift-hyperfleet/hyperfleet-sentinel:
    - name: commitlint
      # ... rest of configuration
```

### 3. Install Commitlint Dependencies

Add to your `package.json`:

```json
{
  "name": "hyperfleet-sentinel",
  "version": "1.0.0",
  "private": true,
  "devDependencies": {
    "@commitlint/cli": "^19.6.0",
    "@commitlint/config-conventional": "^19.6.0"
  }
}
```

**Why?** The Prow job runs `npm ci` to install dependencies. While the job could install them on the fly, pre-declaring them in `package.json`:
- Locks versions for consistency
- Speeds up job execution (npm caches)
- Documents dependencies clearly

### 4. Create Commitlint Config

Create `commitlint.config.js` in your repository root that extends the centralized config:

```javascript
// This file is used by local pre-commit hooks and as fallback
// The Prow job downloads the centralized config directly from h-hooks
module.exports = {
  extends: ['@commitlint/config-conventional'],

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

  helpUrl: 'https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md'
};
```

### 5. Commit and Push

```bash
git add .prow.yaml package.json commitlint.config.js
git commit -m "HYPERFLEET-813 - ci: add commitlint prow job"
git push origin main
```

### 6. Test with a Pull Request

Create a test PR with both valid and invalid commits to verify the job runs:

**Test 1: Valid commit**
```bash
git checkout -b test-commitlint-valid
echo "test" > test.txt
git add test.txt
git commit -m "HYPERFLEET-813 - test: verify commitlint validation"
git push origin test-commitlint-valid
# Create PR on GitHub
```

Expected: ✅ Prow job passes

**Test 2: Invalid commit**
```bash
git checkout -b test-commitlint-invalid
echo "test2" > test2.txt
git add test2.txt
git commit -m "Add test file"  # Invalid format
git push origin test-commitlint-invalid
# Create PR on GitHub
```

Expected: ❌ Prow job fails with helpful error message

## How the Prow Job Works

### Job Execution Flow

1. **Triggered:** Pull request opened/updated
2. **Container starts:** `node:18-alpine` image
3. **Downloads config:** Fetches `commitlint.config.js` from h-hooks repo
4. **Installs dependencies:** Runs `npm ci`
5. **Validates commits:** Runs `commitlint --from BASE_SHA --to HEAD_SHA`
6. **Reports result:** Updates PR status check on GitHub

### Environment Variables

Prow automatically provides:

| Variable | Description | Example |
|----------|-------------|---------|
| `PULL_BASE_SHA` | Base commit of PR | `abc1234...` |
| `PULL_PULL_SHA` | Head commit of PR | `def5678...` |
| `REPO_OWNER` | Repository owner | `openshift-hyperfleet` |
| `REPO_NAME` | Repository name | `hyperfleet-sentinel` |
| `PULL_NUMBER` | PR number | `42` |

### Configuration Options

Key sections in `.prow.yaml`:

```yaml
presubmits:
  openshift-hyperfleet/hyperfleet-sentinel:
    - name: commitlint              # Job name (appears in GitHub)
      cluster: default               # Prow cluster to run on
      always_run: true               # Run on every PR
      skip_report: false             # Report status to GitHub
      decorate: true                 # Use Prow decorators
      decoration_config:
        timeout: 5m                  # Max runtime
        grace_period: 15s            # Cleanup time
```

## Advanced Configuration

### Using Custom h-hooks Version

To test changes from a specific h-hooks branch:

```yaml
# In .prow.yaml, modify the download URL:
HOOKS_REPO_URL="https://raw.githubusercontent.com/openshift-hyperfleet/h-hooks/feature-branch"
```

### Running Additional Validation

Add more steps to the Prow job:

```yaml
command:
  - /bin/sh
  - -c
  - |
    # Commitlint validation
    npm ci
    npx commitlint --from="${PULL_BASE_SHA}" --to="${PULL_PULL_SHA}"

    # Additional validation (e.g., PR title)
    if ! echo "${PULL_TITLE}" | grep -E '^HYPERFLEET-[0-9]+'; then
      echo "PR title must start with HYPERFLEET-XXX"
      exit 1
    fi
```

### Customizing Error Messages

Modify the failure message in `.prow.yaml` to add repository-specific guidance.

## Troubleshooting

### Job Not Running

**Check Prow configuration:**
```bash
# Verify .prow.yaml is in repository root
ls -la .prow.yaml

# Check syntax
yamllint .prow.yaml
```

**Check Prow logs:**
Visit Prow dashboard and search for your repository.

### Job Failing to Download Config

**Issue:** Config download fails

**Solution:** Verify h-hooks repository is public or Prow has access:
```bash
curl https://raw.githubusercontent.com/openshift-hyperfleet/h-hooks/main/commitlint/commitlint.config.js
```

### Different Results Than Local

**Issue:** Local pre-commit passes but Prow fails (or vice versa)

**Causes:**
1. Different commitlint versions
2. Different config files
3. Local hooks checking different commits

**Solution:**
```bash
# Match versions
npm list @commitlint/cli
# Should match version in Prow job

# Use same config
diff commitlint.config.js /path/to/h-hooks/commitlint/commitlint.config.js

# Test same commit range
npx commitlint --from origin/main --to HEAD
```

### Job Timeout

**Issue:** Job exceeds 5-minute timeout

**Solution:** Increase timeout in `.prow.yaml`:
```yaml
decoration_config:
  timeout: 10m  # Increased from 5m
```

## Monitoring and Metrics

### Prow Dashboard

View job status at Prow dashboard:
- Job history
- Logs
- Success/failure rate
- Duration metrics

### Testgrid Integration

Configure Testgrid for historical tracking:

```yaml
annotations:
  testgrid-dashboards: "hyperfleet"
  testgrid-tab-name: "commitlint"
  testgrid-alert-email: "team@example.com"
```

## Best Practices

1. **Pin h-hooks version** — Reference specific tags in production
2. **Test before merging** — Verify Prow job works with test PRs
3. **Keep configs in sync** — Local and CI should use same rules
4. **Monitor job duration** — Optimize if jobs become slow
5. **Document exceptions** — If you modify the template, document why

## Migration from GitHub Actions

If migrating from GitHub Actions to Prow:

1. Keep both temporarily for validation
2. Compare results across 5-10 PRs
3. Remove GitHub Actions workflow once Prow is stable
4. Update documentation

See [migration-guide.md](./migration-guide.md) for detailed steps.

## Reference

- [Prow Job Documentation](https://docs.prow.k8s.io/docs/jobs/)
- [Prow Configuration](https://docs.prow.k8s.io/docs/config/)
- [HyperFleet Commit Standard](https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md)
