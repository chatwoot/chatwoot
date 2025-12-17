---
description: Create an event in ZeroDB event stream
---

Use the mcp__ainative-zerodb__zerodb_create_event tool to publish events.

Example usage:
- Log application events
- Trigger workflows
- Track user actions
- Publish notifications

Key parameters:
- event_type: Event type/category (required)
- event_data: Event payload data object (required)
- source: Event source identifier (optional)
- correlation_id: Correlation ID for tracking (optional)

Ask the user what event to create, then use the tool to publish it.
