# Once Platform Deployment

This application is compatible with [37signals' Once](https://once.com/) platform.

## Compatibility

The app meets all Once requirements:

| Requirement | Status |
|-------------|--------|
| Docker container | Yes |
| HTTP on port 80 | Yes |
| Health check at `/up` | Yes (returns 200 OK) |
| Persistent data in `/storage` | Yes (logs only) |

## Environment Variables

**Required** (set in Once admin UI):

- `SLACK_BOT_TOKEN` — Slack bot token (starts with `xoxb-`)
- `GITHUB_TOKEN` — GitHub personal access token (starts with `ghp_`)

**Automatically provided by Once:**

- `NUM_CPUS` — Used to set Puma worker count (falls back to `WEB_CONCURRENCY`, then default of 2)
- `SECRET_KEY_BASE` — Injected but not used by this app
- `DISABLE_SSL` — Injected but not used (SSL is handled by the reverse proxy)

## Storage

The app is stateless — no database or file uploads. The `/storage` volume is used only for log files at `/storage/log/`. When running outside Once, logs fall back to `log/` in the app directory.

## Backup and Restore

The Once hook scripts at `/hooks/pre-backup` and `/hooks/post-restore` are no-ops because the app has no stateful data to back up. Source files are in `once/hooks/` in the repository.
