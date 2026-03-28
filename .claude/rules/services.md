---
paths:
  - "lib/services/**/*.rb"
---

# Service Conventions

- All HTTP calls use Ruby's native `Net::HTTP` — do not add external HTTP client gems
- Services are plain Ruby classes initialized with tokens/config, no framework coupling
- Constructor pattern: `initialize(token, debug: false, logger: nil)`
- API clients define a private `api_request` method that handles GET/POST, auth headers, and JSON parsing
- Error handling: check response status/`ok` field, log via `debug_log`, return empty/false on failure rather than raising
- SlackService auto-joins channels on `not_in_channel` errors — preserve this retry pattern
