#!/usr/bin/env bash
# PreCompact backstop: fires when Claude Code auto-compacts the conversation.
# Auto-compaction summarizes earlier turns — detail is lost and hallucination risk peaks.
# Emits a user-visible systemMessage. (context-mode's own PreCompact snapshot still runs too.)
set -euo pipefail
cat >/dev/null  # drain stdin payload; we don't need its fields here
printf '%s\n' '{"systemMessage":"⚠ Context auto-compacting — earlier detail is being summarized and specifics may be lost. Re-confirm critical facts before acting, and run ctx_search (sources: compaction, decision) to recover prior context."}'
