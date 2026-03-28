---
name: release
description: Walk through the release process - preview changelog, bump version, create PR
disable-model-invocation: true
argument-hint: "[major|minor|patch]"
---

Create a release for this project. The bump type is: $ARGUMENTS (default to what `rake release:preview` suggests if not specified).

Steps:

1. Run `bundle exec rake release:preview` to show the current version, suggested bump type, and changelog preview
2. Confirm the bump type with the user before proceeding
3. Ensure the working directory is clean (`git status`)
4. Run `bundle exec rake ci` to verify all checks pass
5. Run `bundle exec rake release:$ARGUMENTS` to create the release (this bumps version, updates CHANGELOG.md, and creates a git tag)
6. Show the user the final commands to push: `git push origin main && git push origin <tag>`

Do NOT push automatically — let the user decide when to push.
