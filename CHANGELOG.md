# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial open source release
- MIT License
- Contributing guidelines
- Security policy
- GitHub Actions CI/CD pipeline
- Issue and PR templates

### Changed

- Generalized deployment configuration
- Updated documentation for open source community

## [1.0.0] - 2025-08-02

### ✨ Features

- implement comprehensive logging system with security fixes
- add logo to README
- convert deployment config to sample template
- update Dependabot configuration for new requirements (#5)
- add comprehensive automated release system with GitHub Actions (#8)

### 🔧 Other Changes

- Add initial implementation of GitHub Commenter with Slack integration
- Add health check endpoint for service status
- Fix deployment issues and add health check
- Add shortcut endpoint to handle GitHub comments from Slack threads
- Refactor shortcut endpoint to handle Slack modal for GitHub issue submission
- Enhance shortcut endpoint to validate GitHub issue URLs and improve error handling
- Improve error handling in GitHub comment posting
- Add minimal debugging for thread messages
- Add debugging output for thread messages in shortcut endpoint
- Fix global shortcut to ask for thread URL
- Refactor shortcut endpoint for improved readability and formatting
- Fix HTML entity decoding in Slack messages
- Fix HTML entity decoding in thread messages for ghcomment and shortcut endpoints
- Add real user names and fix formatting in GitHub comments
- Fix HTML entity decoding and improve user name handling in messages
- Add debugging for user name resolution
- Add Slack reply with GitHub comment link after posting
- Add message shortcut endpoint with automatic context detection
- Consolidate shortcuts into single endpoint with different callback IDs
- Fix user mentions in messages - replace <@U094SJ77G3T> with @username
- Add debug logging to troubleshoot Slack API responses
- Add better error handling and early return for empty messages
- Improve error messages for channel membership issues
- Add automatic channel joining and expanded OAuth scopes
- Update README with additional OAuth scopes and improve formatting
- Fix message shortcut response format to prevent Slack error alert
- Major refactor: Implement Sinatra best practices with service layer and comprehensive tests
- Fix lint offenses
- Rename the repo to slack-github-threads
- Add issue templates, CI/CD configuration, security policy, and documentation
- Add rubocop
- Introduce logging
- Add a logo image
- Replace auto-merge workflow with Dependabot solution (#7)
- Update GitHub Sponsors username (#6)
- docker(deps): bump ruby from 3.2 to 3.4 (#1)
- deps(deps): bump puma from 6.6.0 to 6.6.1 in the patch-updates group (#2)
## [1.0.0] - 2025-08-02

### Added

- Slack slash command integration for posting thread conversations to GitHub issues
- GitHub API integration for creating issue comments
- Slack Bot token and GitHub token authentication
- Thread message collection and formatting
- User mention resolution in Slack messages
- HTML entity decoding for proper message display
- Slack shortcuts (global and message) support
- Modal interfaces for GitHub URL input
- Comprehensive test suite with WebMock for API stubbing
- Docker support with Dockerfile
- Kamal deployment configuration
- Health check endpoint
- Error handling and validation
- Service layer architecture with separation of concerns

### Technical Details

- Ruby Sinatra web framework
- Modular service architecture (SlackService, GitHubService, CommentService)
- Text processing utilities for message formatting
- Modal builder helpers for Slack UI components
- Comprehensive test coverage using Minitest
- Environment-based configuration management