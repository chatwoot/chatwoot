#!/usr/bin/env python3
"""PreToolUse guard for ai-service (DEV-Johnstocker/chatwoot#1).

Enforces the hard rules in ai-service/AGENTS.md instead of trusting the text:

1. No push to `develop` (feature branch + PR only), no plain --force.
2. No --no-verify.
3. Never open, copy or edit the fork's `enterprise/` directory.
4. Never edit Chatwoot's own files: in the fork, writes are allowed only under
   `ai-service/` and to `.github/workflows/ai-service.yml`.
5. Never set SAFE_FETCH_ALLOW_PRIVATE_NETWORK.
6. The guard protects itself: no agent edits to .claude/hooks/ or
   .claude/settings*.json; the owner changes those by hand.

It also unwraps `env`, `VAR=1`, `nohup` and `sh -c '...'`, and refuses
`git -c core.hooksPath` / `-c alias.*` and `push --all/--mirror`.

Claude Code sends the tool call as JSON on stdin. Exit code 2 blocks the call
and shows stderr to the model; exit 0 lets it through. Anything the guard
cannot parse is let through, so a bug here never blocks ordinary work.

This is a guard rail, not a sandbox. A determined script (eval, a heredoc fed
to an interpreter, `sed -i` on Chatwoot files, a recursive search walking
enterprise/) can still get past it. The real control for `develop` is GitHub
branch protection; review still applies. Run the tests with
`python3 -m unittest discover -s ai-service/.claude/hooks`.
"""

import json
import os
import re
import shlex
import subprocess
import sys

FORK_REMOTE = "DEV-Johnstocker/chatwoot"
ALLOWED_PREFIXES = ("ai-service/",)
ALLOWED_FILES = (".github/workflows/ai-service.yml",)
PROTECTED_BRANCHES = ("develop",)

WRITE_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")
READ_TOOLS = ("Read", "Grep", "Glob")

SAFE_FETCH = re.compile(
    r"SAFE_FETCH_ALLOW_PRIVATE_NETWORK(\\*['\"])?\s*[:=]\s*(\\*['\"])?(true|1|yes|on)\b",
    re.IGNORECASE,
)
ENTERPRISE_PATH = re.compile(r"^(\./)?enterprise(/|$)", re.IGNORECASE)
# The guard protects itself: changing it needs the owner, outside an agent session.
GUARD_FILES = ("ai-service/.claude/hooks/", "ai-service/.claude/settings")
GUARD_MENTION = re.compile(r"guard\.py|\.claude/hooks|\.claude/settings", re.IGNORECASE)
SHELL_WRITE = re.compile(
    r">|\btee\b|\bsed\s+-[a-zA-Z]*i|\bperl\s+-[a-zA-Z]*i|\b(mv|cp|rm|ln|chmod|truncate|install|rsync|dd)\b|python3?\s+-c"
)
WRAPPERS = {"env", "command", "exec", "nohup", "time", "sudo", "nice", "xargs"}
SHELLS = {"sh", "bash", "zsh", "dash"}
GIT_CONFIG_BLOCKED = ("core.hookspath", "alias.")
GIT_CONFIG_ENV = re.compile(r"\bGIT_CONFIG_\w*=")
PUSH_ALL_FLAGS = ("--all", "--mirror", "--branches")
MAX_NESTING = 3
FILE_COMMANDS = {
    "cat", "less", "more", "head", "tail", "cp", "mv", "rsync", "sed", "awk",
    "grep", "rg", "ls", "find", "vim", "vi", "nano", "open", "code", "tar", "zip",
}


def block(reason):
    print(f"Blocked by ai-service guard: {reason}", file=sys.stderr)
    sys.exit(2)


def run_git(cwd, *args):
    try:
        out = subprocess.run(
            ["git", "-C", cwd, *args],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    return out.stdout.strip() if out.returncode == 0 else None


def existing_dir(path):
    path = os.path.abspath(path)
    while path and not os.path.isdir(path):
        parent = os.path.dirname(path)
        if parent == path:
            return None
        path = parent
    return path


def fork_relative_path(file_path):
    """Path relative to the fork's root, or None when outside the fork."""
    start = existing_dir(os.path.dirname(file_path) or ".")
    if not start:
        return None
    root = run_git(start, "rev-parse", "--show-toplevel")
    if not root:
        return None
    remote = run_git(root, "remote", "get-url", "origin") or ""
    if FORK_REMOTE.lower() not in remote.lower():
        return None
    root = os.path.realpath(root)
    target = os.path.realpath(os.path.abspath(file_path))
    if not target.startswith(root + os.sep):
        return None
    return os.path.relpath(target, root)


def in_fork(directory):
    root = run_git(directory, "rev-parse", "--show-toplevel")
    remote = run_git(root, "remote", "get-url", "origin") if root else ""
    return bool(remote) and FORK_REMOTE.lower() in remote.lower()


def is_enterprise(rel):
    rel = rel.lower()
    return rel == "enterprise" or rel.startswith("enterprise/")


def is_guard_file(rel):
    return rel.lower().startswith(GUARD_FILES)


def string_values(value):
    """Every string inside a tool input, decoded (no JSON escaping)."""
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from string_values(item)
    elif isinstance(value, list):
        for item in value:
            yield from string_values(item)


def check_write(file_path):
    rel = fork_relative_path(file_path)
    if rel is None:
        return
    if is_enterprise(rel):
        block("never open, copy or edit enterprise/ (separate licence).")
    if is_guard_file(rel):
        block("the guard and its settings change only by the owner's hand, not from an agent session.")
    if rel.startswith(ALLOWED_PREFIXES) or rel in ALLOWED_FILES:
        return
    block(
        f"{rel} is a Chatwoot file. Our code lives only in ai-service/ and "
        ".github/workflows/ai-service.yml (AGENTS.md project rules)."
    )


def check_read(tool_input):
    for key in ("file_path", "path"):
        value = tool_input.get(key)
        if value:
            rel = fork_relative_path(value)
            if rel is not None and is_enterprise(rel):
                block("never open enterprise/ (separate licence).")
    pattern = tool_input.get("pattern", "")
    if tool_input.get("path") is None and ENTERPRISE_PATH.match(pattern):
        block("never open enterprise/ (separate licence).")


def split_commands(command):
    return [part for part in re.split(r"&&|\|\||;|\n|\|", command) if part.strip()]


def tokens(part):
    try:
        return shlex.split(part)
    except ValueError:
        return part.split()


def effective_cwd(command, cwd):
    """Follow a leading `cd <dir>` so the branch check uses the right repo."""
    for part in split_commands(command):
        words = tokens(part)
        if len(words) >= 2 and words[0] == "cd":
            target = os.path.expanduser(words[1])
            cwd = target if os.path.isabs(target) else os.path.join(cwd, target)
    return cwd


def unwrap(words):
    """Drop `env VAR=1`, `nohup`, `VAR=1` and similar prefixes before the real command."""
    while words:
        head = os.path.basename(words[0])
        if head in WRAPPERS or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0]):
            words = words[1:]
            while words and (words[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0])):
                words = words[1:]
            continue
        return words
    return words


def nested_script(words):
    """The script of `sh -c '...'` (and bash/zsh), or None."""
    if not words or os.path.basename(words[0]) not in SHELLS:
        return None
    for index, word in enumerate(words[1:], start=1):
        if re.match(r"^-[a-zA-Z]*c[a-zA-Z]*$", word) and index + 1 < len(words):
            return words[index + 1]
    return None


def git_subcommand(words):
    """Return (repo_dir_or_None, subcommand, args) for a git invocation."""
    if not words or os.path.basename(words[0]) != "git":
        return None
    repo = None
    i = 1
    while i < len(words):
        word = words[i]
        if word == "-C" and i + 1 < len(words):
            repo = words[i + 1]
            i += 2
        elif word.startswith("--config-env") and GIT_CONFIG_BLOCKED[0] in word.lower():
            block("no git --config-env core.hooksPath; it bypasses hooks.")
        elif word == "-c" and i + 1 < len(words):
            if words[i + 1].lower().startswith(GIT_CONFIG_BLOCKED):
                block("no git -c core.hooksPath or alias overrides; they bypass hooks and this guard.")
            i += 2
        elif word.startswith("-"):
            i += 1
        else:
            return repo, word, words[i + 1:]
    return None


def check_push(args, repo_dir):
    for arg in args:
        name = arg.split("=")[0]
        if name.startswith("--") and len(name) >= 4 and any(flag.startswith(name) for flag in PUSH_ALL_FLAGS):
            block("no push --all/--mirror/--branches; push one feature branch.")
    for arg in args:
        if arg in ("--force", "-f") or (arg.startswith("-") and not arg.startswith("--") and "f" in arg[1:]):
            block("never plain --force; use --force-with-lease on your own branch.")
    refspecs = [a for a in args if not a.startswith("-")]
    for ref in refspecs[1:]:
        dest = ref.split(":")[-1].strip("'\"").lstrip("+")
        dest = dest.removeprefix("refs/heads/")
        if "*" in dest:
            block("no wildcard refspecs; push one feature branch.")
        if dest in PROTECTED_BRANCHES:
            block(f"never push to {dest}; push a feature branch and open a PR.")
    if len(refspecs) <= 1:
        branch = run_git(repo_dir, "symbolic-ref", "--short", "HEAD")
        if branch in PROTECTED_BRANCHES:
            block(f"current branch is {branch}; push a feature branch and open a PR.")


def check_bash(command, cwd, depth=0):
    if SAFE_FETCH.search(command):
        block("never set SAFE_FETCH_ALLOW_PRIVATE_NETWORK.")
    if GUARD_MENTION.search(command) and SHELL_WRITE.search(command):
        block("the guard and its settings change only by the owner's hand, not from an agent session.")
    lowered = command.lower()
    if GIT_CONFIG_ENV.search(command) and any(key in lowered for key in GIT_CONFIG_BLOCKED):
        block("no GIT_CONFIG_* overrides of core.hooksPath or aliases.")
    base = effective_cwd(command, cwd)
    for part in split_commands(command):
        words = unwrap(tokens(part))
        script = nested_script(words)
        if script is not None:
            if depth >= MAX_NESTING:
                block("shell nesting too deep to check; run the command directly.")
            check_bash(script, base, depth + 1)
            continue
        if words and os.path.basename(words[0]) in FILE_COMMANDS:
            for word in words[1:]:
                if word.startswith("-") or "enterprise" not in word.lower():
                    continue
                path = os.path.expanduser(word)
                path = path if os.path.isabs(path) else os.path.join(base, path)
                rel = fork_relative_path(path)
                if (rel is not None and is_enterprise(rel)) or (ENTERPRISE_PATH.match(word) and in_fork(base)):
                    block("never open, copy or edit enterprise/ (separate licence).")
        parsed = git_subcommand(words)
        if not parsed:
            continue
        repo, sub, args = parsed
        if "--no-verify" in args:
            block("never --no-verify; fix the failing hook instead.")
        if sub == "config" and any(a.lower().startswith(GIT_CONFIG_BLOCKED) for a in args):
            block("no git config of core.hooksPath or aliases; they bypass hooks and this guard.")
        if sub == "push":
            repo_dir = repo if repo and os.path.isabs(repo) else os.path.join(base, repo or "")
            check_push(args, repo_dir)


def main():
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return
    tool = event.get("tool_name", "")
    tool_input = event.get("tool_input") or {}
    cwd = event.get("cwd") or os.getcwd()

    if any(SAFE_FETCH.search(text) for text in string_values(tool_input)):
        block("never set SAFE_FETCH_ALLOW_PRIVATE_NETWORK.")
    if tool == "Bash":
        check_bash(tool_input.get("command", ""), cwd)
    elif tool in WRITE_TOOLS:
        path = tool_input.get("file_path") or tool_input.get("notebook_path")
        if path:
            check_write(path)
    elif tool in READ_TOOLS:
        check_read(tool_input)


if __name__ == "__main__":
    main()
