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
