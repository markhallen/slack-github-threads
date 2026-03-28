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
DEBUG=true bundle exec ruby app.rb  # Run with debug logging
```

To run a single test file: `bundle exec ruby test/services/test_text_processor.rb`

## Architecture

```
Slack (slash command / shortcut)
  → app.rb (Sinatra routing, 3 endpoints: GET /up, POST /ghcomment, POST /shortcut)
    → CommentService (orchestration)
      ├→ SlackService (fetch thread via conversations.replies, resolve user mentions)
      ├→ TextProcessor (format messages: HTML entity decoding, @mention replacement)
      └→ GitHubService (POST comment to issue via REST API)
```

- **app.rb** — Entry point. Routes requests, validates params, delegates to CommentService.
- **lib/services/comment_service.rb** — Orchestrates the flow: fetch thread → format → post to GitHub → reply in Slack.
- **lib/services/slack_service.rb** — Slack API client (Net::HTTP). Auto-joins channels if bot isn't a member.
- **lib/services/github_service.rb** — GitHub API client (Net::HTTP). Parses issue URLs to extract org/repo/number.
- **lib/services/text_processor.rb** — Converts Slack message formatting to GitHub-compatible markdown.
- **lib/helpers/modal_builder.rb** — Constructs Slack Block Kit modals for shortcut flows.
- **lib/version_helper.rb** — Semantic versioning and changelog generation from conventional commits.

All API calls use Ruby's native `Net::HTTP` — no external HTTP client gems.

## Testing

- Framework: Minitest with `Minitest::Spec` style
- HTTP mocking: WebMock (all external calls must be stubbed)
- `test/test_helper.rb` provides shared fixtures (`slack_message`, `slack_thread_response`) and stub helpers (`stub_slack_conversations_replies`, `stub_github_create_comment`)
- Integration tests use `Rack::Test` against the Sinatra app

## Environment Variables

Required: `SLACK_BOT_TOKEN` (xoxb_*), `GITHUB_TOKEN` (ghp_*)
Optional: `DEBUG` (true/false), `RACK_ENV`, `PORT` (default 3000)

## Code Style

RuboCop enforced. Key rules: 120-char line limit, 20-line method limit, single quotes preferred. Uses rubocop-minitest and rubocop-rake plugins.

## Commit Conventions

Uses conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `perf:`, `style:`. Breaking changes use `feat!:` or `BREAKING CHANGE:` footer. These drive automatic version bumping (major/minor/patch).
