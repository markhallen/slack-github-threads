# GitHub Commenter

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
   git clone <your-repo-url>
   cd gh-commenter
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

## Environment Variables

Create a `.env` file with the following variables:

```env
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
GITHUB_TOKEN=ghp_your-github-personal-access-token
```

### Getting Tokens

#### Slack Bot Token

1. Go to [Slack API](https://api.slack.com/apps)
2. Create a new app or use an existing one
3. Go to "OAuth & Permissions"
4. Add the following bot token scopes:
   - `channels:history`
   - `groups:history`
   - `im:history`
   - `mpim:history`
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

3. Configure your deployment settings in `config/deploy.yml`

### Deploy

```bash
kamal deploy
```

## Docker

You can also run the application using Docker:

```bash
# Build the image
docker build -t gh-commenter .

# Run the container
docker run -p 3000:3000 --env-file .env gh-commenter
```

## Project Structure

```
├── app.rb              # Main Sinatra application
├── config.ru           # Rack configuration
├── Gemfile             # Ruby dependencies
├── Dockerfile          # Docker configuration
├── config/
│   └── deploy.yml      # Kamal deployment configuration
└── .kamal/
    └── secrets         # Kamal secrets configuration
```

## API Endpoints

- `POST /ghcomment` - Processes Slack slash command and posts to GitHub

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes
5. Submit a pull request

## Security

- Never commit tokens or secrets to the repository
- Use environment variables for all sensitive data
- Regularly rotate your API tokens
- Use HTTPS in production

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter any issues or have questions, please open an issue on GitHub.
