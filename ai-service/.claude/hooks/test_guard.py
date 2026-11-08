"""Tests for guard.py: run it the way Claude Code does (JSON on stdin)."""

import json
import os
import shlex
import subprocess
import sys
import tempfile
import unittest

HOOKS = os.path.dirname(os.path.abspath(__file__))
GUARD = os.path.join(HOOKS, "guard.py")
FORK_ROOT = os.environ.get("GUARD_TEST_FORK_ROOT") or os.path.abspath(os.path.join(HOOKS, "..", "..", ".."))
# Built by concatenation so this file itself never contains the forbidden setting.
SAFE_FETCH_ON = "SAFE_FETCH_ALLOW_PRIVATE_NETWORK" + "=true"


def run_guard(tool, tool_input, cwd=FORK_ROOT):
    event = {"tool_name": tool, "tool_input": tool_input, "cwd": cwd}
    return subprocess.run(
        [sys.executable, GUARD],
        input=json.dumps(event),
        capture_output=True,
        text=True,
        timeout=30,
    )


def git(cwd, *args):
    subprocess.run(["git", "-C", cwd, *args], check=True, capture_output=True)


class PushTests(unittest.TestCase):
    def test_push_to_develop_is_blocked(self):
        # Arrange
        command = "git push --dry-run origin develop"
        # Act
        result = run_guard("Bash", {"command": command})
        # Assert
        self.assertEqual(result.returncode, 2)
        self.assertIn("never push to develop", result.stderr)

    def test_push_refspec_to_develop_is_blocked(self):
        result = run_guard("Bash", {"command": "git -c credential.helper= push origin HEAD:refs/heads/develop"})
        self.assertEqual(result.returncode, 2)

    def test_bare_push_while_on_develop_is_blocked(self):
        # Arrange: a throwaway repository checked out on develop
        with tempfile.TemporaryDirectory() as repo:
            git(repo, "init", "-q", "-b", "develop")
            # Act
            result = run_guard("Bash", {"command": f"cd {repo} && git push"})
        # Assert
        self.assertEqual(result.returncode, 2)
        self.assertIn("current branch is develop", result.stderr)

    def test_plain_force_is_blocked(self):
        result = run_guard("Bash", {"command": "git push -f origin feat/x"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("--force", result.stderr)

    def test_feature_branch_push_with_lease_is_allowed(self):
        result = run_guard("Bash", {"command": "git push --force-with-lease -u origin feat/x"})
        self.assertEqual(result.returncode, 0, result.stderr)


class NoVerifyTests(unittest.TestCase):
    def test_commit_no_verify_is_blocked(self):
        result = run_guard("Bash", {"command": "git commit --no-verify -m wip"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("--no-verify", result.stderr)

    def test_normal_commit_is_allowed(self):
        result = run_guard("Bash", {"command": "git commit -m 'docs: note'"})
        self.assertEqual(result.returncode, 0, result.stderr)


class FileRuleTests(unittest.TestCase):
    def test_edit_in_ai_service_is_allowed(self):
        path = os.path.join(FORK_ROOT, "ai-service", "README.md")
        result = run_guard("Edit", {"file_path": path, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_edit_to_our_workflow_is_allowed(self):
        path = os.path.join(FORK_ROOT, ".github", "workflows", "ai-service.yml")
        result = run_guard("Edit", {"file_path": path, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_edit_to_chatwoot_file_is_blocked(self):
        path = os.path.join(FORK_ROOT, "app", "models", "user.rb")
        result = run_guard("Edit", {"file_path": path, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("app/models/user.rb is a Chatwoot file", result.stderr)

    def test_new_file_outside_ai_service_is_blocked(self):
        path = os.path.join(FORK_ROOT, "lib", "new_dir", "x.rb")
        result = run_guard("Write", {"file_path": path, "content": "x"})
        self.assertEqual(result.returncode, 2)

    def test_write_to_enterprise_is_blocked(self):
        path = os.path.join(FORK_ROOT, "enterprise", "app", "x.rb")
        result = run_guard("Write", {"file_path": path, "content": "x"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("enterprise/", result.stderr)

    def test_read_of_enterprise_is_blocked(self):
        path = os.path.join(FORK_ROOT, "enterprise", "LICENSE")
        result = run_guard("Read", {"file_path": path})
        self.assertEqual(result.returncode, 2)

    def test_shell_cat_of_enterprise_is_blocked(self):
        result = run_guard("Bash", {"command": "cat enterprise/LICENSE"})
        self.assertEqual(result.returncode, 2)

    def test_shell_relative_path_into_enterprise_is_blocked(self):
        # Arrange: a session started inside ai-service/
        cwd = os.path.join(FORK_ROOT, "ai-service")
        # Act
        result = run_guard("Bash", {"command": "cat ../enterprise/LICENSE"}, cwd=cwd)
        # Assert
        self.assertEqual(result.returncode, 2)

    def test_shell_absolute_path_into_enterprise_is_blocked(self):
        path = os.path.join(FORK_ROOT, "enterprise", "LICENSE")
        result = run_guard("Bash", {"command": f"head -1 {path}"}, cwd="/tmp")
        self.assertEqual(result.returncode, 2)

    def test_text_mentioning_enterprise_is_allowed(self):
        result = run_guard("Bash", {"command": "git commit -m 'never open enterprise/'"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_file_outside_the_fork_is_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_guard("Write", {"file_path": os.path.join(tmp, "notes.md"), "content": "x"})
        self.assertEqual(result.returncode, 0, result.stderr)


class SafeFetchTests(unittest.TestCase):
    def test_setting_it_in_a_file_is_blocked(self):
        path = os.path.join(FORK_ROOT, "ai-service", "deploy", "x.env")
        result = run_guard("Write", {"file_path": path, "content": SAFE_FETCH_ON + "\n"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("SAFE_FETCH_ALLOW_PRIVATE_NETWORK", result.stderr)

    def test_setting_it_in_a_shell_is_blocked(self):
        result = run_guard("Bash", {"command": f"export {SAFE_FETCH_ON}"})
        self.assertEqual(result.returncode, 2)

    def test_setting_it_in_any_tool_is_blocked(self):
        result = run_guard("mcp__plugin_context-mode_context-mode__ctx_execute", {"code": f"env['{SAFE_FETCH_ON}']"})
        self.assertEqual(result.returncode, 2)

    def test_mentioning_it_unset_is_allowed(self):
        result = run_guard("Bash", {"command": "grep -n SAFE_FETCH_ALLOW_PRIVATE_NETWORK deploy/dokploy-compose.yml"})
        self.assertEqual(result.returncode, 0, result.stderr)


class BypassTests(unittest.TestCase):
    """Findings from the security review of PR #11."""

    def test_escaped_quotes_in_json_still_blocked(self):
        # Arrange: the value sits behind an escaped quote once JSON-encoded
        content = 'env:\n  "SAFE_FETCH_ALLOW_PRIVATE_NETWORK": "' + "true" + '"\n'
        path = os.path.join(FORK_ROOT, "ai-service", "deploy", "x.json")
        # Act
        result = run_guard("Write", {"file_path": path, "content": content})
        # Assert
        self.assertEqual(result.returncode, 2)

    def test_nested_edit_value_is_blocked(self):
        path = os.path.join(FORK_ROOT, "ai-service", "deploy", "x.env")
        edits = [{"old_string": "a", "new_string": SAFE_FETCH_ON}]
        result = run_guard("MultiEdit", {"file_path": path, "edits": edits})
        self.assertEqual(result.returncode, 2)

    def test_editing_the_guard_is_blocked(self):
        result = run_guard("Edit", {"file_path": GUARD, "old_string": "a", "new_string": "b"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("guard", result.stderr)

    def test_editing_settings_is_blocked(self):
        path = os.path.join(FORK_ROOT, "ai-service", ".claude", "settings.json")
        result = run_guard("Write", {"file_path": path, "content": "{}"})
        self.assertEqual(result.returncode, 2)

    def test_shell_overwrite_of_guard_is_blocked(self):
        result = run_guard("Bash", {"command": "echo pass > ai-service/.claude/hooks/guard.py"})
        self.assertEqual(result.returncode, 2)

    def test_running_the_guard_tests_is_allowed(self):
        result = run_guard("Bash", {"command": "python3 -m unittest discover -s .claude/hooks 2>&1 | tail -3"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_push_all_and_mirror_are_blocked(self):
        for flag in ("--all", "--mirror"):
            result = run_guard("Bash", {"command": f"git push {flag} origin"})
            self.assertEqual(result.returncode, 2, flag)

    def test_hooks_path_override_is_blocked(self):
        result = run_guard("Bash", {"command": "git -c core.hooksPath=/dev/null commit -m x"})
        self.assertEqual(result.returncode, 2)

    def test_alias_override_is_blocked(self):
        result = run_guard("Bash", {"command": "git -c alias.p='push origin develop' p"})
        self.assertEqual(result.returncode, 2)

    def test_push_inside_sh_c_is_blocked(self):
        result = run_guard("Bash", {"command": "sh -c 'git push origin develop'"})
        self.assertEqual(result.returncode, 2)

    def test_push_behind_env_is_blocked(self):
        result = run_guard("Bash", {"command": "env GIT_TRACE=1 git push origin develop"})
        self.assertEqual(result.returncode, 2)

    def test_enterprise_in_other_case_is_blocked(self):
        path = os.path.join(FORK_ROOT, "Enterprise", "LICENSE")
        result = run_guard("Read", {"file_path": path})
        self.assertEqual(result.returncode, 2)


class SecondReviewTests(unittest.TestCase):
    """Findings from the second security review of PR #11."""

    def test_guard_path_in_other_case_is_blocked(self):
        path = os.path.join(FORK_ROOT, "ai-service", ".Claude", "Hooks", "guard.py")
        result = run_guard("Write", {"file_path": path, "content": "x"})
        self.assertEqual(result.returncode, 2)

    def test_shell_write_to_guard_in_other_case_is_blocked(self):
        result = run_guard("Bash", {"command": "echo x > ai-service/.CLAUDE/HOOKS/GUARD.PY"})
        self.assertEqual(result.returncode, 2)

    def test_git_config_hooks_path_is_blocked(self):
        result = run_guard("Bash", {"command": "git config core.hooksPath /dev/null"})
        self.assertEqual(result.returncode, 2)

    def test_git_config_alias_is_blocked(self):
        result = run_guard("Bash", {"command": "git config --global alias.p 'push origin develop'"})
        self.assertEqual(result.returncode, 2)

    def test_git_config_env_is_blocked(self):
        result = run_guard("Bash", {"command": "GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/x git commit -m x"})
        self.assertEqual(result.returncode, 2)

    def test_reading_git_config_is_allowed(self):
        result = run_guard("Bash", {"command": "git config user.email"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_abbreviated_all_and_branches_are_blocked(self):
        for flag in ("--al", "--mirr", "--branches", "--bran"):
            result = run_guard("Bash", {"command": f"git push {flag} origin"})
            self.assertEqual(result.returncode, 2, flag)

    def test_glob_refspec_is_blocked(self):
        result = run_guard("Bash", {"command": "git push origin 'refs/heads/*:refs/heads/*'"})
        self.assertEqual(result.returncode, 2)

    def test_combined_shell_flags_are_unwrapped(self):
        result = run_guard("Bash", {"command": "bash -lc 'git push origin develop'"})
        self.assertEqual(result.returncode, 2)

    def test_too_deep_nesting_fails_closed(self):
        command = "git status"
        for _ in range(5):
            command = "sh -c " + shlex.quote(command)
        result = run_guard("Bash", {"command": command})
        self.assertEqual(result.returncode, 2)


class ThirdReviewTests(unittest.TestCase):
    def test_config_env_as_separate_word_is_blocked(self):
        result = run_guard("Bash", {"command": "git --config-env core.hooksPath=X commit -m x"})
        self.assertEqual(result.returncode, 2)

    def test_short_abbreviation_is_blocked(self):
        result = run_guard("Bash", {"command": "git push --a origin"})
        self.assertEqual(result.returncode, 2)

    def test_atomic_push_is_allowed(self):
        result = run_guard("Bash", {"command": "git push --atomic origin feat/x"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_include_path_is_blocked(self):
        result = run_guard("Bash", {"command": "git config include.path /tmp/evil"})
        self.assertEqual(result.returncode, 2)

    def test_global_config_override_is_blocked(self):
        result = run_guard("Bash", {"command": "GIT_CONFIG_GLOBAL=/tmp/x git commit -m x"})
        self.assertEqual(result.returncode, 2)

    def test_shell_write_to_git_config_is_blocked(self):
        result = run_guard("Bash", {"command": "printf '[core]' >> .git/config"})
        self.assertEqual(result.returncode, 2)

    def test_shell_write_from_inside_claude_dir_is_blocked(self):
        cwd = os.path.join(FORK_ROOT, "ai-service", ".claude")
        result = run_guard("Bash", {"command": "cd hooks && echo x > g.py"}, cwd=cwd)
        self.assertEqual(result.returncode, 2)


class RedirectTests(unittest.TestCase):
    def test_fd_redirects_to_guard_files_are_blocked(self):
        for command in (
            "echo x 1> ai-service/.claude/hooks/guard.py",
            "echo x &> .git/config",
            "echo x >& ai-service/.claude/settings.json",
            "cp>&1x a ai-service/.claude/hooks/guard.py",
        ):
            result = run_guard("Bash", {"command": command})
            self.assertEqual(result.returncode, 2, command)


class FourthReviewTests(unittest.TestCase):
    """Bypasses left open after PR #11."""

    def test_vertical_tab_or_form_feed_is_blocked(self):
        for sep in ("\x0b", "\x0c"):
            result = run_guard("Bash", {"command": f"cp{sep}a ai-service/.claude/hooks/guard.py"})
            self.assertEqual(result.returncode, 2, repr(sep))

    def test_fd_duplication_before_vertical_tab_is_not_exempt(self):
        result = run_guard("Bash", {"command": "echo x >&1\x0bai-service/.claude/settings.json"})
        self.assertEqual(result.returncode, 2)

    def test_home_override_on_git_is_blocked(self):
        for command in ("HOME=/tmp/x git commit -m x", "env XDG_CONFIG_HOME=/tmp/x git push origin feat/x"):
            result = run_guard("Bash", {"command": command})
            self.assertEqual(result.returncode, 2, command)

    def test_home_without_git_is_allowed(self):
        result = run_guard("Bash", {"command": "HOME=/tmp/x python3 -c 1"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_writes_to_user_git_config_are_blocked(self):
        for command in (
            "printf x >> ~/.gitconfig",
            "echo x > $HOME/.config/git/config",
            "cp evil ~/.config/git/attributes",
        ):
            result = run_guard("Bash", {"command": command})
            self.assertEqual(result.returncode, 2, command)


class OwnerPatchTests(unittest.TestCase):
    """Allowed paths match AGENTS.md; reads and PR text no longer trip the self-protection."""

    def test_our_workflows_and_dependabot_are_allowed(self):
        for rel in (".github/workflows/ai-service-answer-smoke.yml", ".github/dependabot.yml"):
            # Arrange
            path = os.path.join(FORK_ROOT, *rel.split("/"))
            # Act
            result = run_guard("Write", {"file_path": path, "content": "x"})
            # Assert
            self.assertEqual(result.returncode, 0, rel + result.stderr)

    def test_other_github_files_stay_blocked(self):
        for rel in (
            ".github/workflows/frontend-fe.yml",
            ".github/workflows/ai-service/nested.yml",
            ".github/workflows/ai-service.yml.bak",
            ".github/CODEOWNERS",
        ):
            path = os.path.join(FORK_ROOT, *rel.split("/"))
            result = run_guard("Write", {"file_path": path, "content": "x"})
            self.assertEqual(result.returncode, 2, rel)
            self.assertIn("is a Chatwoot file", result.stderr)

    def test_reading_the_guard_with_dev_null_redirect_is_allowed(self):
        for command in (
            "grep -n Chatwoot ai-service/.claude/hooks/guard.py 2>/dev/null | head",
            "cat ai-service/.claude/settings.json &>/dev/null",
        ):
            result = run_guard("Bash", {"command": command})
            self.assertEqual(result.returncode, 0, command + result.stderr)

    def test_writes_to_the_guard_next_to_dev_null_stay_blocked(self):
        for command in (
            "echo x 2>/dev/null > ai-service/.claude/hooks/guard.py",
            "cat a >/dev/null; rm ai-service/.claude/hooks/guard.py",
            "echo x >/dev/nullx ai-service/.claude/settings.json",
        ):
            result = run_guard("Bash", {"command": command})
            self.assertEqual(result.returncode, 2, command)

    def test_pr_and_commit_text_naming_the_guard_is_allowed(self):
        for command in (
            "gh pr create --title t --body-file - <<'EOF'\nAllow the path in guard.py, then rm the > note; cp it.\nEOF",
            "cd /tmp && git commit -q -F - <<'EOF'\nfix: tests for .claude/hooks > guard.py (cp, mv)\nEOF",
        ):
            result = run_guard("Bash", {"command": command})
            self.assertEqual(result.returncode, 0, command + result.stderr)

    def test_heredoc_writes_to_the_guard_stay_blocked(self):
        for command in (
            "cat <<'EOF' > ai-service/.claude/hooks/guard.py\nx\nEOF",
            "gh pr create --body-file - <<'EOF' > ai-service/.claude/hooks/guard.py\nx\nEOF",
            "gh pr create --body-file - <<'EOF'\nok\nEOF\ncp x ai-service/.claude/hooks/guard.py",
            "gh pr create --body-file - <<'EOF'\nunterminated rm ai-service/.claude/hooks/guard.py",
            "git apply <<'EOF'\n+++ b/ai-service/.claude/hooks/guard.py\n> x\nEOF",
        ):
            result = run_guard("Bash", {"command": command})
            self.assertEqual(result.returncode, 2, command)


class HeredocExpansionTests(unittest.TestCase):
    """Security review of #46: unquoted heredoc bodies run $(...) and backticks."""

    def test_command_substitution_in_unquoted_heredoc_is_blocked(self):
        for command in (
            "gh pr create --body-file - <<EOF\n$(cp x ai-service/.claude/hooks/guard.py)\nEOF",
            "git commit -F - <<EOF\n`rm ai-service/.claude/settings.json`\nEOF",
            "gh pr create --body-file - <<-EOF\n$(echo x > ai-service/.claude/hooks/guard.py)\nEOF",
        ):
            # Act
            result = run_guard("Bash", {"command": command})
            # Assert
            self.assertEqual(result.returncode, 2, command)

    def test_substitution_text_in_quoted_heredoc_is_not_stripped(self):
        command = "gh pr create --body-file - <<'EOF'\n$(cp x ai-service/.claude/hooks/guard.py)\nEOF"
        result = run_guard("Bash", {"command": command})
        self.assertEqual(result.returncode, 2)

    def test_unquoted_heredoc_prose_is_checked_in_full(self):
        command = "gh pr create --body-file - <<EOF\nAllow the path in guard.py; rm the old note.\nEOF"
        result = run_guard("Bash", {"command": command})
        self.assertEqual(result.returncode, 2)

    def test_double_quoted_heredoc_prose_is_allowed(self):
        command = 'gh pr create --body-file - <<"EOF"\nAllow the path in guard.py; rm the old note.\nEOF'
        result = run_guard("Bash", {"command": command})
        self.assertEqual(result.returncode, 0, result.stderr)


class RobustnessTests(unittest.TestCase):
    def test_garbage_input_is_let_through(self):
        result = subprocess.run([sys.executable, GUARD], input="not json", capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
