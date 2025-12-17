---
description: Collect RLHF feedback for agent improvement
---

Use the mcp__ainative-zerodb__zerodb_rlhf_agent_feedback tool to record user feedback.

Example usage:
- Collect thumbs up/down feedback
- Record ratings
- Improve agent responses
- Train with human feedback

Key parameters:
- agent_id: Agent identifier (required)
- feedback_type: "thumbs_up", "thumbs_down", or "rating" (required)
- rating: Rating value 1-5 for rating type (optional)
- comment: Feedback comment (optional)
- context: Feedback context object (optional)

Ask the user for feedback, then use the tool to record it for learning.
