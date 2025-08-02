# Contributing to Slack GitHub Threads

Thank you for your interest in contributing to Slack GitHub Threads! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/slack-github-threads.git
   cd slack-github-threads
   ```
3. Install dependencies:
   ```bash
   bundle install
   ```
4. Set up your environment variables by copying `.env.example` to `.env` and filling in your tokens

## Development Workflow

### Running the Application Locally

1. Start the server:

   ```bash
   bundle exec rake server
   ```

   Or directly:

   ```bash
   bundle exec ruby app.rb
   ```

2. Use ngrok to expose your local server for Slack webhook testing:
   ```bash
   ngrok http 3000
   ```

### Running Tests

```bash
# Run all CI checks locally (recommended before submitting PR)
bundle exec rake ci

# Individual commands
bundle exec rake rubocop     # Run RuboCop linter
bundle exec rake test        # Run all tests
bundle exec rake syntax      # Check syntax only

# Run specific test groups
bundle exec rake test_services
bundle exec rake test_app
```

**💡 Pro tip**: Always run `bundle exec rake ci` before submitting a PR to ensure your changes pass the same checks as our CI system!

## Code Style and Standards

- Follow Ruby community conventions
- Use meaningful variable and method names
- Add comments for complex logic
- Keep methods small and focused
- Write tests for new functionality

## Testing

- All new features should include tests
- Tests use Minitest with WebMock for API stubbing
- Maintain test coverage for critical paths
- Test both success and error scenarios

## Submitting Changes

1. Create a feature branch from `main`:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes with descriptive commit messages:

   ```bash
   git commit -m "Add feature: description of what you added"
   ```

3. Push to your fork:

   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a Pull Request with:
   - Clear description of changes
   - Why the change is needed
   - Any breaking changes
   - Screenshots/examples if applicable

## Code Review Process

- All submissions require review before merging
- We may ask for changes or improvements
- Be patient and responsive to feedback
- Discussions should be constructive and respectful

## Automated Processes

### Dependabot

- Dependabot automatically creates PRs for dependency updates
- Patch updates and security fixes are auto-merged after CI passes
- Major/minor updates require manual review

### CI/CD

- All PRs must pass CI checks (tests, linting, security)
- GitHub Actions runs tests on multiple Ruby versions
- Security scanning is performed on all changes

## Reporting Issues

When reporting bugs or requesting features:

1. Check if the issue already exists
2. Use the issue template (if available)
3. Provide clear steps to reproduce (for bugs)
4. Include relevant error messages and logs
5. Describe your environment (Ruby version, OS, etc.)

## Security

- Never commit tokens, secrets, or credentials
- Report security vulnerabilities privately
- Use environment variables for sensitive data

## Questions?

Feel free to open an issue for questions about contributing or the codebase.

Thank you for contributing! 🎉
