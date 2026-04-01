# Migration Guide: Moving to Centralized h-hooks

This guide helps HyperFleet repositories migrate from local commitlint configurations to the centralized h-hooks repository.

## Overview

**Before migration:** Each repository has its own commitlint config, GitHub Actions workflow, and possibly different validation rules.

**After migration:** All repositories reference h-hooks for:
- Shared commitlint configuration
- Reusable pre-commit hooks
- Standardized Prow job definitions

## Benefits of Migration

- **Consistency:** Same rules across all HyperFleet repos
- **Maintainability:** Update rules once in h-hooks, not in each repo
- **Fewer errors:** Eliminates config drift and copy-paste mistakes
- **Better DX:** Developers get same experience regardless of repo

## Migration Steps

### Step 1: Assess Current State

Check what your repository currently has:

```bash
# Check for existing commitlint config
ls -la commitlint.config.js .commitlintrc.* package.json

# Check for GitHub Actions
ls -la .github/workflows/commitlint.yml

# Check for pre-commit hooks
ls -la .pre-commit-config.yaml
```

Document current configuration to ensure no rules are lost.

### Step 2: Back Up Current Configuration

```bash
# Create backup branch
git checkout -b backup-commitlint-config

# Commit current state
git add .
git commit -m "chore: backup commitlint config before migration"
git push origin backup-commitlint-config
```

### Step 3: Install h-hooks Pre-commit

**Replace** `.pre-commit-config.yaml` with:

```yaml
repos:
  - repo: https://github.com/openshift-hyperfleet/h-hooks
    rev: v1.0.0  # Use latest release
    hooks:
      - id: commitlint
```

**Remove** any old local commitlint hooks:

```bash
# Delete old hook configurations
sed -i '/commitlint/d' .pre-commit-config.yaml  # If you have other hooks
```

### Step 4: Update Commitlint Config

**Option A: Extend centralized config (recommended)**

Replace `commitlint.config.js` with:

```javascript
// Extends centralized h-hooks configuration
// Keep local file for IDE support and local fallback
module.exports = {
  extends: ['@commitlint/config-conventional'],

  // Import rules from h-hooks
  // (In future, this will be: extends: ['@hyperfleet/commitlint-config'])
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

**Option B: Reference remote config**

Add to `package.json`:

```json
{
  "scripts": {
    "commitlint": "commitlint --config node_modules/@hyperfleet/commitlint-config/commitlint.config.js"
  }
}
```

(This requires h-hooks to publish an npm package — future enhancement)

### Step 5: Update package.json

Ensure dependencies are correct:

```json
{
  "devDependencies": {
    "@commitlint/cli": "^19.6.0",
    "@commitlint/config-conventional": "^19.6.0"
  }
}
```

Remove any old/unused dependencies:

```bash
npm uninstall husky  # If you were using husky
npm install
```

### Step 6: Migrate from GitHub Actions to Prow

**A. Copy Prow job template:**

```bash
cp /path/to/h-hooks/prow/commitlint-job.yaml .prow.yaml
```

**B. Update repository name:**

Edit `.prow.yaml`:

```yaml
presubmits:
  openshift-hyperfleet/YOUR-REPO-NAME:  # Update this
    - name: commitlint
      # ...
```

**C. Keep GitHub Actions temporarily:**

Don't delete `.github/workflows/commitlint.yml` immediately. Run both for a few PRs to validate consistency.

**D. Compare results:**

Create test PRs and verify both GitHub Actions and Prow:
- Produce same pass/fail results
- Show same error messages
- Have similar run times

**E. Remove GitHub Actions:**

Once Prow is validated:

```bash
git rm .github/workflows/commitlint.yml
git commit -m "ci: remove github actions commitlint (migrated to prow)"
```

### Step 7: Update Documentation

Update your repository's README.md:

**Before:**
```markdown
## Commit Message Format

We use commitlint to validate commit messages...
```

**After:**
```markdown
## Commit Message Format

We follow the HyperFleet Commit Standard enforced via centralized validation from [h-hooks](https://github.com/openshift-hyperfleet/h-hooks).

### Setup Local Validation

```bash
pip install pre-commit
pre-commit install --hook-type commit-msg
```

See [h-hooks documentation](https://github.com/openshift-hyperfleet/h-hooks/blob/main/docs/setup-local-hooks.md) for details.
```

### Step 8: Reinstall Git Hooks

```bash
# Uninstall old hooks
pre-commit uninstall
pre-commit uninstall --hook-type commit-msg

# Install new hooks
pre-commit install --hook-type commit-msg

# Test
echo "test: verify migration" | pre-commit run --hook-stage commit-msg
```

### Step 9: Test End-to-End

**Test 1: Local validation**

```bash
git checkout -b test-migration
echo "test" > test.txt
git add test.txt

# Should pass
git commit -m "HYPERFLEET-999 - test: verify commitlint works"

# Should fail
git commit -m "Test commit" && echo "FAIL: Should have rejected" || echo "PASS: Correctly rejected"
```

**Test 2: CI validation**

Push test branch and create PR:

```bash
git push origin test-migration
# Create PR on GitHub
# Verify Prow job runs and passes
```

### Step 10: Clean Up

Remove old configuration files:

```bash
# If you had these old configs
rm -f .commitlintrc.js .commitlintrc.json .commitlintrc.yml
rm -rf .husky/  # If you were using husky

git add -A
git commit -m "chore: clean up old commitlint config files"
```

## Migration Checklist

Use this checklist to track migration progress:

- [ ] Back up current configuration
- [ ] Update `.pre-commit-config.yaml` to reference h-hooks
- [ ] Update `commitlint.config.js` to match h-hooks rules
- [ ] Ensure `package.json` has correct dependencies
- [ ] Copy and customize `.prow.yaml`
- [ ] Test local pre-commit hooks work
- [ ] Test Prow job runs on PRs
- [ ] Verify GitHub Actions and Prow produce same results (if running both)
- [ ] Remove GitHub Actions workflow (after validation period)
- [ ] Update repository README
- [ ] Clean up old config files
- [ ] Notify team of changes

## Common Migration Issues

### Issue: Local hooks not running

**Cause:** Old hooks still installed

**Solution:**
```bash
pre-commit clean
pre-commit uninstall
pre-commit install --hook-type commit-msg
```

### Issue: Different results between local and CI

**Cause:** Version mismatch or config drift

**Solution:**
```bash
# Check versions
npm list @commitlint/cli

# Update to latest
npm install --save-dev @commitlint/cli@^19.6.0

# Verify config matches h-hooks
diff commitlint.config.js /path/to/h-hooks/commitlint/commitlint.config.js
```

### Issue: Prow job not running

**Cause:** Syntax error in `.prow.yaml`

**Solution:**
```bash
# Validate YAML
yamllint .prow.yaml

# Check Prow dashboard for errors
# Visit: https://prow.your-domain.com/?repo=YOUR-REPO
```

### Issue: Team resistance to stricter validation

**Cause:** New rules catch previously allowed patterns

**Solution:**
1. Document the migration in team channel
2. Provide examples of valid commit messages
3. Run validation in warning-only mode temporarily
4. Offer 1-on-1 help for developers struggling

## Rollback Plan

If migration causes issues:

```bash
# Restore from backup branch
git checkout main
git reset --hard backup-commitlint-config

# Or cherry-pick old config
git checkout backup-commitlint-config -- .github/workflows/commitlint.yml commitlint.config.js
git commit -m "chore: rollback commitlint migration"
```

## Timeline Recommendation

For a typical HyperFleet repository:

| Week | Activity |
|------|----------|
| 1 | Audit current config, create backup |
| 1 | Set up h-hooks pre-commit hooks |
| 1-2 | Run local validation alongside old setup |
| 2 | Deploy Prow job (keep GitHub Actions running) |
| 2-3 | Validate Prow job across 5-10 PRs |
| 3 | Remove GitHub Actions workflow |
| 3 | Update documentation, notify team |
| 4 | Clean up old files, close migration |

## Getting Help

- **Questions:** Open issue in h-hooks repository
- **Bug reports:** Include config files and error logs
- **Feature requests:** Propose in h-hooks discussions

## Post-Migration

After successful migration:

1. Monitor Prow job success rate
2. Collect feedback from developers
3. Report any issues to h-hooks maintainers
4. Consider contributing improvements back to h-hooks

## Reference

- [Setup Local Hooks](./setup-local-hooks.md)
- [Setup Prow Jobs](./setup-prow-jobs.md)
- [h-hooks README](../README.md)
