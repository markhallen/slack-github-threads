---
paths:
  - "lib/helpers/**/*.rb"
---

# Slack Modal Conventions

- Modals use Slack Block Kit format — return Ruby hashes that serialize to JSON
- Two modal types: `global_shortcut_modal` (needs both thread URL and issue URL inputs) and `message_shortcut_modal` (only needs issue URL, thread context passed via `private_metadata`)
- `private_metadata` carries `channel_id` and `thread_ts` as JSON between shortcut trigger and submission
- Callback IDs follow the pattern `gh_comment_modal_<type>` — these are matched in `app.rb` to route submissions
- Use `plain_text_input` elements with `block_id`/`action_id` pairs for form fields
