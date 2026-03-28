---
name: review-pr
description: Review a pull request for code style, architecture, and correctness
disable-model-invocation: true
context: fork
agent: Explore
argument-hint: "[PR number or URL]"
allowed-tools: Bash(gh *)
---

Review pull request $ARGUMENTS against this project's conventions.

## Gather context

- PR diff: !`gh pr view $ARGUMENTS --json additions,deletions,changedFiles`
- PR details: !`gh pr view $ARGUMENTS`
- Full diff: !`gh pr diff $ARGUMENTS`

## Review checklist

1. **Code style**: RuboCop compliance (120-char lines, 20-line methods, single quotes)
2. **Architecture**: Services stay in `lib/services/`, helpers in `lib/helpers/`. Services use Net::HTTP, not external HTTP gems
3. **Testing**: New functionality has corresponding tests. All HTTP calls are stubbed with WebMock. Tests use shared fixtures from `test_helper.rb`
4. **Commit messages**: Follow conventional commits format (`feat:`, `fix:`, `docs:`, etc.)
5. **Error handling**: API errors handled gracefully, debug logging via `debug_log`

## Output

Provide a structured review with:
- Summary of changes
- Issues found (if any), with file and line references
- Suggestions for improvement
- Overall assessment (approve / request changes)
