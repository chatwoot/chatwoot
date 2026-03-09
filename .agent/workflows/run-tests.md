---
description: Run Ruby specs inside the Docker container
---

## Run Ruby Tests

Tests MUST run inside the Docker container (host has no DB access).

// turbo-all

1. Verify containers are running:
```bash
docker ps --format '{{.Names}}' | grep chatwitv410
```

2. If containers are NOT running, start them:
```bash
cd /home/wital/chatwitv4.10 && ./dev.sh start
```

3. Run the spec inside the container:
```bash
cd /home/wital/chatwitv4.10 && ./dev.sh shell -c "bundle exec rspec SPEC_FILE"
```

Replace `SPEC_FILE` with the actual spec path, e.g. `spec/services/whatsapp/providers/whatsapp_cloud_service_spec.rb`.

For a specific line:
```bash
cd /home/wital/chatwitv4.10 && ./dev.sh shell -c "bundle exec rspec SPEC_FILE:LINE"
```

> **Note:** If you see `PG::ConnectionBad`, you are running outside the container.
