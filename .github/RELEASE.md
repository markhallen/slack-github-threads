# Release Configuration

This project provides multiple release workflows: fully automated GitHub Actions, local Rake tasks, and interactive scripts.

## 🚀 Automated GitHub Actions Release (Recommended)

The easiest way to create releases using GitHub's web interface.

### Quick Start

1. **Navigate to** [Actions tab](https://github.com/markhallen/slack-github-threads/actions)
2. **Click** "Create Release PR" workflow
3. **Click** "Run workflow" button
4. **Choose options**:
   - **Release Type**: `auto` (recommended), `major`, `minor`, or `patch`
   - **Dry Run**: Check this to preview without creating actual release
5. **Click** "Run workflow"
6. **Review and merge** the automatically created PR
7. **Release publishes automatically** when PR is merged

### What the GitHub Action Does

1. **Analyzes commits** since last release
2. **Suggests appropriate version bump** (if `auto` selected)
3. **Runs full test suite** to ensure quality
4. **Generates changelog** from conventional commits
5. **Creates release branch** with version bump
6. **Opens PR** with detailed release information
7. **Auto-releases** when PR is merged

### Workflow Options

| Option    | Description                                       | When to Use                   |
| --------- | ------------------------------------------------- | ----------------------------- |
| `auto`    | System analyzes commits and suggests release type | Most releases                 |
| `major`   | Force major version bump (breaking changes)       | API changes, major refactors  |
| `minor`   | Force minor version bump (new features)           | New functionality             |
| `patch`   | Force patch version bump (bug fixes)              | Bug fixes, small improvements |
| `dry_run` | Preview mode - no actual release created          | Testing, planning             |

## 🧠 Local Rake Tasks

For developers who prefer command-line workflows.

### Key Features

1. **Automatic Changelog Generation**: Parses git commit messages since the last tag
2. **Conventional Commit Support**: Categorizes commits based on conventional commit patterns
3. **Integrated Testing**: Runs full CI checks before creating releases
4. **Git Tag Management**: Automatically creates and manages version tags

## Creating a Release

### Method 1: Rake Task (Recommended)

```bash
# Preview unreleased changes
rake release:preview

# Create release with automatic changelog generation
rake release:create[1.1.0]

# Push changes and tag
git push origin main && git push origin v1.1.0
```

### Method 2: Release Script

```bash
# One command that handles everything including the push
./scripts/release.sh 1.1.0
```

## Commit Message Conventions

The automatic changelog generation works best with conventional commit messages:

| Commit Pattern               | Changelog Section | Example                            |
| ---------------------------- | ----------------- | ---------------------------------- |
| `feat:`, `add`, `implement`  | **Added**         | `feat: add webhook support`        |
| `fix:`, `bug`, `resolve`     | **Fixed**         | `fix: resolve timeout issue`       |
| `chore:`, `update`, `change` | **Changed**       | `chore: update dependencies`       |
| `docs:`, `documentation`     | **Changed**       | `docs: improve API documentation`  |
| `remove`, `delete`           | **Removed**       | `remove: delete deprecated method` |
| `security`, `sec:`           | **Security**      | `security: fix XSS vulnerability`  |

## Manual Changelog Updates

If you prefer manual changelog management:

1. Edit `CHANGELOG.md` directly with your changes
2. Use `rake release:create[1.1.0]` - it will preserve manual entries
3. The Rake task will add the version and date automatically

## Release Checklist

Before creating a release, ensure:

- [ ] All tests pass locally
- [ ] CHANGELOG.md is updated with the new version
- [ ] Version follows semantic versioning (MAJOR.MINOR.PATCH)
- [ ] Documentation is up to date
- [ ] No sensitive information is included in the release

## Manual Release (if needed)

If you need to create a release manually:

1. Go to the [Releases page](https://github.com/markhallen/slack-github-threads/releases)
2. Click "Create a new release"
3. Choose your tag or create a new one
4. Fill in the release title and description
5. Upload any additional assets if needed

## Version Tag Format

Always use the format `v<MAJOR>.<MINOR>.<PATCH>` for version tags:

- `v1.0.0` - Major release
- `v1.1.0` - Minor release
- `v1.0.1` - Patch release
