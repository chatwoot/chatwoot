---
description: List events from ZeroDB event stream
---

Use the mcp__ainative-zerodb__zerodb_list_events tool to query events.

Example usage:
- View event history
- Filter by type or source
- Query time ranges

Key parameters:
- event_type: Filter by event type (optional)
- source: Filter by source (optional)
- start_time: ISO timestamp - events after this time (optional)
- end_time: ISO timestamp - events before this time (optional)
- limit: Maximum results (default: 100)
- offset: Pagination offset (default: 0)

Use this tool to show the user their events.
