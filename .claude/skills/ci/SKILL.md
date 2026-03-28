---
name: ci
description: Run the full CI suite (syntax + rubocop + tests) and report results
allowed-tools: Bash(bundle exec *)
---

Run the full CI check suite:

```bash
bundle exec rake ci
```

Report the results clearly. If any step fails, identify which step failed and show the relevant error output.
