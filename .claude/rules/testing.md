---
paths:
  - "test/**/*.rb"
---

# Testing Rules

- Use `Minitest::Spec` style (`describe`/`it` blocks)
- All external HTTP calls must be stubbed with WebMock — `WebMock.disable_net_connect!` is enforced globally
- Use the shared fixtures and stub helpers from `test/test_helper.rb`:
  - Fixtures: `slack_message`, `slack_thread_response`, `slack_user_response`, `github_comment_response`, `slack_modal_payload`
  - Stubs: `stub_slack_conversations_replies`, `stub_slack_users_info`, `stub_slack_chat_post_message`, `stub_github_create_comment`
- Integration tests use `Rack::Test` — call endpoints via `get`, `post` etc. and the `app` method returns `Sinatra::Application`
- `setup` calls `WebMock.reset!` automatically — no need to repeat it
- Test env vars (`SLACK_BOT_TOKEN`, `GITHUB_TOKEN`) are set in `test_helper.rb`
