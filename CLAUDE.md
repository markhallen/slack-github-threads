# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Slack-github-threads is a Ruby Sinatra app that exports Slack thread conversations as comments on GitHub issues. Users trigger it via a `/ghcomment` slash command or Slack shortcuts (global and message).

## Common Commands

```bash
bundle install                  # Install dependencies
bundle exec rake test           # Run all tests
bundle exec rake test_services  # Run service unit tests only
bundle exec rake test_app       # Run integration tests only
bundle exec rake ci             # Full CI: syntax + rubocop + tests
bundle exec rake rubocop        # Lint only
bundle exec rake lint           # Syntax check + rubocop
bundle exec rake server         # Start dev server
bundle exec rake config         # Manage multi-project integrations (TUI)
DEBUG=true bundle exec ruby app.rb  # Run with debug logging
```

To run a single test file: `bundle exec ruby test/services/test_text_processor.rb`

## Architecture

```
Slack (slash command / shortcut)
  → app.rb (Sinatra routing, 3 endpoints: GET /up, POST /ghcomment, POST /shortcut)
    → resolve_tokens(team_id) → ProjectConfig lookup or ENV fallback
    → CommentService (orchestration)
      ├→ SlackService (fetch thread via conversations.replies, resolve user mentions)
      ├→ TextProcessor (format messages: HTML entity decoding, @mention replacement)
      └→ GitHubService (POST comment to issue via REST API)
```

- **app.rb** — Entry point. Routes requests, resolves credentials by team_id, delegates to CommentService.
- **lib/config/encryption.rb** — AES-256-GCM encryption/decryption with PBKDF2 key derivation (stdlib only).
- **lib/config/project_config.rb** — Multi-project config model: CRUD, encrypted file I/O, team_id lookup.
- **lib/cli/tui.rb** — Interactive TUI (tty-prompt) for managing project integrations.
- **lib/services/comment_service.rb** — Orchestrates the flow: fetch thread → format → post to GitHub → reply in Slack.
- **lib/services/slack_service.rb** — Slack API client (Net::HTTP). Auto-joins channels if bot isn't a member.
- **lib/services/github_service.rb** — GitHub API client (Net::HTTP). Parses issue URLs to extract org/repo/number.
- **lib/services/text_processor.rb** — Converts Slack message formatting to GitHub-compatible markdown.
- **lib/helpers/modal_builder.rb** — Constructs Slack Block Kit modals for shortcut flows.
- **lib/version_helper.rb** — Semantic versioning and changelog generation from conventional commits.
- **bin/slack-gh-config** — CLI entry point for the project configuration TUI.

All API calls use Ruby's native `Net::HTTP` — no external HTTP client gems.

## Testing

- Framework: Minitest with `Minitest::Spec` style
- HTTP mocking: WebMock (all external calls must be stubbed)
- `test/test_helper.rb` provides shared fixtures (`slack_message`, `slack_thread_response`) and stub helpers (`stub_slack_conversations_replies`, `stub_github_create_comment`)
- Integration tests use `Rack::Test` against the Sinatra app

## Environment Variables

Required (single-project mode): `SLACK_BOT_TOKEN` (xoxb-*), `GITHUB_TOKEN` (ghp_*)
Optional: `DEBUG` (true/false), `RACK_ENV`, `PORT` (default 3000), `CONFIG_PASSPHRASE` (for multi-project mode)

## Code Style

RuboCop enforced. Key rules: 120-char line limit, 20-line method limit, single quotes preferred. Uses rubocop-minitest and rubocop-rake plugins.

## Commit Conventions

Uses conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `perf:`, `style:`. Breaking changes use `feat!:` or `BREAKING CHANGE:` footer. These drive automatic version bumping (major/minor/patch).
