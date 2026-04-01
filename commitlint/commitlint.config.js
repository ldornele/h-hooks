/**
 * Shared Commitlint Configuration for HyperFleet
 *
 * This is the SINGLE SOURCE OF TRUTH for commit message validation
 * across all HyperFleet repositories.
 *
 * Enforces HyperFleet Commit Message Standard:
 * https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md
 *
 * Valid formats:
 * - HYPERFLEET-XXX - type: subject
 * - type: subject (when no JIRA ticket)
 *
 * Used by:
 * - Local pre-commit hooks (via .pre-commit-config.yaml)
 * - Prow CI jobs (via .prow.yaml)
 * - Individual repository commitlint configs (extends this file)
 */

module.exports = {
  extends: ['@commitlint/config-conventional'],

  rules: {
    // Header format allows optional HYPERFLEET-XXX prefix
    // Total header length (including ticket prefix) must not exceed 100 characters
    'header-max-length': [2, 'always', 100],

    // Subject line (excluding ticket prefix) must not exceed 72 characters
    // This ensures readability in git log, GitHub UI, and terminal output
    'subject-max-length': [2, 'always', 72],

    // Enforce lowercase for type
    'type-case': [2, 'always', 'lower-case'],

    // Allowed types per HyperFleet standard
    // Includes standard Conventional Commits types plus HyperFleet extensions
    'type-enum': [
      2,
      'always',
      [
        'feat',      // New feature
        'fix',       // Bug fix
        'docs',      // Documentation changes
        'style',     // Code style (HyperFleet extension: gofmt, goimports)
        'refactor',  // Code restructuring
        'perf',      // Performance improvements (HyperFleet extension)
        'test',      // Adding tests
        'build',     // Build system changes
        'ci',        // CI configuration
        'chore',     // Other changes
        'revert'     // Reverting commits
      ]
    ],

    // Subject must not be empty
    'subject-empty': [2, 'never'],

    // Subject must not end with period
    'subject-full-stop': [2, 'never', '.'],

    // Subject should start with lowercase (after type:)
    'subject-case': [2, 'always', 'lower-case'],

    // Type must not be empty
    'type-empty': [2, 'never'],

    // Body must have leading blank line if present
    'body-leading-blank': [2, 'always'],

    // Footer must have leading blank line if present
    'footer-leading-blank': [2, 'always'],

    // Scope is optional
    'scope-empty': [0],

    // Scope should be lowercase if provided
    'scope-case': [2, 'always', 'lower-case']
  },

  // Custom parser to handle HYPERFLEET-XXX prefix
  parserPreset: {
    parserOpts: {
      // Matches:
      // - HYPERFLEET-123 - feat: description
      // - feat: description
      // - feat(scope): description
      // - HYPERFLEET-123 - feat(scope): description
      headerPattern: /^(?:HYPERFLEET-\d+\s+-\s+)?(\w+)(?:\(([^)]*)\))?:\s+(.+)$/,
      headerCorrespondence: ['type', 'scope', 'subject']
    }
  },

  // Ignore automatically generated commit messages
  ignores: [
    (commit) => commit.startsWith('Merge branch'),
    (commit) => commit.startsWith('Merge pull request'),
    (commit) => commit.startsWith('Revert "'),
    (commit) => commit.includes('Initial commit')
  ],

  // Custom help URL pointing to HyperFleet documentation
  helpUrl: 'https://github.com/openshift-hyperfleet/architecture/blob/main/hyperfleet/standards/commit-standard.md',

  // Default severity level
  defaultIgnores: true,

  // Fail on warnings (strict mode)
  prompt: {
    settings: {},
    messages: {},
    questions: {
      type: {
        description: 'Select the type of change',
        enum: {
          feat: {
            description: 'A new feature',
            title: 'Features',
            emoji: '✨'
          },
          fix: {
            description: 'A bug fix',
            title: 'Bug Fixes',
            emoji: '🐛'
          },
          docs: {
            description: 'Documentation only changes',
            title: 'Documentation',
            emoji: '📚'
          },
          style: {
            description: 'Code style changes (formatting, gofmt)',
            title: 'Styles',
            emoji: '💎'
          },
          refactor: {
            description: 'Code change that neither fixes a bug nor adds a feature',
            title: 'Code Refactoring',
            emoji: '📦'
          },
          perf: {
            description: 'Performance improvements',
            title: 'Performance Improvements',
            emoji: '🚀'
          },
          test: {
            description: 'Adding or correcting tests',
            title: 'Tests',
            emoji: '🚨'
          },
          build: {
            description: 'Changes to build system or dependencies',
            title: 'Builds',
            emoji: '🛠'
          },
          ci: {
            description: 'Changes to CI configuration',
            title: 'Continuous Integrations',
            emoji: '⚙️'
          },
          chore: {
            description: 'Other changes that don\'t modify src or test files',
            title: 'Chores',
            emoji: '♻️'
          },
          revert: {
            description: 'Reverting a previous commit',
            title: 'Reverts',
            emoji: '🗑'
          }
        }
      }
    }
  }
};
