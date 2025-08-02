# Security Policy

## Supported Versions

We currently support the latest version of this project. Security updates will be applied to:

| Version  | Supported          |
| -------- | ------------------ |
| Latest   | :white_check_mark: |
| < Latest | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability, please report it privately.

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please email us at: [security@example.com] (replace with actual contact)

Please include the following information in your report:

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Any suggested fixes or mitigations

We will acknowledge receipt of your vulnerability report within 48 hours and provide a detailed response within 7 days indicating the next steps in handling your report.

## Security Best Practices

When using this application:

1. **Environment Variables**: Always use environment variables for sensitive data (tokens, secrets)
2. **HTTPS**: Use HTTPS in production environments
3. **Token Rotation**: Regularly rotate your API tokens
4. **Access Control**: Limit API token permissions to only what's necessary
5. **Updates**: Keep dependencies updated to get security patches

## Dependencies

We regularly monitor our dependencies for security vulnerabilities using:

- GitHub Security Advisories
- Ruby security mailing lists
- Automated dependency checking tools

If you notice a vulnerable dependency, please report it following the process above.
