#!/usr/bin/env python3
"""PreToolUse hook: enterprise/ and spec/enterprise/ stay identical to upstream, so the
agent is told where the change goes instead of editing them. Merging an upstream release
does not go through Edit/Write, so it is unaffected."""
import json
import os
import sys

event = json.load(sys.stdin)
tool_input = event.get('tool_input') or {}
path = tool_input.get('file_path') or tool_input.get('notebook_path') or ''
root = os.path.realpath(os.environ.get('CLAUDE_PROJECT_DIR') or event.get('cwd') or os.getcwd())
relative = os.path.relpath(os.path.realpath(os.path.join(root, path)), root)

if relative.split(os.sep)[0] == 'enterprise' or relative.startswith(os.path.join('spec', 'enterprise') + os.sep):
    reason = (
        f'{relative} is upstream Enterprise code and stays identical to the release in VERSION_CW '
        '(CI and the pre-commit hook check it). The fork does not modify or patch Enterprise code: '
        'no edits here, and no prepend, class_eval or reopened Enterprise constant from outside '
        'enterprise/ either (bin/validate_enterprise_isolation checks that). Make the change '
        'in the CE code (app/, lib/) so it works the same with or without enterprise/.'
    )
elif relative.split(os.sep)[0] == 'fazer_ai_ee':
    reason = (
        f'{relative} would bring back fazer_ai_ee/, the overlay of Enterprise code the fork no longer '
        'keeps: changing Enterprise behavior, from any directory, is what the Enterprise license '
        'reserves to subscribers. Make the change in the CE code (app/, lib/) instead.'
    )
else:
    reason = None

if reason:
    print(json.dumps({'hookSpecificOutput': {
        'hookEventName': 'PreToolUse', 'permissionDecision': 'deny', 'permissionDecisionReason': reason
    }}))
