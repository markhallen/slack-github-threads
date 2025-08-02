# Conventional Commits Guide

This project uses conventional commits for automatic changelog generation.

## Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

- **feat**: A new feature (MINOR version bump)
- **fix**: A bug fix (PATCH version bump)
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools

## Examples

```bash
# New feature
git commit -m "feat: add webhook endpoint for GitHub events"

# Bug fix
git commit -m "fix: resolve timeout issue in Slack API calls"

# Documentation
git commit -m "docs: update installation instructions"

# Chore
git commit -m "chore: update Ruby to 3.3"

# Breaking change (MAJOR version bump)
git commit -m "feat!: change API response format

BREAKING CHANGE: The /api/threads endpoint now returns an array instead of an object"
```

## Changelog Mapping

| Commit Type                                          | Changelog Section   |
| ---------------------------------------------------- | ------------------- |
| `feat`                                               | Added               |
| `fix`                                                | Fixed               |
| `docs`, `style`, `refactor`, `perf`, `test`, `chore` | Changed             |
| Breaking changes                                     | Changed (with note) |

## Release Workflow

### 🚀 GitHub Actions (Recommended)

1. Make commits following conventional format
2. Go to **Actions** → **"Create Release PR"** → **"Run workflow"**
3. Choose release type (or use `auto` for smart suggestions)
4. Review and merge the created PR
5. Release is automatically published!

### 🧠 Local Development

1. Make commits following conventional format
2. Preview changes: `rake release:preview`
3. Create release by type:
   - `rake release:major` (or `./scripts/release.sh major`)
   - `rake release:minor` (or `./scripts/release.sh minor`)
   - `rake release:patch` (or `./scripts/release.sh patch`)
4. Push: `git push origin main && git push origin v<version>`

### Version Bumping Rules

| Commit Type                    | Version Bump | Example       |
| ------------------------------ | ------------ | ------------- |
| `feat!:` or `BREAKING CHANGE:` | **MAJOR**    | 1.0.0 → 2.0.0 |
| `feat:`                        | **MINOR**    | 1.0.0 → 1.1.0 |
| `fix:`                         | **PATCH**    | 1.0.0 → 1.0.1 |
| `chore:`, `docs:`, etc.        | **PATCH**    | 1.0.0 → 1.0.1 |

The system analyzes all unreleased commits and suggests the appropriate version bump automatically!
