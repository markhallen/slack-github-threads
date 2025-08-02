# slack-github-threads

[![CI](https://github.com/markhallen/slack-github-threads/actions/workflows/ci.yml/badge.svg)](https://github.com/markhallen/slack-github-threads/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <img src="docs/images/slack-github-threads-logo-white.png" alt="Slack GitHub Threads Logo" width="300">
</p>

A Slack slash command integration that posts Slack thread conversations as comments to GitHub issues.

## Overview

This Ruby Sinatra application provides a bridge between Slack and GitHub, allowing you to easily share Slack thread discussions as comments on GitHub issues. When you use the slash command with a GitHub issue URL, it will collect all messages in the current thread and post them as a formatted comment to the specified GitHub issue.

## Features

- 🔗 **Slack Integration**: Works as a Slack slash command
- 📝 **Thread Collection**: Captures entire Slack thread conversations
- 🐙 **GitHub Integration**: Posts formatted comments to GitHub issues
- 🚀 **Easy Deployment**: Configured for deployment with Kamal
- 🔒 **Secure**: Uses environment variables for sensitive tokens

## Prerequisites

- Ruby 3.2+
- Bundler
- A Slack app with bot token permissions
- A GitHub personal access token
- (Optional) Kamal for deployment

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/markhallen/slack-github-threads.git
   cd slack-github-threads
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Set up environment variables:

   ```bash
   cp .env.example .env
   # Edit .env with your tokens
   ```

4. (Optional) Set up Kamal deployment secrets:

   ```bash
   cp .kamal/secrets.example .kamal/secrets
   # Edit .kamal/secrets with your deployment credentials

   cp config/deploy.yml.example config/deploy.yml
   # Edit config/deploy.yml with your deployment settings
   ```

## Environment Variables

Create a `.env` file with the following variables:

```env
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
GITHUB_TOKEN=ghp_your-github-personal-access-token
DEBUG=false  # Optional: set to 'true' for debug logging
```

### Getting Tokens

#### Slack Bot Token

1. Go to [Slack API](https://api.slack.com/apps)
2. Create a new app or use an existing one
3. Go to "OAuth & Permissions"
4. Add the following bot token scopes:

   - `channels:history` - Read messages in public channels
   - `channels:read` - List public channels
   - `channels:join` - Join public channels automatically
   - `groups:history` - Read messages in private channels
   - `groups:read` - List private channels
   - `im:history` - Read direct messages
   - `mpim:history` - Read group direct messages
   - `users:read` - Get user information for name resolution
   - `chat:write` - Post reply messages

   **Note**: Even with these scopes, the bot may still need to be added to private channels manually.

5. Install the app to your workspace
6. Copy the "Bot User OAuth Token"

#### GitHub Token

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate a new token with the following permissions:
   - `repo` (for private repositories) or `public_repo` (for public repositories only)
3. Copy the generated token

## Usage

### Local Development

1. Start the server:

   ```bash
   bundle exec thin start -R config.ru -p 3000
   ```

2. Use a tool like ngrok to expose your local server:

   ```bash
   ngrok http 3000
   ```

3. Configure your Slack slash command to point to `https://your-ngrok-url.ngrok.io/ghcomment`

### Slack Slash Command Setup

1. In your Slack app configuration, go to "Slash Commands"
2. Create a new command (e.g., `/ghcomment`)
3. Set the Request URL to your application endpoint: `https://your-domain.com/ghcomment`
4. Configure the command to be used in channels and direct messages

### Using the Command

In a Slack thread, use the slash command with a GitHub issue URL:

```
/ghcomment https://github.com/owner/repo/issues/123
```

The bot will:

1. Collect all messages in the current thread
2. Format them with usernames
3. Post the formatted conversation as a comment on the specified GitHub issue

## Deployment

This project is configured for deployment using [Kamal](https://kamal-deploy.org/).

### Prerequisites for Deployment

1. Install Kamal:

   ```bash
   gem install kamal
   ```

2. Set up your secrets (see `.kamal/secrets` file)

3. Configure your deployment settings in `config/deploy.yml` (copy from `config/deploy.yml.example`)

### Deploy

```bash
kamal deploy
```

## Docker

You can also run the application using Docker:

```bash
# Build the image
docker build -t slack-github-threads .

# Run the container
docker run -p 3000:3000 --env-file .env slack-github-threads
```

## Project Structure

```
├── app.rb                      # Main Sinatra application
├── config.ru                   # Rack configuration
├── Gemfile                     # Ruby dependencies
├── Dockerfile                  # Docker configuration
├── Rakefile                    # Task definitions and test runner
├── lib/                        # Application modules
│   ├── services/               # Business logic services
│   │   ├── slack_service.rb    # Slack API interactions
│   │   ├── github_service.rb   # GitHub API interactions
│   │   ├── text_processor.rb   # Message formatting and parsing
│   │   └── comment_service.rb  # Main orchestration service
│   └── helpers/                # Helper modules
│       └── modal_builder.rb    # Slack modal construction
├── test/                       # Test suite
│   ├── test_helper.rb          # Test configuration and helpers
│   ├── test_app.rb             # Integration tests
│   └── services/               # Service unit tests
│       ├── test_slack_service.rb
│       ├── test_github_service.rb
│       └── test_text_processor.rb
├── config/
│   └── deploy.yml.example      # Kamal deployment configuration template
└── .kamal/
    └── secrets                 # Kamal secrets configuration
```

## Development

### Running Tests

```bash
# Run all CI checks (recommended for development)
bundle exec rake ci

# Individual commands
bundle exec rake rubocop     # Run RuboCop linter
bundle exec rake test        # Run all tests
bundle exec rake syntax      # Check syntax only

# Run specific test groups
bundle exec rake test_services
bundle exec rake test_app
```

### Debugging and Logging

The application includes comprehensive logging and debug capabilities:

#### Debug Mode

Enable debug mode to see detailed output during development:

```bash
# Enable debug mode (shows debug logs in console + log file)
DEBUG=true ruby app.rb

# Or set in your .env file
DEBUG=true
```

#### Log Files

The application automatically creates environment-specific log files:

- `log/development.log` - Development environment logs
- `log/production.log` - Production environment logs
- `log/test.log` - Test environment uses in-memory logging (no file created)

#### Log Levels

- **INFO**: Application startup, successful operations
- **DEBUG**: Detailed API interactions, debugging information (only when DEBUG=true)
- **ERROR**: Failures, exceptions, API errors

Example log output:

```log
I, [2025-08-02T09:55:53.928339 #94625]  INFO -- : Starting gh-commenter app (development)
D, [2025-08-02T09:56:15.123456 #94625] DEBUG -- : DEBUG: Successfully posted Slack reply
E, [2025-08-02T09:56:20.654321 #94625] ERROR -- : Failed to post comment: GitHub API rate limit exceeded
```

### Code Organization

The application follows Sinatra best practices with clear separation of concerns:

- **Services**: Handle external API interactions and business logic
- **Helpers**: Provide utility functions and UI components
- **Controllers**: Slim route handlers that delegate to services
- **Tests**: Comprehensive test coverage using Minitest with WebMock for API stubbing

## API Endpoints

- `GET /up` - Health check endpoint
- `POST /ghcomment` - Processes Slack slash command and posts to GitHub
- `POST /shortcut` - Handles Slack shortcuts (global and message) and modal submissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes
5. Submit a pull request

## Releases

This project supports multiple release workflows: automated GitHub Actions, smart Rake tasks, and interactive scripts.

### 🚀 GitHub Actions Release (Recommended)

Create releases directly from GitHub's web interface:

1. **Go to Actions tab** → **"Create Release PR"** workflow
2. **Click "Run workflow"** and choose:
   - `auto` - Let the system analyze commits and suggest release type
   - `major/minor/patch` - Specify release type manually
   - `dry_run` - Preview what would be released
3. **Review and merge** the created PR
4. **Release is automatically published** when PR merges

### 🧠 Smart Local Release Process

```bash
# Preview changes and get version suggestion
rake release:preview

# Create releases by type (automatic version bumping)
rake release:major    # Breaking changes (1.0.0 → 2.0.0)
rake release:minor    # New features (1.0.0 → 1.1.0)
rake release:patch    # Bug fixes (1.0.0 → 1.0.1)

# Push to trigger automated GitHub release
git push origin main && git push origin v<version>
```

### 🎯 Interactive Release Script

```bash
# Interactive script with smart suggestions
./scripts/release.sh

# Or specify release type directly
./scripts/release.sh minor
```

### Key Features

- **🤖 Fully Automated**: GitHub Actions handles everything including PR creation
- **🧠 Smart Version Detection**: Analyzes commits to suggest appropriate version bump
- **📝 Automatic Changelog**: Generates changelog from conventional commit messages
- **🚀 One-Click Releases**: Complete release process with testing and validation
- **📋 Preview Mode**: See what will be released before committing
- **👥 Team Friendly**: PR-based workflow for team review

### Commit Message Conventions

For optimal automatic changelog generation:

- `feat: add new feature` → **Added** section → **minor** version bump
- `fix: resolve bug` → **Fixed** section → **patch** version bump
- `feat!: breaking change` → **Added** section → **major** version bump
- `chore: update dependencies` → **Changed** section → **patch** version bump

See [docs/CONVENTIONAL_COMMITS.md](docs/CONVENTIONAL_COMMITS.md) for detailed commit message guidelines.

## Security

- Never commit tokens or secrets to the repository
- Use environment variables for all sensitive data
- Regularly rotate your API tokens
- Use HTTPS in production

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter any issues or have questions, please open an issue on GitHub.
